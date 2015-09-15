/*
     File: APAMultiplayerLayeredCharacterScene.h
 Abstract: n/a
  Version: 1.2
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */


/* The layers in a scene. */
typedef enum : uint8_t {
	APAWorldLayerGround = 0,
	APAWorldLayerBelowCharacter,
	APAWorldLayerCharacter,
	APAWorldLayerAboveCharacter,
	APAWorldLayerTop,
	kWorldLayerCount
} APAWorldLayer;

/* Player states for the four players in the HUD. */
typedef enum : uint8_t {
    APAHUDStateLocal,
    APAHUDStateConnecting,
    APAHUDStateDisconnected,
    APAHUDStateConnected
} APAHUDState;


#define kMinTimeInterval (1.0f / 60.0f)
#define kNumPlayers 4
#define kMinHeroToEdgeDistance 256                  // minimum distance between hero and edge of camera before moving camera

/* Completion handler for callback after loading assets asynchronously. */
typedef void (^APAAssetLoadCompletionHandler)(void);

/* Forward declarations. */
@class APAHeroCharacter, APAPlayer, APACharacter;



@interface APAMultiplayerLayeredCharacterScene : SKScene

@property (nonatomic, readonly) NSArray *players;               // array of player objects or NSNull for no player
@property (nonatomic, readonly) APAPlayer *defaultPlayer;       // player '1' controlled by keyboard/touch
@property (nonatomic, readonly) SKNode *world;                  // root node to which all game renderables are attached
@property (nonatomic) CGPoint defaultSpawnPoint;                // the point at which heroes are spawned
@property (nonatomic) BOOL worldMovedForUpdate;                 // indicates the world moved before or during the current update

@property (nonatomic, readonly) NSArray *heroes;                // all heroes in the game

/* Start loading all the shared assets for the scene in the background. This method calls +loadSceneAssets 
   on a background queue, then calls the callback handler on the main thread. */
+ (void)loadSceneAssetsWithCompletionHandler:(APAAssetLoadCompletionHandler)callback;

/* Overridden by subclasses to load scene-specific assets. */ 
+ (void)loadSceneAssets;

/* Overridden by subclasses to release assets used only by this scene. */
+ (void)releaseSceneAssets;

/* Overridden by subclasses to provide an emitter used to indicate when a new hero is spawned. */
- (SKEmitterNode *)sharedSpawnEmitter;

/* Overridden by subclasses to update the scene - called once per frame. */
- (void)updateWithTimeSinceLastUpdate:(NSTimeInterval)timeSinceLast;

/* This method should be called when the level is loaded to set up currently-connected game controllers,
   and register for the relevant notifications to deal with new connections/disconnections. */
- (void)configureGameControllers;

/* All sprites in the scene should be added through this method to ensure they are placed in the correct world layer. */
- (void)addNode:(SKNode *)node atWorldLayer:(APAWorldLayer)layer;

/* Heroes and players. */
- (APAHeroCharacter *)addHeroForPlayer:(APAPlayer *)player;
- (void)heroWasKilled:(APAHeroCharacter *)hero;

/* Utility methods for coordinates. */
- (void)centerWorldOnCharacter:(APACharacter *)character;
- (void)centerWorldOnPosition:(CGPoint)position;
- (float)distanceToWall:(CGPoint)pos0 from:(CGPoint)pos1;
- (BOOL)canSee:(CGPoint)pos0 from:(CGPoint)pos1;

/* Determines the relevant player from the given projectile, and adds to that player's score. */
- (void)addToScore:(uint32_t)amount afterEnemyKillWithProjectile:(SKNode *)projectile;

@end
