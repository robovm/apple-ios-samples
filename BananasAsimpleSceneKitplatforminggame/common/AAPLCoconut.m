/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class manages the coconuts thrown by monkeys in the game. It configures and vends instances for use by the AAPLMonkeyCharacter class, which uses them both for simple animation (the monkey retrieving a coconut from the tree) and physics simulation (the monkey throwing a coconut at the player).
  
 */

#import "AAPLCoconut.h"
#import "AAPLGameLevel.h"

@implementation AAPLCoconut

+ (SCNPhysicsShape *)coconutPhysicsShape
{
	static SCNPhysicsShape *s_coconutPhysicShape = nil;

	if (s_coconutPhysicShape == nil) {
		SCNSphere *sphere = [SCNSphere sphereWithRadius:25];
		s_coconutPhysicShape = [SCNPhysicsShape shapeWithGeometry:sphere options:nil];
	}

	return s_coconutPhysicShape;
}

+ (SCNNode *)coconutProtoObject
{
	static SCNNode *s_coconutProtoObject = nil;

	if (s_coconutProtoObject == nil) {
		NSString *coconutDaeName = [AAPLGameSimulation pathForArtResource:@"characters/monkey/coconut.dae"];
		s_coconutProtoObject = [AAPLGameSimulation loadNodeWithName:@"Coconut"
													fromSceneNamed:coconutDaeName];
	}

	// create and return a clone of our proto object.
	SCNNode *coconut = [s_coconutProtoObject clone];
	coconut.name = @"coconut";

	return coconut;
}

+ (AAPLCoconut *)coconutThrowProtoObject
{
	static AAPLCoconut *s_coconutThrowProtoObject = nil;

	if (s_coconutThrowProtoObject == nil) {
		NSString *coconutDaeName = [AAPLGameSimulation pathForArtResource:@"characters/monkey/coconut_no_translation.dae"];
		SCNNode *node = [AAPLGameSimulation loadNodeWithName:@"coconut"
											 fromSceneNamed:coconutDaeName];
		s_coconutThrowProtoObject = [[AAPLCoconut alloc] init];
		[s_coconutThrowProtoObject addChildNode:node];

		[s_coconutThrowProtoObject enumerateChildNodesUsingBlock:^(SCNNode *child, BOOL *stop) {
			for (SCNMaterial *m in child.geometry.materials)
				m.lightingModelName = SCNLightingModelConstant;
		}];
	}

	// create and return a clone of our proto object.
	AAPLCoconut *coconut = (AAPLCoconut *)[s_coconutThrowProtoObject clone];
	coconut.name = @"coconut_throw";
	return coconut;
}

@end
