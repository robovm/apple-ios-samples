/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class contains an UIView backed by a CAEAGLLayer. It handles rendering input textures to the view. The object loads, compiles and links the fragment and vertex shader to be used during rendering.
 */

#import "APLEAGLView.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVUtilities.h>
#import <mach/mach_time.h>

// Uniform index.
enum
{
	UNIFORM_Y,
	UNIFORM_UV,
	UNIFORM_LUMA_THRESHOLD,
	UNIFORM_CHROMA_THRESHOLD,
	UNIFORM_ROTATION_ANGLE,
	UNIFORM_COLOR_CONVERSION_MATRIX,
	NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
	ATTRIB_VERTEX,
	ATTRIB_TEXCOORD,
	NUM_ATTRIBUTES
};

// Color Conversion Constants (YUV to RGB) including adjustment from 16-235/16-240 (video range)

// BT.601, which is the standard for SDTV.
static const GLfloat kColorConversion601[] = {
		1.164,  1.164, 1.164,
		  0.0, -0.392, 2.017,
		1.596, -0.813,   0.0,
};

// BT.709, which is the standard for HDTV.
static const GLfloat kColorConversion709[] = {
		1.164,  1.164, 1.164,
		  0.0, -0.213, 2.112,
		1.793, -0.533,   0.0,
};

@interface APLEAGLView ()
{
	// The pixel dimensions of the CAEAGLLayer.
	GLint _backingWidth;
	GLint _backingHeight;

	EAGLContext *_context;
	CVOpenGLESTextureRef _lumaTexture;
	CVOpenGLESTextureRef _chromaTexture;
	CVOpenGLESTextureCacheRef _videoTextureCache;
	
	GLuint _frameBufferHandle;
	GLuint _colorBufferHandle;
	
	const GLfloat *_preferredConversion;
}

@property GLuint program;

- (void)setupBuffers;
- (void)cleanUpTextures;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type URL:(NSURL *)URL;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation APLEAGLView

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder]))
	{
		// Use 2x scale factor on Retina displays.
		self.contentScaleFactor = [[UIScreen mainScreen] scale];

		// Get and configure the layer.
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

		eaglLayer.opaque = TRUE;
		eaglLayer.drawableProperties = @{ kEAGLDrawablePropertyRetainedBacking :[NSNumber numberWithBool:NO],
										  kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};

		// Set the context into which the frames will be drawn.
		_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

		if (!_context || ![EAGLContext setCurrentContext:_context] || ![self loadShaders]) {
			return nil;
		}
		
		// Set the default conversion to BT.709, which is the standard for HDTV.
		_preferredConversion = kColorConversion709;
	}
	return self;
}

# pragma mark - OpenGL setup

- (void)setupGL
{
	[EAGLContext setCurrentContext:_context];
	[self setupBuffers];
	[self loadShaders];
	
	glUseProgram(self.program);
	
	// 0 and 1 are the texture IDs of _lumaTexture and _chromaTexture respectively.
	glUniform1i(uniforms[UNIFORM_Y], 0);
	glUniform1i(uniforms[UNIFORM_UV], 1);
	glUniform1f(uniforms[UNIFORM_LUMA_THRESHOLD], self.lumaThreshold);
	glUniform1f(uniforms[UNIFORM_CHROMA_THRESHOLD], self.chromaThreshold);
	glUniform1f(uniforms[UNIFORM_ROTATION_ANGLE], self.preferredRotation);
	glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, _preferredConversion);
	
	// Create CVOpenGLESTextureCacheRef for optimal CVPixelBufferRef to GLES texture conversion.
	if (!_videoTextureCache) {
		CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
		if (err != noErr) {
			NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
			return;
		}
	}
}

#pragma mark - Utilities

- (void)setupBuffers
{
	glDisable(GL_DEPTH_TEST);
	
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
	
	glEnableVertexAttribArray(ATTRIB_TEXCOORD);
	glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
	
	glGenFramebuffers(1, &_frameBufferHandle);
	glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
	
	glGenRenderbuffers(1, &_colorBufferHandle);
	glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
	
	[_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);

	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBufferHandle);
	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
	}
}

- (void)cleanUpTextures
{
	if (_lumaTexture) {
		CFRelease(_lumaTexture);
		_lumaTexture = NULL;
	}
	
	if (_chromaTexture) {
		CFRelease(_chromaTexture);
		_chromaTexture = NULL;
	}
	
	// Periodic texture cache flush every frame
	CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (void)dealloc
{
	[self cleanUpTextures];
	
	if(_videoTextureCache) {
		CFRelease(_videoTextureCache);
	}
}

#pragma mark - OpenGLES drawing

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
	CVReturn err;
	if (pixelBuffer != NULL) {
		int frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
		int frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
		
		if (!_videoTextureCache) {
			NSLog(@"No video texture cache");
			return;
		}
		
		[self cleanUpTextures];
		
		
		/*
		 Use the color attachment of the pixel buffer to determine the appropriate color conversion matrix.
		 */
		CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
		
		if (colorAttachments == kCVImageBufferYCbCrMatrix_ITU_R_601_4) {
			_preferredConversion = kColorConversion601;
		}
		else {
			_preferredConversion = kColorConversion709;
		}
		
		/*
         CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture optimally from CVPixelBufferRef.
         */
		
		/*
         Create Y and UV textures from the pixel buffer. These textures will be drawn on the frame buffer Y-plane.
         */
		glActiveTexture(GL_TEXTURE0);
		err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
														   _videoTextureCache,
														   pixelBuffer,
														   NULL,
														   GL_TEXTURE_2D,
														   GL_RED_EXT,
														   frameWidth,
														   frameHeight,
														   GL_RED_EXT,
														   GL_UNSIGNED_BYTE,
														   0,
														   &_lumaTexture);
		if (err) {
			NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
		}
		
		glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		// UV-plane.
		glActiveTexture(GL_TEXTURE1);
		err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
														   _videoTextureCache,
														   pixelBuffer,
														   NULL,
														   GL_TEXTURE_2D,
														   GL_RG_EXT,
														   frameWidth / 2,
														   frameHeight / 2,
														   GL_RG_EXT,
														   GL_UNSIGNED_BYTE,
														   1,
														   &_chromaTexture);
		if (err) {
			NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
		}
		
		glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
		
		// Set the view port to the entire view.
		glViewport(0, 0, _backingWidth, _backingHeight);
	}
	
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT);
	
	// Use shader program.
	glUseProgram(self.program);
	glUniform1f(uniforms[UNIFORM_LUMA_THRESHOLD], self.lumaThreshold);
	glUniform1f(uniforms[UNIFORM_CHROMA_THRESHOLD], self.chromaThreshold);
	glUniform1f(uniforms[UNIFORM_ROTATION_ANGLE], self.preferredRotation);
	glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, _preferredConversion);
	
	// Set up the quad vertices with respect to the orientation and aspect ratio of the video.
	CGRect vertexSamplingRect = AVMakeRectWithAspectRatioInsideRect(self.presentationRect, self.layer.bounds);
	
	// Compute normalized quad coordinates to draw the frame into.
	CGSize normalizedSamplingSize = CGSizeMake(0.0, 0.0);
	CGSize cropScaleAmount = CGSizeMake(vertexSamplingRect.size.width/self.layer.bounds.size.width, vertexSamplingRect.size.height/self.layer.bounds.size.height);
	
	// Normalize the quad vertices.
	if (cropScaleAmount.width > cropScaleAmount.height) {
		normalizedSamplingSize.width = 1.0;
		normalizedSamplingSize.height = cropScaleAmount.height/cropScaleAmount.width;
	}
	else {
		normalizedSamplingSize.width = 1.0;
		normalizedSamplingSize.height = cropScaleAmount.width/cropScaleAmount.height;
	}
	
	/*
     The quad vertex data defines the region of 2D plane onto which we draw our pixel buffers.
     Vertex data formed using (-1,-1) and (1,1) as the bottom left and top right coordinates respectively, covers the entire screen.
     */
	GLfloat quadVertexData [] = {
		-1 * normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
			 normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
		-1 * normalizedSamplingSize.width, normalizedSamplingSize.height,
			 normalizedSamplingSize.width, normalizedSamplingSize.height,
	};
	
	// Update attribute values.
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData);
	glEnableVertexAttribArray(ATTRIB_VERTEX);

	/*
     The texture vertices are set up such that we flip the texture vertically. This is so that our top left origin buffers match OpenGL's bottom left texture coordinate system.
     */
	CGRect textureSamplingRect = CGRectMake(0, 0, 1, 1);
	GLfloat quadTextureData[] =  {
		CGRectGetMinX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
		CGRectGetMaxX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
		CGRectGetMinX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
		CGRectGetMaxX(textureSamplingRect), CGRectGetMinY(textureSamplingRect)
	};
	
	glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData);
	glEnableVertexAttribArray(ATTRIB_TEXCOORD);
	
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
	[_context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
	GLuint vertShader, fragShader;
	NSURL *vertShaderURL, *fragShaderURL;
	
	// Create the shader program.
	self.program = glCreateProgram();
	
	// Create and compile the vertex shader.
	vertShaderURL = [[NSBundle mainBundle] URLForResource:@"Shader" withExtension:@"vsh"];
	if (![self compileShader:&vertShader type:GL_VERTEX_SHADER URL:vertShaderURL]) {
		NSLog(@"Failed to compile vertex shader");
		return NO;
	}
	
	// Create and compile fragment shader.
	fragShaderURL = [[NSBundle mainBundle] URLForResource:@"Shader" withExtension:@"fsh"];
	if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER URL:fragShaderURL]) {
		NSLog(@"Failed to compile fragment shader");
		return NO;
	}
	
	// Attach vertex shader to program.
	glAttachShader(self.program, vertShader);
	
	// Attach fragment shader to program.
	glAttachShader(self.program, fragShader);
	
	// Bind attribute locations. This needs to be done prior to linking.
	glBindAttribLocation(self.program, ATTRIB_VERTEX, "position");
	glBindAttribLocation(self.program, ATTRIB_TEXCOORD, "texCoord");
	
	// Link the program.
	if (![self linkProgram:self.program]) {
		NSLog(@"Failed to link program: %d", self.program);
		
		if (vertShader) {
			glDeleteShader(vertShader);
			vertShader = 0;
		}
		if (fragShader) {
			glDeleteShader(fragShader);
			fragShader = 0;
		}
		if (self.program) {
			glDeleteProgram(self.program);
			self.program = 0;
		}
		
		return NO;
	}
	
	// Get uniform locations.
	uniforms[UNIFORM_Y] = glGetUniformLocation(self.program, "SamplerY");
	uniforms[UNIFORM_UV] = glGetUniformLocation(self.program, "SamplerUV");
	uniforms[UNIFORM_LUMA_THRESHOLD] = glGetUniformLocation(self.program, "lumaThreshold");
	uniforms[UNIFORM_CHROMA_THRESHOLD] = glGetUniformLocation(self.program, "chromaThreshold");
	uniforms[UNIFORM_ROTATION_ANGLE] = glGetUniformLocation(self.program, "preferredRotation");
	uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] = glGetUniformLocation(self.program, "colorConversionMatrix");
	
	// Release vertex and fragment shaders.
	if (vertShader) {
		glDetachShader(self.program, vertShader);
		glDeleteShader(vertShader);
	}
	if (fragShader) {
		glDetachShader(self.program, fragShader);
		glDeleteShader(fragShader);
	}
	
	return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type URL:(NSURL *)URL
{
    NSError *error;
    NSString *sourceString = [[NSString alloc] initWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
    if (sourceString == nil) {
		NSLog(@"Failed to load vertex shader: %@", [error localizedDescription]);
        return NO;
    }
    
	GLint status;
	const GLchar *source;
	source = (GLchar *)[sourceString UTF8String];
	
	*shader = glCreateShader(type);
	glShaderSource(*shader, 1, &source, NULL);
	glCompileShader(*shader);
	
#if defined(DEBUG)
	GLint logLength;
	glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar *log = (GLchar *)malloc(logLength);
		glGetShaderInfoLog(*shader, logLength, &logLength, log);
		NSLog(@"Shader compile log:\n%s", log);
		free(log);
	}
#endif
	
	glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
	if (status == 0) {
		glDeleteShader(*shader);
		return NO;
	}
	
	return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
	GLint status;
	glLinkProgram(prog);
	
#if defined(DEBUG)
	GLint logLength;
	glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(prog, logLength, &logLength, log);
		NSLog(@"Program link log:\n%s", log);
		free(log);
	}
#endif
	
	glGetProgramiv(prog, GL_LINK_STATUS, &status);
	if (status == 0) {
		return NO;
	}
	
	return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
	GLint logLength, status;
	
	glValidateProgram(prog);
	glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(prog, logLength, &logLength, log);
		NSLog(@"Program validate log:\n%s", log);
		free(log);
	}
	
	glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
	if (status == 0) {
		return NO;
	}
	
	return YES;
}

@end

