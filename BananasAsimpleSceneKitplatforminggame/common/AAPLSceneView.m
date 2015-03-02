/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The view displaying the game scene. Handles keyboard (OS X) and touch (iOS) input for controlling the game, and forwards other click/touch events to the SpriteKit overlay UI.
  
 */

#import <SpriteKit/SpriteKit.h>
#import <SceneKit/SceneKit.h>

#import "AAPLSceneView.h"
#import "AAPLInGameScene.h"
#import "AAPLGameLevel.h"

#if TARGET_OS_IPHONE
#import "AAPLVirtualDPadGestureRecognizer.h"
#import "AAPLGameSimulation.h"

@interface AAPLSceneView () <UIGestureRecognizerDelegate>

@end

#endif

NSString *AAPLLeftKey = @"AAPLLeftKey";
NSString *AAPLRightKey = @"AAPLRightKey";
NSString *AAPLJumpKey = @"AAPLJumpKey";
NSString *AAPLRunKey = @"AAPLRunKey";

@implementation AAPLSceneView

// Keyspressed is our set of current inputs
- (void)updateKey:(NSString *)key isPressed:(BOOL)isPressed
{
	if (!self.keysPressed) {
		self.keysPressed = [[NSMutableSet alloc] init];
	}
	if (isPressed) {
		[self.keysPressed addObject:key];
	} else {
		[self.keysPressed removeObject:key];
	}
}

#if TARGET_OS_IPHONE

- (instancetype)init
{
	self = [super init];
	if (self) {
		AAPLVirtualDPadGestureRecognizer *gesture = [[AAPLVirtualDPadGestureRecognizer alloc] initWithTarget:self action:@selector(handleVirtualDPadAction:)];
		gesture.delegate = self;
		[self addGestureRecognizer:gesture];
	}
	return self;
}

- (void)handleVirtualDPadAction:(AAPLVirtualDPadGestureRecognizer *)gesture
{
	[self updateKey:AAPLLeftKey isPressed:gesture.leftPressed];
	[self updateKey:AAPLRightKey isPressed:gesture.rightPressed];
	[self updateKey:AAPLRunKey isPressed:gesture.running];
	[self updateKey:AAPLJumpKey isPressed:gesture.buttonAPressed];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	if (self.scene) {
		return [AAPLGameSimulation sim].gameState == AAPLGameStateInGame;
	}
	return NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	AAPLInGameScene *skScene = (AAPLInGameScene *)self.overlaySKScene;
	UITouch *touch = [touches anyObject];
	CGPoint p = [touch locationInNode:skScene];
	[skScene touchUpAtPoint:p];
	[super touchesEnded:touches withEvent:event];
}

#else

- (void)keyDown:(NSEvent *)theEvent
{

	NSNumber *keyHit = [NSNumber numberWithUnsignedInt:[[theEvent characters] characterAtIndex:0]];


	if ([theEvent modifierFlags] & NSShiftKeyMask) {
		[self updateKey:AAPLRunKey isPressed:YES];
	}

	switch ([keyHit unsignedIntValue]) {
		case NSRightArrowFunctionKey:
			[self updateKey:AAPLRightKey isPressed:YES];
			return;
		case NSLeftArrowFunctionKey:
			[self updateKey:AAPLLeftKey isPressed:YES];
			return;
		case 'r':
			[self updateKey:AAPLRunKey isPressed:YES];
			return;
		case ' ':
			[self updateKey:AAPLJumpKey isPressed:YES];
			return;
		default:
			break;
	}

	[super keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
	if (!self.keysPressed) {
		self.keysPressed = [[NSMutableSet alloc] init];
	}

	NSNumber *keyReleased = [NSNumber numberWithUnsignedInt:[[theEvent characters] characterAtIndex:0]];

	switch ([keyReleased unsignedIntValue]) {
		case NSRightArrowFunctionKey:
			[self updateKey:AAPLRightKey isPressed:NO];
			break;
		case NSLeftArrowFunctionKey:
			[self updateKey:AAPLLeftKey isPressed:NO];
			break;
		case 'r':
			[self updateKey:AAPLRunKey isPressed:NO];
			break;
		case ' ':
			[self updateKey:AAPLJumpKey isPressed:NO];
			break;
		default:
			break;
	}

	if ([theEvent modifierFlags] & NSShiftKeyMask) {
		[self updateKey:AAPLRunKey isPressed:NO];
	}
}

- (void)mouseUp:(NSEvent *)event
{
	AAPLInGameScene *skScene = (AAPLInGameScene *)self.overlaySKScene;
	CGPoint p = [skScene convertPointFromView:[event locationInWindow]];
	[skScene touchUpAtPoint:p];

	[super mouseUp:event];
}

#endif

@end
