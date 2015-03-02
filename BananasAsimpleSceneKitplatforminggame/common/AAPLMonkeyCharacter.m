/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class simulates the monkeys in the game. It includes game logic for determining each monkey's actions and also manages the monkey's animations.
  
 */

#import <GLKit/GLKit.h>
#import "AAPLMonkeyCharacter.h"
#import "AAPLGameSimulation.h"
#import "AAPLGameLevel.h"
#import "AAPLCoconut.h"
#import "AAPLPlayerCharacter.h"
#import "AAPLMathUtils.h"

@interface AAPLMonkeyCharacter () {
	BOOL isIdle;
	BOOL hasCoconut;
}

@end

@implementation AAPLMonkeyCharacter

- (void)createAnimations
{

	self.name = @"monkey";
	self.rightHand = [self childNodeWithName:@"Bone_R_Hand" recursively:YES];

	isIdle = YES;
	hasCoconut = NO;

	//load and cache animations
	[self setupTauntAnimation];
	[self setupHangAnimation];
	[self setupGetCoconutAnimation];
	[self setupThrowAnimation];

	//-- Sequence: get -> throw
	[self chainAnimation:@"monkey_get_coconut-1" toAnimation:@"monkey_throw_coconut-1"];

	// start the ball rolling with hanging in the tree.
	[self.mainSkeleton addAnimation:[self cachedAnimationForKey:@"monkey_tree_hang-1"] forKey:@"monkey_idle"];
}

- (void)setupTauntAnimation
{
	CAAnimation *taunt = [self loadAndCacheAnimation:[AAPLGameSimulation pathForArtResource:@"characters/monkey/monkey_tree_hang_taunt"]
											  forKey:@"monkey_tree_hang_taunt-1"];

	taunt.repeatCount = 0;

	SCNAnimationEventBlock ackBlock = ^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {
		[[AAPLGameSimulation sim] playSound:@"ack.caf"];
	};

	taunt.animationEvents = @[[SCNAnimationEvent animationEventWithKeyTime:0.0f block:ackBlock],
							  [SCNAnimationEvent animationEventWithKeyTime:1.0f block:^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {
								  isIdle = YES;
							  }
							   ]];
}

- (void)setupHangAnimation
{
	CAAnimation *hang = [self loadAndCacheAnimation:[AAPLGameSimulation pathForArtResource:@"characters/monkey/monkey_tree_hang"]
											 forKey:@"monkey_tree_hang-1"];
	hang.repeatCount = MAXFLOAT;
}

- (void)setupGetCoconutAnimation
{
	SCNAnimationEventBlock pickupEventBlock = ^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {
		[self.coconut removeFromParentNode];
		self.coconut = [AAPLCoconut coconutProtoObject];
		[self.rightHand addChildNode:self.coconut];
		hasCoconut = YES;
	};

	CAAnimation *getAnimation = [self loadAndCacheAnimation:[AAPLGameSimulation pathForArtResource:@"characters/monkey/monkey_get_coconut"] forKey:@"monkey_get_coconut-1"];
	if (getAnimation.animationEvents == nil) {
		getAnimation.animationEvents = @[[SCNAnimationEvent animationEventWithKeyTime:0.40f block:pickupEventBlock]];
	}

	getAnimation.repeatCount = 0;
}

- (void)setupThrowAnimation
{
	CAAnimation *throw = [self loadAndCacheAnimation:[AAPLGameSimulation pathForArtResource:@"characters/monkey/monkey_throw_coconut"] forKey:@"monkey_throw_coconut-1"];
	throw.speed = 1.5f;
	if (throw.animationEvents == nil || throw.animationEvents.count == 0) {
		SCNAnimationEventBlock throwEventBlock = ^(CAAnimation *animation, id animatedObject, BOOL playingBackward) {

			if (hasCoconut) {
				SCNMatrix4 worldMtx = self.coconut.presentationNode.worldTransform;
				[self.coconut removeFromParentNode];

				AAPLCoconut *node =  [AAPLCoconut coconutThrowProtoObject];
				SCNPhysicsShape *coconutPhysicsShape = [AAPLCoconut coconutPhysicsShape];
				node.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:coconutPhysicsShape];
				node.physicsBody.restitution = 0.9;
				node.physicsBody.collisionBitMask = GameCollisionCategoryPlayer | GameCollisionCategoryGround;
				node.physicsBody.categoryBitMask = GameCollisionCategoryCoconut;

				node.transform = worldMtx;
				[[AAPLGameSimulation sim].rootNode addChildNode:node];
				[[AAPLGameSimulation sim].gameLevel.coconuts addObject:node];
				[node.physicsBody applyForce:SCNVector3Make(-200, 500, 300) impulse:YES];
				hasCoconut = NO;
				isIdle = YES;
			}
		};
		throw.animationEvents = @[[SCNAnimationEvent animationEventWithKeyTime:0.35f block:throwEventBlock]];
	}

	throw.repeatCount = 0;
}

/*! update the Monkey and decide when to throw a coconut
 */
- (void)update:(NSTimeInterval)deltaTime
{
	CGFloat distanceToCharacter = FLT_MAX;
	AAPLPlayerCharacter *playerCharacter = [AAPLGameSimulation sim].gameLevel.playerCharacter;

	SCNVector3 pos = AAPLMatrix4GetPosition(self.presentationNode.worldTransform);
	GLKVector3 myPosition = GLKVector3Make(pos.x, pos.y, pos.z);

	// If the player is to the left of the monkey, calculate how far away the character is.
	if (playerCharacter.position.x < myPosition.x) {
		distanceToCharacter = GLKVector3Distance(SCNVector3ToGLKVector3(playerCharacter.position), myPosition);
	}

	// If the character is close enough and not moving, throw a coconut.
	if (distanceToCharacter < 700) {
		if (isIdle) {
			if (playerCharacter.isRunning == YES) {
				[self.mainSkeleton addAnimation:[self cachedAnimationForKey:@"monkey_get_coconut-1"] forKey:nil];
				isIdle = NO;
			} else {
				// taunt the player if they aren't moving.
				if (AAPLRandomPercent() <= 0.001f) {
					isIdle = NO;
					[self.mainSkeleton addAnimation:[self cachedAnimationForKey:@"monkey_tree_hang_taunt-1"]
											 forKey:nil];
				}
			}
		}
		
	}
}

@end
