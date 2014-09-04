/*

    File: GLLevelMeter.m
Abstract: dB meter class for displaying audio power levels using OpenGL
 Version: 2.5

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

Copyright (C) 2012 Apple Inc. All Rights Reserved.


*/

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "GLLevelMeter.h"


@implementation GLLevelMeter

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (BOOL)_createFramebuffer
{
	glGenFramebuffersOES(1, &_viewFramebuffer);
	glGenRenderbuffersOES(1, &_viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, _viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _viewRenderbuffer);
	[_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &_backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &_backingHeight);
	
	if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}

- (void)_destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &_viewFramebuffer);
	_viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &_viewRenderbuffer);
	_viewRenderbuffer = 0;
	
}

- (void)_setupView
{
	// Sets up matrices and transforms for OpenGL ES
	glViewport(0, 0, _backingWidth, _backingHeight);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, _backingWidth, 0, _backingHeight, -1.0f, 1.0f);
	glMatrixMode(GL_MODELVIEW);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnable(GL_BLEND);
	glDisable(GL_LINE_SMOOTH);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)_performInit
{
	_level = 0.;
	_numLights = 0;
	_numColorThresholds = 3;
	_variableLightIntensity = YES;
	_bgColor = [[UIColor alloc] initWithRed:0. green:0. blue:0. alpha:0.6];
	_borderColor = [[UIColor alloc] initWithRed:0. green:0. blue:0. alpha:1.];
	_colorThresholds = (LevelMeterColorThreshold*)malloc(3 * sizeof(LevelMeterColorThreshold));
	_colorThresholds[0].maxValue = 0.6;
	_colorThresholds[0].color = [[UIColor alloc] initWithRed:0. green:1. blue:0. alpha:1.];
	_colorThresholds[1].maxValue = 0.9;
	_colorThresholds[1].color = [[UIColor alloc] initWithRed:1. green:1. blue:0. alpha:1.];
	_colorThresholds[2].maxValue = 1.;
	_colorThresholds[2].color = [[UIColor alloc] initWithRed:1. green:0. blue:0. alpha:1.];
	_vertical = ([self frame].size.width < [self frame].size.height) ? YES : NO;
	
	if ([self respondsToSelector:@selector(setContentScaleFactor:)]){
        _scaleFactor = self.contentScaleFactor = [[UIScreen mainScreen] scale];
    } else {
        _scaleFactor = 1.0;
    }

	CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
	
	self.opaque = NO;
	eaglLayer.opaque = NO;
	
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
	
	
	_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	
	if(!_context || ![EAGLContext setCurrentContext:_context] || ![self _createFramebuffer]) {
		[self release];
		return;
	}
	
	[self _setupView];
}

- (void)_drawView
{
	//BOOL success = NO;
	
	if (!_viewFramebuffer) return;
	
	// Make sure that you are drawing to the current context
	[EAGLContext setCurrentContext:_context];
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, _viewFramebuffer);
	
	CGColorRef bgc = self.bgColor.CGColor;

	if (CGColorGetNumberOfComponents(bgc) != 4) goto bail;
	
	const CGFloat *bg_rgba;
	
	bg_rgba = CGColorGetComponents(bgc);
	
	glClearColor(0., 0., 0., 0.);
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	
	glPushMatrix();
	
	CGRect bds;
	
	if (_vertical)
	{
		glTranslatef(0., [self bounds].size.height, 0.);
		glScalef(1., -1., 1.);
		bds = CGRectMake(0., -1., [self bounds].size.width * _scaleFactor, [self bounds].size.height * _scaleFactor);
	} else {
		glTranslatef(0., [self bounds].size.height * _scaleFactor, 0.);
		glRotatef(-90., 0., 0., 1.);
		bds = CGRectMake(0., 1., [self bounds].size.height * _scaleFactor, [self bounds].size.width * _scaleFactor);
	}
	
	
	if (_numLights == 0)
	{
		int i;
		CGFloat currentTop = 0.;
		
		for (i=0; i<_numColorThresholds; i++)
		{
			LevelMeterColorThreshold thisThresh = _colorThresholds[i];
			CGFloat val = MIN(thisThresh.maxValue, _level);
						
			CGRect rect = CGRectMake(
									 0, 
									 (bds.size.height) * currentTop, 
									 bds.size.width, 
									 (bds.size.height) * (val - currentTop)
									 );
			
			GLfloat vertices[] = {
				CGRectGetMinX(rect), CGRectGetMinY(rect),  
				CGRectGetMaxX(rect), CGRectGetMinY(rect),  
				CGRectGetMinX(rect), CGRectGetMaxY(rect),  
				CGRectGetMaxX(rect), CGRectGetMaxY(rect),  
			};
			
			CGColorRef clr = thisThresh.color.CGColor;
			if (CGColorGetNumberOfComponents(clr) != 4) goto bail;
			const CGFloat *rgba;
			rgba = CGColorGetComponents(clr);
			glColor4f(rgba[0], rgba[1], rgba[2], rgba[3]);
			
			
			glVertexPointer(2, GL_FLOAT, 0, vertices);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			
			
			if (_level < thisThresh.maxValue) break;
			
			currentTop = val;
		}
	}
	else
	{
		int light_i;
		CGFloat lightMinVal = 0.;
		CGFloat insetAmount, lightVSpace;
		lightVSpace = bds.size.height / (CGFloat)_numLights;
		if (lightVSpace < 4.) insetAmount = 0.;
		else if (lightVSpace < 8.) insetAmount = 0.5;
		else insetAmount = 1.;
		
		int peakLight = -1;
		if (_peakLevel > 0.)
		{
			peakLight = _peakLevel * _numLights;
			if (peakLight >= _numLights) peakLight = _numLights - 1;
		}
		
		for (light_i=0; light_i<_numLights; light_i++)
		{
			CGFloat lightMaxVal = (CGFloat)(light_i + 1) / (CGFloat)_numLights;
			CGFloat lightIntensity;
			CGRect lightRect;
			UIColor *lightColor;
			
			if (light_i == peakLight)
			{
				lightIntensity = 1.;
			} else {
				lightIntensity = (_level - lightMinVal) / (lightMaxVal - lightMinVal);
				lightIntensity = LEVELMETER_CLAMP(0., lightIntensity, 1.);
				if ((!_variableLightIntensity) && (lightIntensity > 0.)) lightIntensity = 1.;
			}
			
			lightColor = _colorThresholds[0].color;
			int color_i;
			for (color_i=0; color_i<(_numColorThresholds-1); color_i++)
			{
				LevelMeterColorThreshold thisThresh = _colorThresholds[color_i];
				LevelMeterColorThreshold nextThresh = _colorThresholds[color_i + 1];
				if (thisThresh.maxValue <= lightMaxVal) lightColor = nextThresh.color;
			}
			
			lightRect = CGRectMake(
								   0., 
								   bds.size.height * ((CGFloat)(light_i) / (CGFloat)_numLights), 
								   bds.size.width,
								   bds.size.height * (1. / (CGFloat)_numLights)
								   );
			lightRect = CGRectInset(lightRect, insetAmount, insetAmount);

			GLfloat vertices[] = {
				CGRectGetMinX(lightRect), CGRectGetMinY(lightRect),  
				CGRectGetMaxX(lightRect), CGRectGetMinY(lightRect),  
				CGRectGetMinX(lightRect), CGRectGetMaxY(lightRect),  
				CGRectGetMaxX(lightRect), CGRectGetMaxY(lightRect),  
			};
			
			CGColorRef clr = lightColor.CGColor;
			if (CGColorGetNumberOfComponents(clr) != 4) goto bail;
			const CGFloat *rgba;
			rgba = CGColorGetComponents(clr);
			
			glVertexPointer(2, GL_FLOAT, 0, vertices);
			
			glColor4f(bg_rgba[0], bg_rgba[1], bg_rgba[2], bg_rgba[3]);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			
			GLfloat lightAlpha = rgba[3] * lightIntensity;
			if ((lightIntensity < 1.) && (lightIntensity > 0.) && (lightAlpha > .8)) lightAlpha = .8;
			
			glColor4f(rgba[0], rgba[1], rgba[2], lightAlpha);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

			lightMinVal = lightMaxVal;
		}
	}
	
	//success = YES;
bail:	
	glPopMatrix();
	
	glFlush();
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _viewRenderbuffer);
	[_context presentRenderbuffer:GL_RENDERBUFFER_OES];
}	


- (void)layoutSubviews
{
	[EAGLContext setCurrentContext:_context];
	[self _destroyFramebuffer];
	[self _createFramebuffer];
	[self _drawView];
}



- (void)drawRect:(CGRect)rect
{
	[self _drawView];
}

- (void)setNeedsDisplay
{
	[self _drawView];
}


- (void)dealloc
{
	if([EAGLContext currentContext] == _context) {
		[EAGLContext setCurrentContext:nil];
	}
	
	[_context release];
	_context = nil;
	
	
	[super dealloc];
}




@end
