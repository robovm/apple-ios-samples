/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Common superclass for the scenes in this demo. Manages an update loop for agents, and provides a mouse/touch tracking agent for use in some of the demo scenes.
 */

@import SpriteKit;
@import GameplayKit;

typedef NS_ENUM(NSInteger, AAPLSceneType) {
    AAPLSceneTypeSeek = 0,
    AAPLSceneTypeWander,
    AAPLSceneTypeFlee,
    AAPLSceneTypeAvoid,
    AAPLSceneTypeSeparate,
    AAPLSceneTypeAlign,
    AAPLSceneTypeFlock,
    AAPLSceneTypePath,

    AAPLSceneTypesCount
};

const static float AAPLDefaultAgentRadius = 40.0f;

@interface AAPLGameScene : SKScene

+ (AAPLGameScene *)sceneWithType:(AAPLSceneType)sceneType size:(CGSize)size;

@property (nonatomic, readonly) NSString *sceneName;

// A component system to manage per-frame updates for all agents.
@property (nonatomic, readonly) GKComponentSystem *agentSystem;

// An agent whose position tracks that of mouseDragged (OS X) or touchesMoved (iOS) events.
// This agent has no display representation, but can be used to make other agents follow the mouse/touch.
@property (nonatomic, readonly) GKAgent2D *trackingAgent;

// YES when the mouse is dragging (OS X) or a touch is moving
@property (nonatomic, getter=isSeeking) BOOL seeking;

@property (nonatomic, readonly) GKGoal *stopGoal;

@end
