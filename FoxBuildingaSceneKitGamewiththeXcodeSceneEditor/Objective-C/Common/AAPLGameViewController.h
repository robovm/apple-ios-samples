/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class manages most of the game logic.
*/

@import SceneKit;

#import "AAPLGameView.h"

// Collision bit masks
typedef NS_OPTIONS(NSUInteger, AAPLBitmask) {
    AAPLBitmaskCollision        = 1UL << 2,
    AAPLBitmaskCollectable      = 1UL << 3,
    AAPLBitmaskEnemy            = 1UL << 4,
    AAPLBitmaskSuperCollectable = 1UL << 5,
    AAPLBitmaskWater            = 1UL << 6
};

#if TARGET_OS_IOS || TARGET_OS_TV
typedef UIViewController AAPLViewController;
#else
typedef NSViewController AAPLViewController;
#endif

@interface AAPLGameViewController : AAPLViewController <SCNSceneRendererDelegate, SCNPhysicsContactDelegate>

@property (nonatomic, readonly) AAPLGameView *gameView;

@end
