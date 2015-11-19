/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class manages most of the game logic.
*/

@import SceneKit;

#import "AAPLGameView.h"
#import "AAPLCharacter.h"

// Collision bit masks
typedef NS_OPTIONS(NSUInteger, AAPLBitmask) {
    AAPLBitmaskCollision        = 1UL << 2,
    AAPLBitmaskCollectable      = 1UL << 3,
    AAPLBitmaskEnemy            = 1UL << 4,
    AAPLBitmaskSuperCollectable = 1UL << 5,
    AAPLBitmaskWater            = 1UL << 6
};

// Speed parameter
#define CharacterSpeedFactor (2/1.3)

#if !TARGET_OS_IPHONE
@interface AAPLGameViewController : NSViewController <SCNSceneRendererDelegate, SCNPhysicsContactDelegate>
#else
@interface AAPLGameViewController : UIViewController <SCNSceneRendererDelegate, SCNPhysicsContactDelegate>
#endif

@property (weak) IBOutlet AAPLGameView *gameView;
@property (readonly) AAPLCharacter *character;

- (void)panCamera:(CGSize)dir;

@end
