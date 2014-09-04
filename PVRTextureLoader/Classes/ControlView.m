/*

    File: ControlView.m
Abstract: ControlView is a UIView subclass responsible for displaying and hidding controls.
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

#import "ControlView.h"

const float gBarHeight = 30.0f;

@implementation ControlView

@synthesize contentHeight = _contentHeight;
@synthesize open = _isOpen;


- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
	{
		_isOpen = FALSE;
		_contentHeight = frame.size.height - gBarHeight;
		
		// Gradient setup for bar
		CGFloat barColors[8] = {
			0.30f, 0.30f, 0.30f, 0.75f,
			0.00f, 0.00f, 0.00f, 0.75f
		};
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		if (colorSpace != NULL)
		{
			_barGradient = CGGradientCreateWithColorComponents(colorSpace, barColors, NULL, 2);
			if (_barGradient == NULL)
				NSLog(@"Failed to create CGGradient");
			CGColorSpaceRelease(colorSpace);
		}
		_barStartPoint = CGPointMake(0.0f, 0.0f);
		_barEndPoint = CGPointMake(0.0f, gBarHeight);
		
		// Image setup for bar
		UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Triangle" ofType:@"png"]];
		if (image == nil)
			NSLog(@"Failed to load image for control vieww");
		
		_barImageView = [[[UIImageView alloc] initWithImage:image] autorelease];
		CGRect imageViewFrame = _barImageView.frame;
		imageViewFrame.origin.x = floorf((frame.size.width/2.0f) - (imageViewFrame.size.width/2.0f));
		imageViewFrame.origin.y = floorf((gBarHeight/2.0f) - (imageViewFrame.size.height/2.0f));
		[_barImageView setFrame:imageViewFrame];
		
		[self addSubview:_barImageView];
		
		_barImageViewRotation = CGAffineTransformMake(cos(-M_PI), sin(-M_PI), -sin(-M_PI), cos(-M_PI), 0.0f, 0.0f);

		self.opaque = FALSE;
    }

    return self;
}


+ (CGFloat)barHeight
{
	return gBarHeight;
}


- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	
	CGContextDrawLinearGradient(context, _barGradient, _barStartPoint, _barEndPoint, kCGGradientDrawsAfterEndLocation);
	
	CGContextSetRGBFillColor(context, 0.25f, 0.25f, 0.25f, 1.0f);
	UIRectFill(CGRectMake(0.0f, 0.0f, self.frame.size.width, 1.0f));
	
	CGContextRestoreGState(context);
}


- (void)dealloc
{
	CGGradientRelease(_barGradient);
	
    [super dealloc];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch;
	CGPoint point;
	
	if ([touches count] > 0)
	{
		touch = [[touches allObjects] objectAtIndex:0];
		point = [touch locationInView:self];
		
		if (point.y <= gBarHeight)
		{
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:0.25f];

			CGRect frame = [self frame];
			
			if (_isOpen == FALSE)
			{
				frame.origin.y -= _contentHeight;
				[_barImageView setTransform:_barImageViewRotation];
				_isOpen = TRUE;
			}
			else
			{
				frame.origin.y += _contentHeight;
				[_barImageView setTransform:CGAffineTransformIdentity];
				_isOpen = FALSE;
			}
			
			[self setFrame:frame];
			
			[UIView commitAnimations];
		}
	}
}

@end
