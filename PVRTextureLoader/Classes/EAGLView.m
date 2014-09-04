/*

    File: EAGLView.m
Abstract: The EAGLView class is responsible for rendering the GL view.
 Version: 1.6

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

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "EAGLView.h"
#import "PVRTexture.h"

#define USE_DEPTH_BUFFER	0

// A class extension to declare private methods
@interface EAGLView ()

@property (nonatomic, retain) EAGLContext *context;

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;
- (void)updateSettings;

@end


@implementation EAGLView

@synthesize compressionSupported = _compressionSupported;
@synthesize anisotropySupported = _anisotropySupported;

@dynamic compressionSetting;
@dynamic mipmapFilterSetting;
@dynamic filterSetting;

@synthesize context = _context;


- (void)loadImageFile:(NSString *)name ofType:(NSString *)extension mipmap:(BOOL)mipmap texture:(uint32_t)texture
{
	UIImage *image;
	size_t width, height;
	CGImageRef cgImage;
	GLubyte *data;
	CGContextRef cgContext;
	CGColorSpaceRef colorSpace;
	GLenum err;
	
	image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:extension]];
	if (image == nil)
	{
		NSLog(@"Failed to load %@.%@", name, extension);
		return;
	}
	
	cgImage = [image CGImage];
	width = CGImageGetWidth(cgImage);
	height = CGImageGetHeight(cgImage);
	colorSpace = CGColorSpaceCreateDeviceRGB();

	// Malloc may be used instead of calloc if your cg image has dimensions equal to the dimensions of the cg bitmap context
	data = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
	cgContext = CGBitmapContextCreate(data, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
	if (cgContext != NULL)
	{
		// Set the blend mode to copy. We don't care about the previous contents.
		CGContextSetBlendMode(cgContext, kCGBlendModeCopy);
		CGContextDrawImage(cgContext, CGRectMake(0.0f, 0.0f, width, height), cgImage);
		
		glGenTextures(1, &(_textures[texture]));
		glBindTexture(GL_TEXTURE_2D, _textures[texture]);
		
		if (mipmap)
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		else
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
		
		if (mipmap)
			glGenerateMipmapOES(GL_TEXTURE_2D);
		
		err = glGetError();
		if (err != GL_NO_ERROR)
			NSLog(@"Error uploading texture. glError: 0x%04X", err);
		
		CGContextRelease(cgContext);
	}
	
	free(data);
	CGColorSpaceRelease(colorSpace);
}


- (void)loadTextures
{
	if (_compressionSupported)
	{
		PVRTexture *pvrTexture;
		NSArray *names = [NSArray arrayWithObjects:@"Brick_mipmap_4", @"Brick_mipmap_2", @"Brick_4", @"Brick_2", nil];

		[EAGLContext setCurrentContext:_context];
		
		[_pvrTextures removeAllObjects];
		
		for (int i=0; i < [names count]; i++)
		{
			pvrTexture = [PVRTexture pvrTextureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[names objectAtIndex:i] ofType:@"pvr"]];
			if (pvrTexture == nil)
				NSLog(@"Failed to load %@.pvr", [names objectAtIndex:i]);
			else {
				_textures[i] = [pvrTexture name];
                [_pvrTextures addObject:pvrTexture];
            }
		}
	}
	
	[self loadImageFile:@"Brick" ofType:@"png" mipmap:TRUE texture:kTextureMipmap];
	[self loadImageFile:@"Brick" ofType:@"png" mipmap:FALSE texture:kTexture];
}


// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


- (Compression)compressionSetting
{
	return _compressionSetting;
}


- (MipmipFilter)mipmapFilterSetting
{
	return _mipmapFilterSetting;
}


- (Filter)filterSetting
{
	return _filterSetting;
}


- (void)setCompressionSetting:(Compression)setting
{
	_compressionSetting = setting;
	[self updateSettings];
	[self drawView];
}


- (void)setMipmapFilterSetting:(MipmipFilter)setting
{
	_mipmapFilterSetting = setting;
	[self updateSettings];
	[self drawView];
}


- (void)setFilterSetting:(Filter)setting
{
	_filterSetting = setting;
	[self updateSettings];
	[self drawView];
}


- (void)updateSettings
{
	// choose texture name
	if (_mipmapFilterSetting == kMipmapFilterOff)
	{
		if (_compressionSetting == kCompressionFourBPP)
			_texSelection = kTexturePvrtc4;
		else if (_compressionSetting == kCompressionTwoBPP)
			_texSelection = kTexturePvrtc2;
		else if (_compressionSetting == kCompressionOff)
			_texSelection = kTexture;
	}
	else
	{
		if (_compressionSetting == kCompressionFourBPP)
			_texSelection = kTexturePvrtcMipmap4;
		else if (_compressionSetting == kCompressionTwoBPP)
			_texSelection = kTexturePvrtcMipmap2;
		else if (_compressionSetting == kCompressionOff)
			_texSelection = kTextureMipmap;
	}
	
	// choose filter settings
	if (_mipmapFilterSetting == kMipmapFilterOff)
	{
		if (_filterSetting == kFilterNearest)
		{
			_minTexParam = GL_NEAREST;
			_magTexParam = GL_NEAREST;
		}
		else if (_filterSetting == kFilterLinear || _filterSetting == kFilterSuper)
		{
			_minTexParam = GL_LINEAR;
			_magTexParam = GL_LINEAR;
		}
	}
	else if (_mipmapFilterSetting == kMipmapFilterNearest)
	{
		if (_filterSetting == kFilterNearest)
		{
			_minTexParam = GL_NEAREST_MIPMAP_NEAREST;
			_magTexParam = GL_NEAREST;
		}
		else if (_filterSetting == kFilterLinear || _filterSetting == kFilterSuper)
		{
			_minTexParam = GL_LINEAR_MIPMAP_NEAREST;
			_magTexParam = GL_LINEAR;
		}
	}
	else if (_mipmapFilterSetting == kMipmapFilterLinear)
	{
		if (_filterSetting == kFilterNearest)
		{
			_minTexParam = GL_NEAREST_MIPMAP_LINEAR;
			_magTexParam = GL_NEAREST;
		}
		else if (_filterSetting == kFilterLinear || _filterSetting == kFilterSuper)
		{
			_minTexParam = GL_LINEAR_MIPMAP_LINEAR;
			_magTexParam = GL_LINEAR;
		}
	}
	
	if (_filterSetting == kFilterSuper)
		_anisotropyTexParam = 2.0f;
	else
		_anisotropyTexParam = 1.0f;
}


- (BOOL)extensionSupported:(NSString *)name
{
	NSString *extensionsString = [NSString stringWithCString:(char *)glGetString(GL_EXTENSIONS) encoding:NSUTF8StringEncoding];
	NSArray *extensionsNames = [extensionsString componentsSeparatedByString:@" "];
	
	return [extensionsNames containsObject:name];
}


// The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder
{    
    if ((self = [super initWithCoder:coder]))
	{
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!_context || ![EAGLContext setCurrentContext:_context])
		{
            [self release];
            return nil;
        }
	
		_scale = 1.5f;
		_rotate = 0.0f;
		
		_compressionSetting = kCompressionOff;
		_mipmapFilterSetting = kMipmapFilterOff;
		_filterSetting = kFilterNearest;
		_texSelection = kTexture;
		_minTexParam = GL_NEAREST;
		_magTexParam = GL_NEAREST;
		_anisotropyTexParam = 1.0f;
		
		// PVRTC textures will not be loaded if the PVRTC extension is not supported.
		// UI selection for compression levels will also be disabled.
		_compressionSupported = [self extensionSupported:@"GL_IMG_texture_compression_pvrtc"];
		
		// The use of GL_TEXTURE_MAX_ANISOTROPY_EXT will be avoided if anisotropic filtering is not supported.
		// UI selection for anisotropic filtering will also be disabled.
		_anisotropySupported = [self extensionSupported:@"GL_EXT_texture_filter_anisotropic"];
		
		_pvrTextures = [[NSMutableArray alloc] initWithCapacity:10];
		
		[self loadTextures];
		
		[self setMultipleTouchEnabled:YES];
	}
	
    return self;
}


- (void)drawView
{
    const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
         1.0f, -1.0f,
        -1.0f,  1.0f,
         1.0f,  1.0f
    };
    const GLfloat squareTexCoords[] = {
        0.0, 1.0,
        1.0, 1.0,
        0.0, 0.0,
        1.0, 0.0
    };
	GLenum err;
    
    [EAGLContext setCurrentContext:_context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _viewFramebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    
    GLfloat aspectRatio = (GLfloat)(_backingWidth)/(GLfloat)(_backingHeight);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	glFrustumf(-1.0f, 1.0f, -1.0/aspectRatio, 1.0/aspectRatio, 1.0f, 10.0f);
    glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glScalef(_scale, _scale, 1.0f);
	glTranslatef(0.0f, 0.0f, -2.0f);
	glRotatef(_rotate, 1.0f, 0.0f, 0.0f);
    
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, squareTexCoords);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
	glEnable(GL_TEXTURE_2D);
	
	glBindTexture(GL_TEXTURE_2D, _textures[_texSelection]);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _minTexParam);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _magTexParam);
	if (_anisotropySupported)
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, _anisotropyTexParam);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
	glDisable(GL_TEXTURE_2D);
	
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _viewRenderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
	err = glGetError();
	if (err != GL_NO_ERROR)
		NSLog(@"Error in frame. glError: 0x%04X", err);
}


- (void)layoutSubviews
{
    [EAGLContext setCurrentContext:_context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self drawView];
}


- (BOOL)createFramebuffer
{
    glGenFramebuffersOES(1, &_viewFramebuffer);
    glGenRenderbuffersOES(1, &_viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _viewRenderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &_backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &_backingHeight);
    
    if (USE_DEPTH_BUFFER)
	{
        glGenRenderbuffersOES(1, &_depthRenderbuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, _depthRenderbuffer);
        glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, _backingWidth, _backingHeight);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _depthRenderbuffer);
    }
    
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}


- (void)destroyFramebuffer
{    
    glDeleteFramebuffersOES(1, &_viewFramebuffer);
    _viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &_viewRenderbuffer);
    _viewRenderbuffer = 0;
    
    if(_depthRenderbuffer)
	{
        glDeleteRenderbuffersOES(1, &_depthRenderbuffer);
        _depthRenderbuffer = 0;
    }
}


- (void)dealloc
{
    if ([EAGLContext currentContext] == _context)
        [EAGLContext setCurrentContext:nil];
    
	if (_textures[kTexture] != 0)
		glDeleteTextures(1, &_textures[kTexture]);
	if (_textures[kTextureMipmap] != 0)
		glDeleteTextures(1, &_textures[kTextureMipmap]);
	
	[_pvrTextures release];
    [_context release];
    [super dealloc];
}


- (float)distanceFromPoint:(CGPoint)pointA toPoint:(CGPoint)pointB
{
	float xD = fabs(pointA.x - pointB.x);
	float yD = fabs(pointA.y - pointB.y);
	
	return sqrt(xD*xD + yD*yD);
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touchA, *touchB;
	CGPoint pointA, pointB;
	
	if ([touches count] == 1)
	{
		touchA = [[touches allObjects] objectAtIndex:0];
		pointA = [touchA locationInView:self];
		pointB = [touchA previousLocationInView:self];
		
		float yDistance = pointA.y - pointB.y;
		
		_rotate += 0.5 * yDistance;
		
		[self drawView];
	}
	else if ([touches count] == 2)
	{
		touchA = [[touches allObjects] objectAtIndex:0];
		touchB = [[touches allObjects] objectAtIndex:1];
		
		pointA = [touchA locationInView:self];
		pointB = [touchB locationInView:self];
		
		float currDistance = [self distanceFromPoint:pointA toPoint:pointB];
		
		pointA = [touchA previousLocationInView:self];
		pointB = [touchB previousLocationInView:self];
		
		float prevDistance = [self distanceFromPoint:pointA toPoint:pointB];
		
		_scale += 0.005 * (currDistance - prevDistance);
		
		if (_scale > 10.0f)
			_scale = 10.0f;
		else if (_scale < 0.025f)
			_scale = 0.025f;
		
		[self drawView];
	}
}

@end
