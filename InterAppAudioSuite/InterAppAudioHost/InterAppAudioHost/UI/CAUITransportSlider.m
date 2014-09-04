/*
     File: CAUITransportSlider.m
 Abstract: 
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

#import "CAUITransportSlider.h"

#define kPositionBarWidthRatio	0.047f
#define kPositionBarHeightRatio	0.345f
#define kPositionBarRadiusRatio 0.023f
#define kPositionBarOffsetRatio 0.156f

#define kBarVerticalOffsetRatio 0.442f
#define kBarHeightRatio			0.154f

#pragma mark - CAUITransportKnob Implementation
@implementation CAUITransportKnob
#pragma mark Initialization
- (id) initWithFrame:(CGRect) frame {
	self = [super initWithFrame: frame];
	if (self) {
		self.primaryColor = [UIColor colorWithWhite:.2 alpha:1];
		
		CGFloat positionBarWidth = kPositionBarWidthRatio * frame.size.width;
		CGFloat positionBarHeight = kPositionBarHeightRatio * frame.size.height;
		CGPathRef path = CGPathCreateWithRoundedRect(CGRectMake(roundf((frame.size.width - positionBarWidth)/2), ceilf((frame.size.height - positionBarHeight)/2), positionBarWidth, positionBarHeight), kPositionBarRadiusRatio * frame.size.width, kPositionBarRadiusRatio * frame.size.height, NULL);
		((CAShapeLayer *) self.layer).path = path;
		CGPathRelease(path);

		((CAShapeLayer *) self.layer).fillColor = self.primaryColor.CGColor;

		self.userInteractionEnabled = NO;	// we want the parent view to get all touch events
	}
	return self;
}

+ (Class) layerClass {
	return [CAShapeLayer class];
}

#pragma mark Properties
- (void) setPrimaryColor:(UIColor *)color {
	[color retain];
	[primaryColor release];
	primaryColor = color;
	((CAShapeLayer *) self.layer).fillColor = self.primaryColor.CGColor;
}

- (UIColor *) primaryColor {
	return primaryColor;
}

@end

#pragma mark - CAUITransportSlider Implementation
@implementation CAUITransportSlider
@synthesize secondaryColor;

#pragma mark Initialization / Deallocation
- (id) initWithCoder:(NSCoder *) aDecoder {
	self = [super initWithCoder: aDecoder];
	if (self)
		[self initialize];

	return self;
}

- (void) initialize {	
	// rectangle knob
	knob = [[CAUITransportKnob alloc] initWithFrame: CGRectMake(0, 0, self.frame.size.height, self.frame.size.height)];
	
	self.secondaryColor = [UIColor colorWithWhite:.887 alpha:1];
	self.primaryColor   = [UIColor colorWithWhite:.2 alpha:1];
	self.backgroundColor = [UIColor clearColor];

	[self addSubview: knob];
	
	self.userInteractionEnabled = YES;
	
	[self updateBarFrame];
	[knob addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context: nil];
}

- (void) dealloc {
	[knob removeFromSuperview];
	[knob removeObserver:self forKeyPath: @"frame"];
	
	[super dealloc];
}

#pragma mark Properties
- (CGFloat) currentPosition {
	return currentPosition;
}

- (void) setCurrentPosition:(CGFloat) position {
	if (position != currentPosition) {
		if (position > 1)
			currentPosition = 1;
		else if (position < 0)
			currentPosition = 0;
		else
			currentPosition = position;
		knob.frame = CGRectMake((currentPosition*barRect.size.width), 0, knob.frame.size.width, knob.frame.size.width);
	}
}

- (UIColor *) primaryColor {
	return primaryColor;
}

- (void) setPrimaryColor:(UIColor *) color {
	[color retain];
	[primaryColor release];
	primaryColor = color;
	
	knob.primaryColor = color;
	
	[self setNeedsDisplay];
}

- (void) setEnabled:(BOOL) isEnabled {
	if (isEnabled != self.enabled) {
		[super setEnabled: isEnabled];
		
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationDelay:0];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		
		knob.alpha = isEnabled ? 1 : .8;
		self.alpha = isEnabled ? 1 : .75;
		
		[UIView commitAnimations];
		
		[self setNeedsDisplay];
	}
}

#pragma mark KVO methods
+ (BOOL) automaticallyNotifiesObserversForKey:(NSString *)key {
	BOOL automatic = YES;
	if ([key isEqualToString: @"currentPosition"])
		automatic = NO;
	return automatic;
}

- (void) observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary *) change context:(void *) context {
	if ([keyPath isEqualToString: @"frame"]) {
		CGRect frame = ((CAUITransportKnob *)object).frame;
		currentPosition = frame.origin.x / barRect.size.width;
        
		[self setNeedsDisplay];
	}
}

#pragma mark Resizing and Drawing methods
- (void) updateBarFrame {
	CGRect frame = self.bounds;
	
	barRect = CGRectMake(roundf(knob.frame.size.width/2), floorf(kBarVerticalOffsetRatio * frame.size.height), frame.size.width - knob.frame.size.width, roundf(kBarHeightRatio * frame.size.height));
    
	[self setNeedsDisplay];
}

- (void) drawRect:(CGRect) rect {
    // Drawing code
	CGRect rightRect = barRect;
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	if (!self.enabled) {
		[[secondaryColor colorWithAlphaComponent: self.alpha] set];
		CGContextFillRect(ctx, rightRect);
		
		[super drawRect: rect];
		return;
	}
	if (currentPosition > 0) {
		[primaryColor setFill];
		CGFloat position = roundf(barRect.origin.x + (currentPosition * barRect.size.width) - knob.frame.size.width/2);
		
		CGRect leftRect = barRect;
		leftRect.size.width = position;
		
		CGContextFillRect(ctx, leftRect);
		
		rightRect.origin.x = barRect.origin.x + position;
		rightRect.size.width = barRect.size.width - position;
	}
	[[secondaryColor colorWithAlphaComponent: self.alpha] setFill];
	CGContextFillRect(ctx, rightRect);
	
	[super drawRect: rect];
}

#pragma mark Event Handling
- (BOOL) beginTrackingWithTouch:(UITouch *) touch withEvent:(UIEvent *) event {
    [super beginTrackingWithTouch:touch withEvent:event];
	
	CGPoint pt = [touch locationInView:self];

	if (CGRectContainsPoint(knob.frame, pt)) {
		lastPoint = pt;
		startPoint = lastPoint;
		
		return YES;
	}
    return NO;
}

- (BOOL) continueTrackingWithTouch:(UITouch *) touch withEvent:(UIEvent *) event {
    [super continueTrackingWithTouch:touch withEvent:event];
	
    //Get touch location
    CGPoint pt = [touch locationInView:self];
	
    //Use the location to design the Handle
	if (lastPoint.x != 0 && lastPoint.y != 0) {
		CGRect myFrame = knob.frame;
		if (pt.x != lastPoint.x && fabsf(startPoint.x - pt.x) >= 2)
			myFrame.origin.x = knob.frame.origin.x + (pt.x - lastPoint.x);
		if (myFrame.origin.x < 0)
			myFrame.origin.x = 0;
		else if (myFrame.origin.x > barRect.size.width)
			myFrame.origin.x = barRect.size.width;
        
		knob.frame = myFrame;
		lastPoint = pt;
		
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}
    return YES;
}

@end
