/*
     File: VideoSnakeOpenGLRenderer.m
 Abstract: The VideoSnake OpenGL effect renderer.
  Version: 2.2
 
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

#import "VideoSnakeOpenGLRenderer.h"
#import <OpenGLES/EAGL.h>
#import "ShaderUtilities.h"
#import "matrix.h"

enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

static CVPixelBufferPoolRef CreatePixelBufferPool(int32_t width, int32_t height, OSType pixelFormat, int32_t maxBufferCount)
{
	CVPixelBufferPoolRef outputPool = NULL;
	
    CFMutableDictionaryRef sourcePixelBufferOptions = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pixelFormat);
    CFDictionaryAddValue(sourcePixelBufferOptions, kCVPixelBufferPixelFormatTypeKey, number);
    CFRelease(number);
    
    number = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &width);
    CFDictionaryAddValue(sourcePixelBufferOptions, kCVPixelBufferWidthKey, number);
    CFRelease(number);
    
    number = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &height);
    CFDictionaryAddValue(sourcePixelBufferOptions, kCVPixelBufferHeightKey, number);
    CFRelease(number);
    
    CFDictionaryAddValue(sourcePixelBufferOptions, kCVPixelFormatOpenGLESCompatibility, kCFBooleanTrue);
    
    CFDictionaryRef ioSurfaceProps = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    if (ioSurfaceProps) {
        CFDictionaryAddValue(sourcePixelBufferOptions, kCVPixelBufferIOSurfacePropertiesKey, ioSurfaceProps);
        CFRelease(ioSurfaceProps);
    }
    
	number = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &maxBufferCount);
	CFDictionaryRef pixelBufferPoolOptions = CFDictionaryCreate(kCFAllocatorDefault, (const void**)&kCVPixelBufferPoolMinimumBufferCountKey, (const void**)&number, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRelease(number);
	
    CVPixelBufferPoolCreate(kCFAllocatorDefault, pixelBufferPoolOptions, sourcePixelBufferOptions, &outputPool);
    
    CFRelease(sourcePixelBufferOptions);
	CFRelease(pixelBufferPoolOptions);	
	return outputPool;
}

static CFDictionaryRef CreatePixelBufferPoolAuxAttributes(int32_t maxBufferCount)
{
	// CVPixelBufferPoolCreatePixelBufferWithAuxAttributes() will return kCVReturnWouldExceedAllocationThreshold if we have already vended the max number of buffers
	NSDictionary *auxAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:maxBufferCount], (id)kCVPixelBufferPoolAllocationThresholdKey, nil];
	return (CFDictionaryRef)auxAttributes;
}

static void PreallocatePixelBuffersInPool( CVPixelBufferPoolRef pool, CFDictionaryRef auxAttributes )
{
	// Preallocate buffers in the pool, since this is for real-time display/capture
	NSMutableArray *pixelBuffers = [[NSMutableArray alloc] init];
	while ( 1 ) {
		CVPixelBufferRef pixelBuffer = NULL;
		OSStatus err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer );
		
		if ( err == kCVReturnWouldExceedAllocationThreshold )
			break;
		assert( err == noErr );
		
		[pixelBuffers addObject:(id)pixelBuffer];
		CFRelease( pixelBuffer );
	}
	[pixelBuffers release];
}

@interface VideoSnakeOpenGLRenderer ()
{
	EAGLContext* _oglContext;
	CVOpenGLESTextureCacheRef _textureCache;
    CVOpenGLESTextureCacheRef _renderTextureCache;
    CVPixelBufferRef _backFramePixelBuffer;
	CVPixelBufferPoolRef _bufferPool;
	CFDictionaryRef _bufferPoolAuxAttributes;
	CMFormatDescriptionRef _outputFormatDescription;
    GLuint _program;
    GLint _frame;
    GLint _backgroundColor;
    GLuint _modelView;
    GLuint _projection;
	GLuint _offscreenBufferHandle;
	
	// Snake effect
    double _velocityDeltaX;
    double _velocityDeltaY;
    NSTimeInterval _lastMotionTime;
}

@end

@implementation VideoSnakeOpenGLRenderer

+ (const GLchar *)readFile:(NSString *)name
{
    NSString *path;
    const GLchar *source;
    
    path = [[NSBundle mainBundle] pathForResource:name ofType: nil];
    source = (GLchar *)[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] UTF8String];    
    return source;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
		self->_oglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		if (!self->_oglContext) {
			NSLog(@"Problem with OpenGL context.");
			[self release];
			return  nil;
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

- (void)prepareWithOutputDimensions:(CMVideoDimensions)outputDimensions retainedBufferCountHint:(size_t)retainedBufferCountHint
{
	[self deleteBuffers];
	if (![self initializeBuffersWithOutputDimensions:outputDimensions retainedBufferCountHint:retainedBufferCountHint]) {
		@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem preparing renderer." userInfo:nil];
	}
}

- (BOOL)initializeBuffersWithOutputDimensions:(CMVideoDimensions)outputDimensions retainedBufferCountHint:(size_t)clientRetainedBufferCountHint
{
	BOOL success = YES;
	
	EAGLContext *oldContext = [EAGLContext currentContext];
	if (oldContext != _oglContext) {
		if (![EAGLContext setCurrentContext:_oglContext]) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem with OpenGL context" userInfo:nil];
			return NO;
		}
	}
	
	glDisable(GL_DEPTH_TEST);
    
    glGenFramebuffers(1, &_offscreenBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenBufferHandle);
	
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _oglContext, NULL, &_textureCache);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
		success = NO;
		goto bail;
    }
	
	err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _oglContext, NULL, &_renderTextureCache);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
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
    
    const GLchar *videoSnakeVertSrc = [VideoSnakeOpenGLRenderer readFile:@"videoSnake.vsh"];
    const GLchar *videoSnakeFragSrc = [VideoSnakeOpenGLRenderer readFile:@"videoSnake.fsh"];
    
    // videoSnake shader program
    glueCreateProgram(videoSnakeVertSrc, videoSnakeFragSrc,
                      NUM_ATTRIBUTES, (const GLchar **)&attribName[0], attribLocation,
                      0, 0, 0,
                      &_program);
    if (!_program) {
		NSLog(@"Problem initializing the program.");
        success = NO;
		goto bail;
    }
    _backgroundColor = glueGetUniformLocation(_program, "backgroundcolor");
    _modelView = glueGetUniformLocation(_program, "amodelview");
    _projection = glueGetUniformLocation(_program, "aprojection");
  	_frame = glueGetUniformLocation(_program, "videoframe");
	
	// Because we will retain one buffer in _backFramePixelBuffer we increment the client's retained buffer count hint by 1
	size_t maxRetainedBufferCount = clientRetainedBufferCountHint + 1;
	
	_bufferPool = CreatePixelBufferPool(outputDimensions.width, outputDimensions.height, kCVPixelFormatType_32BGRA, (int32_t)maxRetainedBufferCount);
	if (!_bufferPool) {
		NSLog(@"Problem initializing a buffer pool.");
		success = NO;
		goto bail;
	}
	
	_bufferPoolAuxAttributes = CreatePixelBufferPoolAuxAttributes((int32_t)maxRetainedBufferCount);
	PreallocatePixelBuffersInPool(_bufferPool, _bufferPoolAuxAttributes);
	
	CMFormatDescriptionRef outputFormatDescription = NULL;
	CVPixelBufferRef testPixelBuffer = NULL;
	CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, _bufferPool, _bufferPoolAuxAttributes, &testPixelBuffer );
	if (!testPixelBuffer) {
		NSLog(@"Problem creating a pixel buffer.");
		success = NO;
		goto bail;
	}
	CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, testPixelBuffer, &outputFormatDescription );
	_outputFormatDescription = outputFormatDescription;
	CFRelease(testPixelBuffer);
	
bail:
	if (!success) {
		[self deleteBuffers];
	}
	if (oldContext != _oglContext) {
		[EAGLContext setCurrentContext:oldContext];
	}
    return success;
}

- (void)reset
{
	[self deleteBuffers];
}

- (void)deleteBuffers
{
	EAGLContext *oldContext = [EAGLContext currentContext];
	if (oldContext != _oglContext) {
		if (![EAGLContext setCurrentContext:_oglContext]) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem with OpenGL context" userInfo:nil];
			return;
		}
	}	
    if (_offscreenBufferHandle) {
        glDeleteFramebuffers(1, &_offscreenBufferHandle);
        _offscreenBufferHandle = 0;
    }
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
    if (_backFramePixelBuffer) {
        CFRelease(_backFramePixelBuffer);
        _backFramePixelBuffer = 0;
    }
    if (_textureCache) {
        CFRelease(_textureCache);
        _textureCache = 0;
    }
    if (_renderTextureCache) {
        CFRelease(_renderTextureCache);
        _renderTextureCache = 0;
    }
	if (_bufferPool) {
		CFRelease(_bufferPool);
		_bufferPool = NULL;
	}
	if (_bufferPoolAuxAttributes) {
		CFRelease(_bufferPoolAuxAttributes);
		_bufferPoolAuxAttributes = NULL;
	}
	if (_outputFormatDescription) {
		CFRelease(_outputFormatDescription);
		_outputFormatDescription = NULL;
	}
	if (oldContext != _oglContext) {
		[EAGLContext setCurrentContext:oldContext];
	}
}

- (CMFormatDescriptionRef)outputFormatDescription
{
	return _outputFormatDescription;
}

- (CVPixelBufferRef)copyRenderedPixelBuffer:(CVPixelBufferRef)pixelBuffer motion:(CMDeviceMotion *)motion
{
	static const float kBlackUniform[4] = {0.0, 0.0, 0.0, 1.0};
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
	
    static const float kMotionDampingFactor = 0.75;
    static const float kMotionScaleFactor = 0.01;
    static const float kFrontScaleFactor = 0.25;
    static const float kBackScaleFactor = 0.85;
	
	if (0 == _offscreenBufferHandle) {
		@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Unintialize buffer" userInfo:nil];
		return NULL;
	}
	
	if (NULL == pixelBuffer) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL pixel buffer" userInfo:nil];
		return NULL;
	}
	
	const CMVideoDimensions srcDimensions = {(int32_t)CVPixelBufferGetWidth(pixelBuffer), (int32_t)CVPixelBufferGetHeight(pixelBuffer)};
	const CMVideoDimensions dstDimensions = CMVideoFormatDescriptionGetDimensions(_outputFormatDescription);
	if (srcDimensions.width != dstDimensions.width ||
		srcDimensions.height != dstDimensions.height) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid pixel buffer dimensions" userInfo:nil];
		return NULL;
	}
	
	if (kCVPixelFormatType_32BGRA != CVPixelBufferGetPixelFormatType(pixelBuffer)) {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid pixel buffer format" userInfo:nil];
		return NULL;
	}
	
	EAGLContext *oldContext = [EAGLContext currentContext];
	if (oldContext != _oglContext) {
		if (![EAGLContext setCurrentContext:_oglContext]) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem with OpenGL context" userInfo:nil];
			return NULL;
		}
	}
	
	CVReturn err = noErr;
    CVOpenGLESTextureRef srcTexture = NULL;
    CVOpenGLESTextureRef dstTexture = NULL;
	CVOpenGLESTextureRef backFrameTexture = NULL;
	CVPixelBufferRef dstPixelBuffer = NULL;
	
    if (!_lastMotionTime) {
        _lastMotionTime = motion.timestamp;
    }
    NSTimeInterval timeDelta = motion.timestamp - _lastMotionTime;
    _lastMotionTime = motion.timestamp;
    
    _velocityDeltaX += motion.userAcceleration.x * timeDelta;
	_velocityDeltaX *= kMotionDampingFactor;
    _velocityDeltaY += motion.userAcceleration.y * timeDelta;
	_velocityDeltaY *= kMotionDampingFactor;
	
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
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
                                                       &srcTexture);
    if (!srcTexture || err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        goto bail;
    }
	
	err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, _bufferPool, _bufferPoolAuxAttributes, &dstPixelBuffer);
	if (kCVReturnWouldExceedAllocationThreshold == err) {
		// Flush the texture cache to potentially release the retained buffers and try again to create a pixel buffer
		CVOpenGLESTextureCacheFlush(_renderTextureCache, 0);
		err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, _bufferPool, _bufferPoolAuxAttributes, &dstPixelBuffer);
	}
	if (err) {
		if (kCVReturnWouldExceedAllocationThreshold == err) {
			NSLog(@"Pool is out of buffers, dropping frame");
		}
		else {
			NSLog(@"Error at CVPixelBufferPoolCreatePixelBuffer %d", err);
		}
		goto bail;
	}

    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
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
                                                       &dstTexture);
    
    if (!dstTexture || err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        goto bail;
    }
	
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenBufferHandle);
	glViewport(0, 0, srcDimensions.width, srcDimensions.height);
    glUseProgram(_program);
	
	glActiveTexture(GL_TEXTURE0);
    glBindTexture(CVOpenGLESTextureGetTarget(dstTexture), CVOpenGLESTextureGetName(dstTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, CVOpenGLESTextureGetTarget(dstTexture), CVOpenGLESTextureGetName(dstTexture), 0);
	
    float modelview[16], projection[16];
    
    // setup projection matrix
    mat4f_LoadIdentity(projection);
    glUniformMatrix4fv(_projection, 1, GL_FALSE, projection);
	
    if (_backFramePixelBuffer) {
		
		float motionPixels = kMotionScaleFactor * dstDimensions.width;
		int motionMirroring = self.shouldMirrorMotion ? -1 : 1;
		float transBack[3] = {-_velocityDeltaY * motionPixels, -_velocityDeltaX * motionPixels * motionMirroring, 0.};
		float scaleBack[3] = {kBackScaleFactor, kBackScaleFactor, 0.};
		
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           _renderTextureCache,
                                                           _backFramePixelBuffer,
                                                           NULL,
                                                           GL_TEXTURE_2D,
                                                           GL_RGBA,
                                                           dstDimensions.width,
                                                           dstDimensions.height,
                                                           GL_BGRA,
                                                           GL_UNSIGNED_BYTE,
                                                           0,
                                                           &backFrameTexture);
        
        if (!backFrameTexture || err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            goto bail;
        }
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(CVOpenGLESTextureGetTarget(backFrameTexture), CVOpenGLESTextureGetName(backFrameTexture));
		glUniform1i(_frame, 1);
		
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        float translation[16];
        mat4f_LoadTranslation(transBack, translation);
		
        float scaling[16];
        mat4f_LoadScale(scaleBack, scaling);
        
        mat4f_MultiplyMat4f(translation, scaling, modelview);
        
        glUniformMatrix4fv(_modelView, 1, GL_FALSE, modelview);
        
		glClearColor(kBlackUniform[0], kBlackUniform[1], kBlackUniform[2], kBlackUniform[3]);
		glUniform4fv(_backgroundColor, 1, kBlackUniform);
       
		glClear(GL_COLOR_BUFFER_BIT);
        
        glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
        glEnableVertexAttribArray(ATTRIB_VERTEX);
        glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
        glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glBindTexture(CVOpenGLESTextureGetTarget(backFrameTexture), 0);
    }
    else {
        glClear(GL_COLOR_BUFFER_BIT);
    }
	
    glActiveTexture(GL_TEXTURE2);
	glBindTexture(CVOpenGLESTextureGetTarget(srcTexture), CVOpenGLESTextureGetName(srcTexture));
    glUniform1i(_frame, 2);
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float scaleFront[3] = {kFrontScaleFactor, kFrontScaleFactor, 0.0};
    mat4f_LoadScale(scaleFront, modelview);
    
    glUniformMatrix4fv(_modelView, 1, GL_FALSE, modelview);
    
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
	glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindTexture(CVOpenGLESTextureGetTarget(srcTexture), 0);
	glBindTexture(CVOpenGLESTextureGetTarget(dstTexture), 0);
	
    if (_backFramePixelBuffer) {
        CFRelease(_backFramePixelBuffer);
        _backFramePixelBuffer = NULL;
    }
    _backFramePixelBuffer = (CVPixelBufferRef)CFRetain(dstPixelBuffer);
	
	glFlush();
	
bail:
	if (oldContext != _oglContext) {
		[EAGLContext setCurrentContext:oldContext];
	}
    if (srcTexture) {
        CFRelease(srcTexture);
    }
    if (backFrameTexture) {
        CFRelease(backFrameTexture);
    }
    if (dstTexture) {
        CFRelease(dstTexture);
    }
	return dstPixelBuffer;
}

@end
