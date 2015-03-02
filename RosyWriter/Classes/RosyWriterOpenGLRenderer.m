
/*
     File: RosyWriterOpenGLRenderer.m
 Abstract: The RosyWriter OpenGL effect renderer
  Version: 2.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "RosyWriterOpenGLRenderer.h"
#import <OpenGLES/EAGL.h>
#import "ShaderUtilities.h"
#import "matrix.h"

enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

@interface RosyWriterOpenGLRenderer ()
{
	EAGLContext *_oglContext;
	CVOpenGLESTextureCacheRef _textureCache;
	CVOpenGLESTextureCacheRef _renderTextureCache;
	CVPixelBufferPoolRef _bufferPool;
	CFDictionaryRef _bufferPoolAuxAttributes;
	CMFormatDescriptionRef _outputFormatDescription;
    GLuint _program;
    GLint _frame;
	GLuint _offscreenBufferHandle;
}

@end

@implementation RosyWriterOpenGLRenderer

#pragma mark API

- (instancetype)init
{
    self = [super init];
    if ( self )
	{
		_oglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		if ( ! _oglContext ) {
			NSLog( @"Problem with OpenGL context." );
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)dealloc
{
	[self deleteBuffers];
	[_oglContext release];
    [super dealloc];
}

#pragma mark RosyWriterRenderer

- (BOOL)operatesInPlace
{
	return NO;
}

- (FourCharCode)inputPixelFormat
{
	return kCVPixelFormatType_32BGRA;
}

- (void)prepareForInputWithFormatDescription:(CMFormatDescriptionRef)inputFormatDescription outputRetainedBufferCountHint:(size_t)outputRetainedBufferCountHint
{
	// The input and output dimensions are the same. This renderer doesn't do any scaling.
	CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions( inputFormatDescription );
	
	[self deleteBuffers];
	if ( ! [self initializeBuffersWithOutputDimensions:dimensions retainedBufferCountHint:outputRetainedBufferCountHint] ) {
		@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem preparing renderer." userInfo:nil];
	}
}

- (void)reset
{
	[self deleteBuffers];
}

- (CVPixelBufferRef)copyRenderedPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f, // bottom left
        1.0f, -1.0f, // bottom right
        -1.0f,  1.0f, // top left
        1.0f,  1.0f, // top right
    };
	static const float textureVertices[] = {
        0.0f, 0.0f, // bottom left
        1.0f, 0.0f, // bottom right
        0.0f,  1.0f, // top left
        1.0f,  1.0f, // top right
    };
	
	if ( _offscreenBufferHandle == 0 ) {
		@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unintialized buffer" userInfo:nil];
		return NULL;
	}
	
	if ( pixelBuffer == NULL ) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL pixel buffer" userInfo:nil];
		return NULL;
	}
	
	const CMVideoDimensions srcDimensions = { (int32_t)CVPixelBufferGetWidth(pixelBuffer), (int32_t)CVPixelBufferGetHeight(pixelBuffer) };
	const CMVideoDimensions dstDimensions = CMVideoFormatDescriptionGetDimensions( _outputFormatDescription );
	if ( srcDimensions.width != dstDimensions.width || srcDimensions.height != dstDimensions.height ) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid pixel buffer dimensions" userInfo:nil];
		return NULL;
	}
	
	if ( CVPixelBufferGetPixelFormatType( pixelBuffer ) != kCVPixelFormatType_32BGRA ) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid pixel buffer format" userInfo:nil];
		return NULL;
	}
	
	EAGLContext *oldContext = [EAGLContext currentContext];
	if ( oldContext != _oglContext ) {
		if ( ! [EAGLContext setCurrentContext:_oglContext] ) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem with OpenGL context" userInfo:nil];
			return NULL;
		}
	}
	
	CVReturn err = noErr;
    CVOpenGLESTextureRef srcTexture = NULL;
    CVOpenGLESTextureRef dstTexture = NULL;
	CVPixelBufferRef dstPixelBuffer = NULL;
	
	err = CVOpenGLESTextureCacheCreateTextureFromImage( kCFAllocatorDefault,
													   _textureCache,
													   pixelBuffer,
													   NULL,
													   GL_TEXTURE_2D,
													   GL_RGBA,
													   srcDimensions.width,
													   srcDimensions.height,
													   GL_BGRA,
													   GL_UNSIGNED_BYTE,
													   0,
													   &srcTexture );
    if ( ! srcTexture || err ) {
        NSLog( @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err );
        goto bail;
    }
	
	err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, _bufferPool, _bufferPoolAuxAttributes, &dstPixelBuffer );
	if ( err == kCVReturnWouldExceedAllocationThreshold ) {
		// Flush the texture cache to potentially release the retained buffers and try again to create a pixel buffer
		CVOpenGLESTextureCacheFlush( _renderTextureCache, 0 );
		err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, _bufferPool, _bufferPoolAuxAttributes, &dstPixelBuffer );
	}
	if ( err ) {
		if ( err == kCVReturnWouldExceedAllocationThreshold ) {
			NSLog( @"Pool is out of buffers, dropping frame" );
		}
		else {
			NSLog( @"Error at CVPixelBufferPoolCreatePixelBuffer %d", err );
		}
		goto bail;
	}

	err = CVOpenGLESTextureCacheCreateTextureFromImage( kCFAllocatorDefault,
													   _renderTextureCache,
													   dstPixelBuffer,
													   NULL,
													   GL_TEXTURE_2D,
													   GL_RGBA,
													   dstDimensions.width,
													   dstDimensions.height,
													   GL_BGRA,
													   GL_UNSIGNED_BYTE,
													   0,
													   &dstTexture );
    
    if ( ! dstTexture || err ) {
        NSLog( @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err );
        goto bail;
    }
	
    glBindFramebuffer( GL_FRAMEBUFFER, _offscreenBufferHandle );
	glViewport( 0, 0, srcDimensions.width, srcDimensions.height );
	glUseProgram( _program );
	
	
	// Set up our destination pixel buffer as the framebuffer's render target.
	glActiveTexture( GL_TEXTURE0 );
    glBindTexture( CVOpenGLESTextureGetTarget( dstTexture ), CVOpenGLESTextureGetName( dstTexture ) );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    glFramebufferTexture2D( GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget( dstTexture ), CVOpenGLESTextureGetName( dstTexture ), 0 );
	
	
	// Render our source pixel buffer.
    glActiveTexture( GL_TEXTURE1 );
	glBindTexture( CVOpenGLESTextureGetTarget( srcTexture ), CVOpenGLESTextureGetName( srcTexture ) );
    glUniform1i( _frame, 1 );
	
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    
	glVertexAttribPointer( ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices );
	glEnableVertexAttribArray( ATTRIB_VERTEX );
	glVertexAttribPointer( ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices );
	glEnableVertexAttribArray( ATTRIB_TEXTUREPOSITON );
    
    glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );
    
    glBindTexture( CVOpenGLESTextureGetTarget( srcTexture ), 0 );
	glBindTexture( CVOpenGLESTextureGetTarget( dstTexture ), 0 );
	
	// Make sure that outstanding GL commands which render to the destination pixel buffer have been submitted.
	// AVAssetWriter, AVSampleBufferDisplayLayer, and GL will block until the rendering is complete when sourcing from this pixel buffer.
	glFlush();
	
bail:
	if ( oldContext != _oglContext ) {
		[EAGLContext setCurrentContext:oldContext];
	}
    if ( srcTexture ) {
        CFRelease( srcTexture );
    }
    if ( dstTexture ) {
        CFRelease( dstTexture );
    }
	return dstPixelBuffer;
}

- (CMFormatDescriptionRef)outputFormatDescription
{
	return _outputFormatDescription;
}

#pragma mark Internal

- (BOOL)initializeBuffersWithOutputDimensions:(CMVideoDimensions)outputDimensions retainedBufferCountHint:(size_t)clientRetainedBufferCountHint
{
	BOOL success = YES;
	
	EAGLContext *oldContext = [EAGLContext currentContext];
	if ( oldContext != _oglContext ) {
		if ( ! [EAGLContext setCurrentContext:_oglContext] ) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem with OpenGL context" userInfo:nil];
			return NO;
		}
	}
	
	glDisable( GL_DEPTH_TEST );
    
    glGenFramebuffers( 1, &_offscreenBufferHandle );
    glBindFramebuffer( GL_FRAMEBUFFER, _offscreenBufferHandle );
	
    CVReturn err = CVOpenGLESTextureCacheCreate( kCFAllocatorDefault, NULL, _oglContext, NULL, &_textureCache );
    if ( err ) {
        NSLog( @"Error at CVOpenGLESTextureCacheCreate %d", err );
		success = NO;
		goto bail;
    }
	
	err = CVOpenGLESTextureCacheCreate( kCFAllocatorDefault, NULL, _oglContext, NULL, &_renderTextureCache );
    if ( err ) {
        NSLog( @"Error at CVOpenGLESTextureCacheCreate %d", err );
		success = NO;
		goto bail;
    }

    // Load vertex and fragment shaders
    GLint attribLocation[NUM_ATTRIBUTES] = {
        ATTRIB_VERTEX, ATTRIB_TEXTUREPOSITON,
    };
    GLchar *attribName[NUM_ATTRIBUTES] = {
        "position", "texturecoordinate",
    };
    
    const GLchar *vertSrc = [RosyWriterOpenGLRenderer readFile:@"myFilter.vsh"];
    const GLchar *fragSrc = [RosyWriterOpenGLRenderer readFile:@"myFilter.fsh"];
    
    // shader program
	glueCreateProgram( vertSrc, fragSrc,  
					  NUM_ATTRIBUTES, (const GLchar **)&attribName[0], attribLocation,
					  0, 0, 0,
					  &_program );
    if ( ! _program ) {
		NSLog( @"Problem initializing the program." );
        success = NO;
		goto bail;
    }
  	_frame = glueGetUniformLocation( _program, "videoframe" );
	
	size_t maxRetainedBufferCount = clientRetainedBufferCountHint;
	_bufferPool = createPixelBufferPool( outputDimensions.width, outputDimensions.height, kCVPixelFormatType_32BGRA, (int32_t)maxRetainedBufferCount );
	if ( ! _bufferPool ) {
		NSLog( @"Problem initializing a buffer pool." );
		success = NO;
		goto bail;
	}
	
	_bufferPoolAuxAttributes = createPixelBufferPoolAuxAttributes( (int32_t)maxRetainedBufferCount );
	preallocatePixelBuffersInPool( _bufferPool, _bufferPoolAuxAttributes );
	
	CMFormatDescriptionRef outputFormatDescription = NULL;
	CVPixelBufferRef testPixelBuffer = NULL;
	CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, _bufferPool, _bufferPoolAuxAttributes, &testPixelBuffer );
	if ( ! testPixelBuffer ) {
		NSLog( @"Problem creating a pixel buffer." );
		success = NO;
		goto bail;
	}
	CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, testPixelBuffer, &outputFormatDescription );
	_outputFormatDescription = outputFormatDescription;
	CFRelease( testPixelBuffer );
	
bail:
	if ( ! success ) {
		[self deleteBuffers];
	}
	if ( oldContext != _oglContext ) {
		[EAGLContext setCurrentContext:oldContext];
	}
    return success;
}

- (void)deleteBuffers
{
	EAGLContext *oldContext = [EAGLContext currentContext];
	if ( oldContext != _oglContext ) {
		if ( ! [EAGLContext setCurrentContext:_oglContext] ) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem with OpenGL context" userInfo:nil];
			return;
		}
	}	
    if ( _offscreenBufferHandle ) {
        glDeleteFramebuffers( 1, &_offscreenBufferHandle );
        _offscreenBufferHandle = 0;
    }
    if ( _program ) {
        glDeleteProgram( _program );
        _program = 0;
    }
    if ( _textureCache ) {
        CFRelease( _textureCache );
        _textureCache = 0;
    }
    if ( _renderTextureCache ) {
        CFRelease( _renderTextureCache );
        _renderTextureCache = 0;
    }
	if ( _bufferPool ) {
		CFRelease( _bufferPool );
		_bufferPool = NULL;
	}
	if ( _bufferPoolAuxAttributes ) {
		CFRelease( _bufferPoolAuxAttributes );
		_bufferPoolAuxAttributes = NULL;
	}
	if ( _outputFormatDescription ) {
		CFRelease( _outputFormatDescription );
		_outputFormatDescription = NULL;
	}
	if ( oldContext != _oglContext ) {
		[EAGLContext setCurrentContext:oldContext];
	}
}

+ (const GLchar *)readFile:(NSString *)name
{
	NSString *path;
	const GLchar *source;
	
	path = [[NSBundle mainBundle] pathForResource:name ofType: nil];
	source = (GLchar *)[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] UTF8String];    
	return source;
}

static CVPixelBufferPoolRef createPixelBufferPool( int32_t width, int32_t height, FourCharCode pixelFormat, int32_t maxBufferCount )
{
	CVPixelBufferPoolRef outputPool = NULL;
	
	NSDictionary *sourcePixelBufferOptions = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(pixelFormat),
												(id)kCVPixelBufferWidthKey : @(width),
												(id)kCVPixelBufferHeightKey : @(height),
												(id)kCVPixelFormatOpenGLESCompatibility : @(YES),
												(id)kCVPixelBufferIOSurfacePropertiesKey : @{ /*empty dictionary*/ } };
	
	NSDictionary *pixelBufferPoolOptions = @{ (id)kCVPixelBufferPoolMinimumBufferCountKey : @(maxBufferCount) };
	
    CVPixelBufferPoolCreate( kCFAllocatorDefault, (CFDictionaryRef)pixelBufferPoolOptions, (CFDictionaryRef)sourcePixelBufferOptions, &outputPool );
    
	return outputPool;
}

static CFDictionaryRef createPixelBufferPoolAuxAttributes( int32_t maxBufferCount )
{
	// CVPixelBufferPoolCreatePixelBufferWithAuxAttributes() will return kCVReturnWouldExceedAllocationThreshold if we have already vended the max number of buffers
	return CFRetain( @{ (id)kCVPixelBufferPoolAllocationThresholdKey : @(maxBufferCount) } );
}

static void preallocatePixelBuffersInPool( CVPixelBufferPoolRef pool, CFDictionaryRef auxAttributes )
{
	// Preallocate buffers in the pool, since this is for real-time display/capture
	NSMutableArray *pixelBuffers = [[NSMutableArray alloc] init];
	while ( 1 )
	{
		CVPixelBufferRef pixelBuffer = NULL;
		OSStatus err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer );
		
		if ( err == kCVReturnWouldExceedAllocationThreshold ) {
			break;
		}
		assert( err == noErr );
		
		[pixelBuffers addObject:(id)pixelBuffer];
		CFRelease( pixelBuffer );
	}
	[pixelBuffers release];
}

@end
