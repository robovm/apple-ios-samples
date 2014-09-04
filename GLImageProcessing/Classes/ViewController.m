/*
     File: ViewController.m
 Abstract: 
  Version: 1.3
 
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

#import "ViewController.h"
#import "EAGLView.h"

#define DEG2RAD (M_PI/180.0f)


// These enums match the button tags in the nib
enum {
	BUTTON_BRIGHTNESS,
	BUTTON_CONTRAST,
	BUTTON_SATURATION,
	BUTTON_HUE,
	BUTTON_SHARPNESS,
	NUM_BUTTONS
};

@implementation ViewController

@synthesize slider;
@synthesize tabBar;


- (void)viewDidLoad
{
	int b, i;

	// Select first tab by default
	tabBar.selectedItem = [tabBar.items objectAtIndex:0];
	
	// Create a bitmap context for rendering the tabBar buttons
	// Usually, button images are loaded from disk, but these simple shapes can be procedurally generated.
	// UITabBar only needs the alpha channel of these images.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(nil, 30, 30, 8, 0, colorSpace, kCGImageAlphaPremultipliedFirst);
	CGImageRef theCGImage;

	// Draw with white round strokes
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
	CGContextSetLineWidth(context, 2.0);
	
	for (b = 0; b < NUM_BUTTONS; b++)
	{
		CGContextClearRect(context, CGRectMake(0, 0, 30, 30));

		switch(b)
		{
			case BUTTON_BRIGHTNESS:
			{
				const CGFloat line[8*4] = {
					15.0, 6.0, 15.0, 4.0,
					15.0,24.0, 15.0,26.0,
					 6.0,15.0,  4.0,15.0,
					24.0,15.0, 26.0,15.0,
					21.5,21.5, 23.0,23.0,
					 8.5, 8.5,  7.0, 7.0,
					21.5, 8.5, 23.0, 7.0,
					 8.5,21.5,  7.0,23.0,					
				};
			
				// A circle with eight rays around it
				CGContextStrokeEllipseInRect(context, CGRectMake(10.5, 10.5, 9.0, 9.0));
				for (i = 0; i < 8; i++)
				{
					CGContextMoveToPoint(context, line[i*4+0], line[i*4+1]);
					CGContextAddLineToPoint(context, line[i*4+2], line[i*4+3]);
					CGContextStrokePath(context);					
				}
				break;
			}
			case BUTTON_CONTRAST:
			{
				// A circle with the right half filled
				CGContextStrokeEllipseInRect(context, CGRectMake(4.0, 4.0, 22.0, 22.0));
				CGContextAddArc(context, 15.0, 15.0, 11.0, -M_PI/2.0, M_PI/2.0, false);
				CGContextFillPath(context);
				break;
			}
			case BUTTON_SATURATION:
			{
				CGGradientRef gradient;
				const CGFloat stripe[3][12] = {
					{ 0.3,0.3,0.3,0.15, 1.0,0.0,0.0,0.70,  5, 5, 7, 25 }, 
					{ 0.5,0.5,0.5,0.25, 0.0,1.0,0.0,0.75, 12, 5, 6, 25 },
					{ 0.2,0.2,0.2,0.10, 0.0,0.0,1.0,0.65, 18, 5, 7, 25 },
				};

				// Red/Green/Blue gradients, inside a rounded rect
				for (i = 0; i < 3; i++)
				{
					gradient = CGGradientCreateWithColorComponents(colorSpace, stripe[i], NULL, 2);
					CGContextSaveGState(context);
					CGContextClipToRect(context, CGRectMake(stripe[i][8], stripe[i][9], stripe[i][10], stripe[i][11]));
					CGContextDrawLinearGradient(context, gradient, CGPointMake(15, 5), CGPointMake(15, 25), 0);
					CGContextRestoreGState(context);
					CGGradientRelease(gradient);
				}

				CGContextMoveToPoint(context, 4, 15);
				CGContextAddArcToPoint(context, 4, 4, 15, 4, 4);
				CGContextAddArcToPoint(context, 26, 4, 26, 15, 4);
				CGContextAddArcToPoint(context, 26, 26, 15, 26, 4);
				CGContextAddArcToPoint(context, 4, 26, 4, 15, 4);
				CGContextClosePath(context);
				CGContextStrokePath(context);
				break;
			}
			case BUTTON_HUE:
			{
				CGGradientRef gradient;
				CGFloat hue[8];
				const int angle = 4;
				
				// A radial gradient, inside a circle
				for (i = 0; i < 360; i+=angle)
				{
					float x = cosf((i+angle*0.5)*DEG2RAD)*10+15;
					float y = sinf((i+angle*0.5)*DEG2RAD)*10+15;
					float r = (i    )/180.0; if (r > 1.0) r = 2.0-r;
					float g = (i+120)/180.0; if (g > 2.0) g = g-2.0; else if (g > 1.0) g = 2.0-g;
					float b = (i+240)/180.0; if (b > 3.0) b = 4.0-b; else if (b > 2.0) b = b-2.0; else b = 2.0-b;
					float a = (i+ 90)/180.0; if (a > 2.0) a = a-2.0; else if (a > 1.0) a = 2.0-a;
					hue[0] = hue[4] = r;
					hue[1] = hue[5] = g;
					hue[2] = hue[6] = b;
					hue[3] = a*0.5;
					hue[7] = a*0.75;

					gradient = CGGradientCreateWithColorComponents(colorSpace, hue, NULL, 2);
					CGContextSaveGState(context);
					CGContextMoveToPoint(context, 15, 15);
					CGContextAddArc(context, 15, 15, 10, i*DEG2RAD, (i+angle)*DEG2RAD, false);
					CGContextClosePath(context);
					CGContextClip(context);
					CGContextDrawLinearGradient(context, gradient, CGPointMake(x, y), CGPointMake(15, 15), 0);					
					CGContextRestoreGState(context);
					CGGradientRelease(gradient);
				}

				CGContextStrokeEllipseInRect(context, CGRectMake(4.0, 4.0, 22.0, 22.0));
				break;
			}
			case BUTTON_SHARPNESS:
			{
				int x, y;
				
				// A gradient checkerboard, inside a rounded rect
				for (x = 5; x < 25; x+=2)
				{
					float b = (x - 5)/19.0*0.5+0.375;
					if (b > 0.75) b = 0.75;
					else if (b < 0.5) b = 0.5;
					
					for (y = 5; y < 25; y+=2)
					{
						float k = ((x ^ y) & 2) ? b : 1.0-b;
						CGContextSetRGBFillColor(context, k, k, k, k);
						CGContextFillRect(context, CGRectMake(x, y, 2, 2));
					}
				}
		
				CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
				CGContextMoveToPoint(context, 4, 15);
				CGContextAddArcToPoint(context, 4, 4, 15, 4, 4);
				CGContextAddArcToPoint(context, 26, 4, 26, 15, 4);
				CGContextAddArcToPoint(context, 26, 26, 15, 26, 4);
				CGContextAddArcToPoint(context, 4, 26, 4, 15, 4);
				CGContextClosePath(context);
				CGContextStrokePath(context);
				break;
			}
		}
		theCGImage = CGBitmapContextCreateImage(context);
		((UITabBarItem *)[tabBar.items objectAtIndex:b]).image = [UIImage imageWithCGImage:theCGImage];
		CGImageRelease(theCGImage);
	}

	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
}


- (void)dealloc
{
	self.slider = nil;
	self.tabBar = nil;
    [super dealloc];
}


- (void)sliderAction:(id)sender
{
	// Redraw the view with the new settings
	[((EAGLView*)self.view) drawView];
}


- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
	// Recenter the slider (this application does not accumulate multiple filters)
	[self.slider setValue:1.0 animated:YES];
	// Redraw the view with the new settings
	[((EAGLView*)self.view) drawView];
}

@end
