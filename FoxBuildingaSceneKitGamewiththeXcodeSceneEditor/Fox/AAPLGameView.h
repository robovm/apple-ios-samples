/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view displaying the game scene. Handles keyboard (OS X) and touch (iOS) input for controlling the game.
*/

@import SceneKit;

@class AAPLGameViewController;

@interface AAPLGameView : SCNView

@property(weak) IBOutlet AAPLGameViewController *controller;
@property(readonly) SCNVector3 direction;
@property NSInteger collectedFlowers;
@property NSInteger collectedPearls;

- (void)setup;
- (void)didCollectAPearl;
- (BOOL)didCollectAFlower;

@end
