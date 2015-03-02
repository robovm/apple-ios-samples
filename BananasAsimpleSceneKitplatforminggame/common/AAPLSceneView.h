/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The view displaying the game scene. Handles keyboard (OS X) and touch (iOS) input for controlling the game, and forwards other click/touch events to the SpriteKit overlay UI.
  
 */

#import <SceneKit/SceneKit.h>

extern NSString *AAPLLeftKey;
extern NSString *AAPLRightKey;
extern NSString *AAPLJumpKey;
extern NSString *AAPLRunKey;

@interface AAPLSceneView : SCNView

@property (strong, nonatomic) NSMutableSet *keysPressed;

@end
