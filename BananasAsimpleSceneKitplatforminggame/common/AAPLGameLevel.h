/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
 This class manages most of the game logic, including setting up the scene and keeping score.
  
 */

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

#import "AAPLGameSimulation.h"

@class AAPLPlayerCharacter;
@class AAPLCoconut;

@interface AAPLGameLevel : NSObject <AAPLGameUIState>

- (SCNNode *)createLevel;
- (SCNNode *)createBanana;
- (void)collectBanana:(SCNNode *)banana;
- (void)collectLargeBanana:(SCNNode *)largeBanana;
- (void)collideWithCoconut:(SCNNode *)coconut point:(SCNVector3)contactPoint;
- (void)collideWithLava;
- (SCNVector3)locationAlongPath:(CGFloat)percent;

- (void)resetLevel;
- (void)update:(NSTimeInterval)deltaTime withRenderer:(id <SCNSceneRenderer>)aRenderer;

@property (strong, nonatomic) AAPLPlayerCharacter *playerCharacter;
@property (strong, nonatomic) AAPLPlayerCharacter *monkeyCharacter;
@property (strong, nonatomic) SCNNode *camera;
@property (strong, nonatomic) NSMutableSet *bananas;
@property (strong, nonatomic) NSMutableSet *largeBananas;
@property (strong, nonatomic) NSMutableArray *coconuts;
@property (assign, nonatomic) BOOL hitByLavaReset;

@property (assign, nonatomic) CGFloat timeAlongPath;

/* GameUIState protocol */
@property (readonly, nonatomic) NSUInteger score;
@property (readonly, nonatomic) NSUInteger coinsCollected;
@property (readonly, nonatomic) NSUInteger bananasCollected;
@property (readonly, nonatomic) NSTimeInterval secondsRemaining;
@property (assign, nonatomic) CGPoint scoreLabelLocation;

@end
