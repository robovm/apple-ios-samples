/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A gesture recognizer that emulates a game controller. Slide left or right on the left half of the screen to move the character, and tap on the right half of the screen to jump.
  
 */

#import "AAPLVirtualDPadGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation AAPLVirtualDPadGestureRecognizer {
	UITouch *_dpadTouch;
	CGPoint _originalLocation;
	UITouch *_buttonATouch;
}

- (id)initWithTarget:(id)target action:(SEL)action
{
	self = [super initWithTarget:target action:action];
	if (self) {
		self.virtialDPadRect = CGRectMake(0, 0, 0.5, 1);
		self.buttonARect = CGRectMake(0.5, 0, 0.5, 1);
		self.virtualDPadWalkThreshold = 20;
		self.virtualDPadRunThreshold = 40;
	}
	return self;
}

- (BOOL)touch:(UITouch *)touch isInRect:(CGRect)rect
{
	CGRect bounds = self.view.bounds;
	rect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(bounds.size.width, bounds.size.height));
	return CGRectContainsPoint(rect, [touch locationInView:self.view]);
}

- (void)reset;
{
	_dpadTouch = _buttonATouch = nil;
	self.leftPressed = self.rightPressed = self.buttonAPressed = NO;
	[super reset];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UITouch *touch in touches) {
		if (_dpadTouch == nil && [self touch:touch isInRect:self.virtialDPadRect]) {
			_dpadTouch = touch;
			_originalLocation = [touch locationInView:self.view];
			self.state = UIGestureRecognizerStateBegan;
		} else if (_buttonATouch == nil && [self touch:touch isInRect:self.buttonARect]) {
			_buttonATouch = touch;
			self.buttonAPressed = YES;
			self.state = UIGestureRecognizerStateBegan;
		} else {
			[self ignoreTouch:touch forEvent:event];
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UITouch *touch in touches) {
		if (touch == _dpadTouch) {
			CGPoint location = [touch locationInView:self.view];
			CGFloat deltaX = location.x - _originalLocation.x;
			self.leftPressed = (deltaX < -self.virtualDPadWalkThreshold);
			self.rightPressed = (deltaX > self.virtualDPadWalkThreshold);
			self.running = ABS(deltaX) > self.virtualDPadRunThreshold;
			self.state = UIGestureRecognizerStateChanged;
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (_dpadTouch != nil || _buttonATouch != nil) {
		for (UITouch *touch in touches) {
			if (touch == _dpadTouch) {
				_dpadTouch = nil;
				self.leftPressed = self.rightPressed = NO;
			} else if (touch == _buttonATouch) {
				_buttonATouch = nil;
				self.buttonAPressed = NO;
			}
		}
		if (_dpadTouch != nil || _buttonATouch != nil) {
			self.state = UIGestureRecognizerStateChanged;
		} else {
			self.state = UIGestureRecognizerStateCancelled;
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (_dpadTouch != nil || _buttonATouch != nil) {
		for (UITouch *touch in touches) {
			if (touch == _dpadTouch) {
				_dpadTouch = nil;
				self.leftPressed = self.rightPressed = NO;
			} else if (touch == _buttonATouch) {
				_buttonATouch = nil;
				self.buttonAPressed = NO;
			}
		}
		if (_dpadTouch != nil || _buttonATouch != nil) {
			self.state = UIGestureRecognizerStateChanged;
		} else {
			self.state = UIGestureRecognizerStateEnded;
		}
	}
}

@end
