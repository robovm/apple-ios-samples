/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Non-interactive demonstration of wander behavior.
 */

#import "AAPLWanderScene.h"
#import "AAPLAgentNode.h"

@implementation AAPLWanderScene

- (NSString *)sceneName {
    return @"WANDERING";
}

- (void)didMoveToView:(nonnull SKView *)view {
    [super didMoveToView:view];
	
	// The wanderer agent simply moves aimlessly through the scene.
    AAPLAgentNode *wanderer = [[AAPLAgentNode alloc] initWithScene:self
                                                          radius:AAPLDefaultAgentRadius
                                                        position:CGPointMake(CGRectGetMidX(self.frame),
                                                                             CGRectGetMidY(self.frame))];
	wanderer.color = [SKColor cyanColor];
    wanderer.agent.behavior = [GKBehavior behaviorWithGoal:[GKGoal goalToWander:10] weight:100];
    [self.agentSystem addComponent:wanderer.agent];
}

@end
