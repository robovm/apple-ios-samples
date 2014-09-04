/*
     File: OpenGLPixelBufferView.m
 Abstract: The OpenGL ES view.
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "OpenGLPixelBufferView.h"
#import <OpenGLES/EAGL.h>
#import <QuartzCore/CAEAGLLayer.h>
#import "ShaderUtilities.h"

#if !defined(_STRINGIFY)
#define __STRINGIFY( _x )   # _x
#define _STRINGIFY( _x )   __STRINGIFY( _x )
#endif

static const char * kPassThruVertex = _STRINGIFY(

attribute vec4 position;
attribute mediump vec4 texturecoordinate;
varying mediump vec2 coordinate;

void main()
{
	gl_Position = position;
	coordinate = texturecoordinate.xy;
}
												 
);

static const char * kPassThruFragment = _STRINGIFY(
												   
varying highp vec2 coordinate;
uniform sampler2D videoframe;

void main()
{
	gl_FragColor = texture2D(videoframe, coordinate);
}
												   
);

enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

@interface OpenGLPixelBufferView ()
{
	EAGLContext* _oglContext;
	CVOpenGLESTextureCacheRef _textureCache;
	GLint _width;
	GLint _height;
	GLuint _frameBufferHandle;
	GLuint _colorBufferHandle;
    GLuint _program;
	GLint _frame;
}

- (BOOL)initializeBuffers;
- (void)reset;

@end

@implementation OpenGLPixelBufferView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
		// Use 2x scale factor on Retina displays.
		self.contentScaleFactor = [[UIScreen mainScreen] scale];
		
        // Initialize OpenGL ES 2
        CAEAGLLayer* eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];

		self->_oglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		if (!self->_oglContext) {
			NSLog(@"Problem with OpenGL context.");
			[self release];
			return nil;
		}
    }
    return self;
}

- (BOOL)initializeBuffers
{
	BOOL success = YES;
	
	glDisable(GL_DEPTH_TEST);
    
    glGenFramebuffers(1, &_frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    
    glGenRenderbuffers(1, &_colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    
    [_oglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_height);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBufferHandle);
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failure with framebuffer generation");
		success = NO;
		goto bail;
	}
    
    //  Create a new CVOpenGLESTexture cache
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _oglContext, NULL, &_textureCache);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        success = NO;
		goto bail;
    }
    
    // attributes
    GLint attribLocation[NUM_ATTRIBUTES] = {
        ATTRIB_VERTEX, ATTRIB_TEXTUREPOSITON,
    };
    GLchar *attribName[NUM_ATTRIBUTES] = {
        "position", "texturecoordinate",
    };
    
    glueCreateProgram(kPassThruVertex, kPassThruFragment,
                      NUM_ATTRIBUTES, (const GLchar **)&attribName[0], attribLocation,
                      0, 0, 0,
                      &_program);
    
    if (!_program) {
		NSLog(@"Error creating the program");
        success = NO;
		goto bail;
	}
	_frame = glueGetUniformLocation(_program, "videoframe");
bail:
	if (!success) {
		[self reset];
	}
    return success;
}

- (void)reset
{
	EAGLContext *oldContext = [EAGLContext currentContext];
	if (oldContext != _oglContext) {
		if (![EAGLContext setCurrentContext:_oglContext]) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem with OpenGL context" userInfo:nil];
			return;
		}
	}
    if (_frameBufferHandle) {
        glDeleteFramebuffers(1, &_frameBufferHandle);
        _frameBufferHandle = 0;
    }
    if (_colorBufferHandle) {
        glDeleteRenderbuffers(1, &_colorBufferHandle);
        _colorBufferHandle = 0;
    }
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    if (_textureCache) {
        CFRelease(_textureCache);
        _textureCache = 0;
    }
	if (oldContext != _oglContext) {
		[EAGLContext setCurrentContext:oldContext];
	}
}

- (void)dealloc
{
	[self reset];
	[_oglContext release];
    [super dealloc];
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f, // bottom left
        1.0f, -1.0f, // bottom right
        -1.0f,  1.0f, // top left
        1.0f,  1.0f, // top right
    };
	
	if (NULL == pixelBuffer) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL pixel buffer" userInfo:nil];
		return;
	}

	EAGLContext *oldContext = [EAGLContext currentContext];
	if (oldContext != _oglContext) {
		if (![EAGLContext setCurrentContext:_oglContext]) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem with OpenGL context" userInfo:nil];
			return;
		}
	}
	
	if (0 == _frameBufferHandle) {
		BOOL success = [self initializeBuffers];
		if ( !success ) {
			NSLog(@"Problem initializing OpenGL buffers.");
			return;
		}
	}
	
    // Create a CVOpenGLESTexture from a CVPixelBufferRef
	size_t frameWidth = CVPixelBufferGetWidth(pixelBuffer);
	size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);
    CVOpenGLESTextureRef texture = NULL;
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                _textureCache,
                                                                pixelBuffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                (GLsizei)frameWidth,
                                                                (GLsizei)frameHeight,
                                                                GL_BGRA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &texture);
    
    
    if (!texture || err) {
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
        return;
    }
	
    // Set the view port to the entire view
	glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    glViewport(0, 0, _width, _height);
	
	glUseProgram(_program);
    glActiveTexture(GL_TEXTURE0);
	glBindTexture(CVOpenGLESTextureGetTarget(texture), CVOpenGLESTextureGetName(texture));
	glUniform1i(_frame, 0);
    
    // Set texture parameters
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	
    // Preserve aspect ratio; fill layer bounds
    CGSize textureSamplingSize;
    CGSize cropScaleAmount = CGSizeMake(self.bounds.size.width / (float)frameWidth, self.bounds.size.height / (float)frameHeight);
    if ( cropScaleAmount.height > cropScaleAmount.width ) {
        textureSamplingSize.width = self.bounds.size.width / (frameWidth * cropScaleAmount.height);
        textureSamplingSize.height = 1.0;
    }
    else {
        textureSamplingSize.width = 1.0;
        textureSamplingSize.height = self.bounds.size.height / (frameHeight * cropScaleAmount.width);
    }
    
	// Perform a vertical flip by swapping the top left and the bottom left coordinate.
	// CVPixelBuffers have a top left origin and OpenGL has a bottom left origin.
    GLfloat passThroughTextureVertices[] = {
        (1.0 - textureSamplingSize.width)/2.0, (1.0 + textureSamplingSize.height)/2.0, // top left
        (1.0 + textureSamplingSize.width)/2.0, (1.0 + textureSamplingSize.height)/2.0, // top right
        (1.0 - textureSamplingSize.width)/2.0, (1.0 - textureSamplingSize.height)/2.0, // bottom left
        (1.0 + textureSamplingSize.width)/2.0, (1.0 - textureSamplingSize.height)/2.0, // bottom right
    };
	
	glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, passThroughTextureVertices);
	glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
	
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    [_oglContext presentRenderbuffer:GL_RENDERBUFFER];
	
    glBindTexture(CVOpenGLESTextureGetTarget(texture), 0);
	glBindTexture(GL_TEXTURE_2D, 0);
    CFRelease(texture);
	
	if (oldContext != _oglContext) {
		[EAGLContext setCurrentContext:oldContext];
	}
}

- (void)flushPixelBufferCache
{
	if (_textureCache) {
		CVOpenGLESTextureCacheFlush(_textureCache, 0);
	}
}

@end
