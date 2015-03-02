/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class simulates the player character. It manages the character's animations and simulates movement and jumping.
  
 */

#import <SceneKit/SceneKit.h>
#import "AAPLSkinnedCharacter.h"

typedef NS_ENUM(NSInteger, WalkDirection) {
	WalkDirectionLeft = 0,
	WalkDirectionRight,
};

@interface AAPLPlayerCharacter : AAPLSkinnedCharacter

// Animation State
@property (nonatomic) BOOL inRunAnimation;
@property (nonatomic) BOOL inHitAnimation;

- (void)performJumpAndStop:(BOOL)stop;

@property (nonatomic) CGFloat walkSpeed;
@property (nonatomic) CGFloat jumpBoost;

@property (nonatomic) WalkDirection walkDirection;

@property (readonly, nonatomic) SCNNode *collideSphere;

@property (nonatomic, getter=isRunning) BOOL running;
@property (nonatomic, getter=isJumping) BOOL jumping;
@property (nonatomic, getter=isLaunching) BOOL launching;

@property (nonatomic) SCNParticleSystem *dustPoof;
@property (nonatomic) SCNParticleSystem *dustWalking;

@end
