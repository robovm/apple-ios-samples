/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Demonstrates flee behavior. Click (OS X) or touch (iOS) and drag; the white agent follows the mouse/touch location, and the red agent avoids the white agent.
 */

#import "AAPLFleeScene.h"
#import "AAPLAgentNode.h"

@interface AAPLFleeScene ()
@property AAPLAgentNode *player;
@property AAPLAgentNode *enemy;
@property GKGoal *seekGoal;
@property GKGoal *fleeGoal;
@property (nonatomic) BOOL fleeing;
@end

@implementation AAPLFleeScene

- (NSString *)sceneName {
    return @"FLEEING";
}

- (void)didMoveToView:(nonnull SKView *)view {
    [super didMoveToView:view];
    
	// The player agent follows the tracking agent.
    self.player = [[AAPLAgentNode alloc] initWithScene:self
                                                radius:AAPLDefaultAgentRadius
                                              position:CGPointMake(CGRectGetMidX(self.frame) - 150,
                                                                   CGRectGetMidY(self.frame))];
    self.player.agent.behavior = [[GKBehavior alloc] init];
    [self.agentSystem addComponent:self.player.agent];
    
	// The enemy agent flees from the player agent.
    self.enemy = [[AAPLAgentNode alloc] initWithScene:self
                                               radius:AAPLDefaultAgentRadius
                                             position:CGPointMake(CGRectGetMidX(self.frame) + 150,
                                                                  CGRectGetMidY(self.frame))];
    self.enemy.color = [SKColor redColor];
    self.enemy.agent.behavior = [[GKBehavior alloc] init];
    [self.agentSystem addComponent:self.enemy.agent];

	// Create seek and flee goals, but add them to the agents' behaviors only in -setSeeking: / -setFleeing:.
    self.seekGoal = [GKGoal goalToSeekAgent:self.trackingAgent];
    self.fleeGoal = [GKGoal goalToFleeAgent:self.player.agent];
}

- (void)setSeeking:(BOOL)seeking {
    [super setSeeking:seeking];
	// Switch between enabling seek and stop goals so that the agent stops when not seeking.
    if (seeking) {
        [self.player.agent.behavior setWeight:1 forGoal:self.seekGoal];
        [self.player.agent.behavior setWeight:0 forGoal:self.stopGoal];
    }
    else {
        [self.player.agent.behavior setWeight:0 forGoal:self.seekGoal];
        [self.player.agent.behavior setWeight:1 forGoal:self.stopGoal];
    }
}

- (void)setFleeing:(BOOL)fleeing {
    _fleeing = fleeing;
	// Switch between enabling flee and stop goals so that the agent stops when not fleeing.
    if (fleeing) {
        [self.enemy.agent.behavior setWeight:1 forGoal:self.fleeGoal];
        [self.enemy.agent.behavior setWeight:0 forGoal:self.stopGoal];
    }
    else {
        [self.enemy.agent.behavior setWeight:0 forGoal:self.fleeGoal];
        [self.enemy.agent.behavior setWeight:1 forGoal:self.stopGoal];
    }
}

- (void)update:(NSTimeInterval)currentTime {
    float distance = vector_distance(self.player.agent.position, self.enemy.agent.position);
    
	const static float maxDistance = 200.0;
    self.fleeing = distance < maxDistance;
    
    [super update:currentTime];
}

@end
