/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A gesture recognizer that emulates a game controller. Slide left or right on the left half of the screen to move the character, and tap on the right half of the screen to jump.
  
 */

#import <UIKit/UIKit.h>

@interface AAPLVirtualDPadGestureRecognizer : UIGestureRecognizer

@property (nonatomic, assign, getter = isLeftPressed) BOOL leftPressed;
@property (nonatomic, assign, getter = isRightPressed) BOOL rightPressed;
@property (nonatomic, assign, getter = isRunning) BOOL running;

@property (nonatomic, assign, getter = isButtonAPressed) BOOL buttonAPressed;

@property (nonatomic, assign) CGRect virtialDPadRect;
@property (nonatomic, assign) CGFloat virtualDPadWalkThreshold;
@property (nonatomic, assign) CGFloat virtualDPadRunThreshold;

@property (nonatomic, assign) CGRect buttonARect;

@end
