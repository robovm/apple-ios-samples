/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class manages the coconuts thrown by monkeys in the game. It configures and vends instances for use by the AAPLMonkeyCharacter class, which uses them both for simple animation (the monkey retrieving a coconut from the tree) and physics simulation (the monkey throwing a coconut at the player).
  
 */

#import <SceneKit/SceneKit.h>

#import <GLKit/GLKMath.h>

// AAPLCoconut
//
// Coconut object that hold simulation information
//
@interface AAPLCoconut : SCNNode

+ (SCNPhysicsShape *)coconutPhysicsShape;
+ (SCNNode *)coconutProtoObject;
+ (AAPLCoconut *)coconutThrowProtoObject;

@end
