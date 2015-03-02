/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class manages the global state of the game. It handles SCNSceneRendererDelegate methods for participating in the update/render loop, polls for input (directly for game controllers and via AAPLSceneView for key/touch input), and delegates game logic to the AAPLGameLevel object.
  
 */

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

@protocol AAPLGameUIState <NSObject>

@required

@property (readonly, nonatomic) NSUInteger score;
@property (readonly, nonatomic) NSUInteger coinsCollected;
@property (readonly, nonatomic) NSUInteger bananasCollected;
@property (readonly, nonatomic) NSTimeInterval secondsRemaining;
@property (assign, nonatomic) CGPoint scoreLabelLocation;

@end


@class AAPLGameLevel;
@class AAPLInGameScene;
@class GCController;

typedef NS_ENUM(NSInteger, AAPLGameState) {
	AAPLGameStatePreGame = 0,
	AAPLGameStateInGame,
    AAPLGameStatePaused,
    AAPLGameStatePostGame,
	AAPLGameStateCount
};

typedef NS_ENUM(NSUInteger, GameCollisionCategory) {
	GameCollisionCategoryGround         = 1 << 2,
    GameCollisionCategoryBanana         = 1 << 3,
    GameCollisionCategoryPlayer         = 1 << 4,
    GameCollisionCategoryLava           = 1 << 5,
    GameCollisionCategoryCoin           = 1 << 6,
    GameCollisionCategoryCoconut        = 1 << 7,
    GameCollisionCategoryNoCollide      = 1 << 14
};

typedef NS_ENUM(NSUInteger, NodeCategory) {
	NodeCategoryTorch          = 1 << 2,
    NodeCategoryLava           = 1 << 3,
    NodeCategoryLava2          = 1 << 4,
};

@interface AAPLGameSimulation : SCNScene <SCNSceneRendererDelegate, SCNPhysicsContactDelegate>


+ (AAPLGameSimulation *)sim;

@property (strong, nonatomic) AAPLGameLevel *gameLevel;
@property (strong, nonatomic) AAPLInGameScene *gameUIScene;
@property (assign, nonatomic) AAPLGameState gameState;
@property (strong, nonatomic) GCController *controller;


- (void)controllerDidConnect:(NSNotification *)note;
- (void)controllerDidDisconnect:(NSNotification *)note;

- (void)playSound:(NSString *)soundFileName;
- (void)playMusic:(NSString *)soundFileName;

#pragma mark - Resource Loading convenience
+ (NSString *)pathForArtResource:(NSString *)resourceName;
+ (SCNNode *)loadNodeWithName:(NSString *)name fromSceneNamed:(NSString *)path;
+ (SCNParticleSystem *)loadParticleSystemWithName:(NSString *)name;

@end
