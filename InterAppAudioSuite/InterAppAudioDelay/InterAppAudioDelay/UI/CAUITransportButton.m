//
/*
     File: CAUITransportButton.m
 Abstract: 
 This UIButton subclass programatically draws a transport button with a particular drawing style.
 It features a fill color that can be an accent color.
 If the button has the recordEnabledButtonStyle, it pulses on and off.

 These buttons resize themselves dynamically at runtime so that their bounds is a minimum of 44 x 44 pts
 in order to make them easy to press.
 The button image will draw at the original size specified in the storyboard

  Version: 1.1.2
 
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

#import "CAUITransportButton.h"


@implementation CAUITransportButton
{
	CGRect	imageRect;
}

@synthesize drawingStyle;
@synthesize fillColor;

- (id) initWithCoder:(NSCoder *) aDecoder {
	self = [super initWithCoder: aDecoder];
	
	if (self) {
		imageRect = self.bounds;
		CGFloat widthDelta = 44 - self.bounds.size.width;
		CGFloat heightDelta= 44 - self.bounds.size.height;
		
		if (widthDelta > 0 || heightDelta > 0) {
			// update the frame
			CGRect bounds = CGRectMake(0, 0, widthDelta > 0 ? 44 : imageRect.size.width, heightDelta > 0 ? 44 : imageRect.size.height);
			CGRect frame  = CGRectMake(widthDelta > 0 ? roundf(self.frame.origin.x - (widthDelta / 2)) : self.frame.origin.x,
									   heightDelta > 0? roundf(self.frame.origin.y - (heightDelta/ 2)) : self.frame.origin.y,
									   bounds.size.width, bounds.size.height);
			
			self.frame = frame;
			self.bounds = bounds;
		}
	}
	return self;
}

+ (Class) layerClass {
	return [CAShapeLayer class];
}

double toRadians(double degrees) {
    return (degrees * M_PI)/180.0;
}

/* sets the drawing style of the button and updates the appearance of the button */
- (void) setDrawingStyle:(CAUITransportButtonStyle) style {
	if (drawingStyle != style) {
		drawingStyle = style;
		CGPathRef path = [self newPathRefForStyle: style];
		((CAShapeLayer *)self.layer).path = path;
		CGPathRelease (path);
		
		self.backgroundColor = [UIColor clearColor];
		
		if (style == recordEnabledButtonStyle) {
			[UIView animateWithDuration:1 delay:0 options: UIViewAnimationOptionCurveLinear animations: ^{
				((CAShapeLayer *)self.layer).strokeColor = self.fillColor;
				((CAShapeLayer *)self.layer).fillColor = self.fillColor;
				((CAShapeLayer *)self.layer).lineWidth = .5;
				[self flash];
			}			completion:nil];
			
		} else if (style == recordButtonStyle) {
			[((CAShapeLayer *)self.layer) removeAllAnimations];
			[UIView animateWithDuration:1 delay:0 options: UIViewAnimationOptionCurveLinear animations: ^{
				((CAShapeLayer *)self.layer).strokeColor = [UIColor clearColor].CGColor;
				((CAShapeLayer *)self.layer).fillColor = fillColor;
				((CAShapeLayer *)self.layer).lineWidth = 0;
			}			completion:NULL];
		}
	}
}

- (void) flash {
	UIColor *color = [[UIColor colorWithCGColor: fillColor] colorWithAlphaComponent: .2];
	[CATransaction begin];
	CABasicAnimation *strokeAnim = [CABasicAnimation animationWithKeyPath:@"fillColor"];
    strokeAnim.fromValue         = (id) ((CAShapeLayer *)self.layer).fillColor;
    strokeAnim.toValue           = (id) color.CGColor;
    strokeAnim.duration          = 2.0;
    strokeAnim.repeatCount       = 0;
    strokeAnim.autoreverses      = YES;
	[CATransaction setCompletionBlock: ^{
		if (drawingStyle == recordEnabledButtonStyle)
			[self flash];
	}];
    [((CAShapeLayer *)self.layer) addAnimation:strokeAnim forKey:@"animateStrokeColor"];
	[CATransaction commit];
}


- (void) setFillColor:(CGColorRef) color {
	fillColor = color;
	((CAShapeLayer *)self.layer).fillColor = color;
}

- (CGPathRef) newPathRefForStyle: (CAUITransportButtonStyle) style {
	CGPathRef path = NULL;
	CGFloat size = MIN(imageRect.size.width, imageRect.size.height);
	
	switch (style) {
		case rewindButtonStyle:
		{
			CGMutablePathRef tempPath = CGPathCreateMutable();
			CGFloat height = size * 0.613;
			CGFloat width = size;
			CGFloat yOffset = roundf((imageRect.size.height - height)/2);
			CGFloat radius  = (size * .0631)/2;
			
			height = roundf(height);
			
			// first arrow
			CGPathAddArc(tempPath, NULL, radius, yOffset + height/2, radius, toRadians(120), toRadians(240), NO);
			CGPathAddArc(tempPath, NULL, .5 * width - radius, yOffset + radius, radius, toRadians(240), toRadians(0), NO);
			CGPathAddArc(tempPath, NULL, .5 * width - radius, yOffset + height - radius, radius, toRadians(0), toRadians(120), NO);
			CGPathCloseSubpath(tempPath);
			
			// second arrow
			CGPathMoveToPoint(tempPath, NULL, .5*size, yOffset + height/2);
			CGPathAddArc(tempPath, NULL, .5*size + radius, yOffset + height/2, radius, toRadians(180), toRadians(240), NO);
			CGPathAddArc(tempPath, NULL, width - radius, yOffset + radius, radius, toRadians(240), toRadians(0), NO);
			CGPathAddArc(tempPath, NULL, width - radius, yOffset + height - radius, radius, toRadians(0), toRadians(120), NO);
			CGPathAddArc(tempPath, NULL, .5*size + radius, yOffset + height/2, radius, toRadians(120), toRadians(180), NO);
			CGPathCloseSubpath(tempPath);
			
			path = tempPath;
		}
			break;
		case pauseButtonStyle:
		{
			CGMutablePathRef tempPath = CGPathCreateMutable();
			CGFloat height = size * 0.857;
			CGFloat width  = size * .7452;
			CGFloat barWidth = size * .2776;
			CGFloat xOffset = roundf((imageRect.size.width - width)/2);
			CGFloat	yOffset = roundf((imageRect.size.height - height)/2);
			CGFloat radius = (size * 0.0397)/2;
			
			height = roundf(height);
			
			CGPathAddRoundedRect(tempPath, NULL, CGRectMake(xOffset, yOffset, barWidth, height), radius, radius);
			CGPathAddRoundedRect(tempPath, NULL, CGRectMake(roundf(imageRect.size.width - xOffset - barWidth), yOffset, barWidth, height), radius, radius);
			
			path = tempPath;
		}
			break;
		case playButtonStyle:
		{
			CGMutablePathRef tempPath = CGPathCreateMutable();
			CGFloat height = size * .857;
			CGFloat width  = size * .6538;
			CGFloat xOffset = roundf((imageRect.size.width - width)/2);
			CGFloat yOffset = roundf((imageRect.size.height - height)/2);
			CGFloat radius  = (size * .0631)/2;
			
			height = roundf(height);
			
			CGPathAddArc(tempPath, NULL, xOffset + radius, yOffset + radius, radius, toRadians(180), toRadians(300), NO);
			CGPathAddArc(tempPath, NULL, xOffset + width - radius, yOffset + height/2, radius, toRadians(300), toRadians(60), NO);
			CGPathAddArc(tempPath, NULL, xOffset + radius, yOffset + height - radius, radius, toRadians(60), toRadians(180), NO);
			CGPathCloseSubpath(tempPath);
			path = tempPath;
		}
			break;
		case recordButtonStyle:
		case recordEnabledButtonStyle:
		{
			size *= .7825;
			CGRect elipseRect = CGRectMake((imageRect.size.width - size)/2, (imageRect.size.height - size)/2, size, size);
			path = CGPathCreateWithEllipseInRect(elipseRect, NULL);
		}
			break;
	}
	return path;
}

@end
