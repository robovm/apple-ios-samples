/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Demonstrates separation behavior. Click (OS X) or touch (iOS) and drag; the white agent follows the mouse/touch location, and the cyan agents attempt to maintain distance from the white agent.
 */

#import "AAPLSeparateScene.h"
#import "AAPLAgentNode.h"

@interface AAPLSeparateScene ()
@property AAPLAgentNode *player;
@property NSArray<AAPLAgentNode *> *friends;
@property GKGoal *separateGoal;
@property GKGoal *seekGoal;
@end

@implementation AAPLSeparateScene

- (NSString *)sceneName {
    return @"SEPARATION";
}

- (void)didMoveToView:(nonnull SKView *)view {
    [super didMoveToView:view];
    
	// The player agent follows the tracking agent.
    self.player = [[AAPLAgentNode alloc] initWithScene:self
                                            radius:AAPLDefaultAgentRadius
                                          position:CGPointMake(CGRectGetMidX(self.frame),
                                                               CGRectGetMidY(self.frame))];
    
    self.player.agent.behavior = [[GKBehavior alloc] init];
    [self.agentSystem addComponent:self.player.agent];
    self.player.agent.maxSpeed *= 1.2;

	// Create the seek goal, but add it to the behavior only in -setSeeking:.
	self.seekGoal = [GKGoal goalToSeekAgent:self.trackingAgent];

	// The friend agents attempt to maintain consistent separation from the player agent.
    self.friends = @[
        [self addFriendAtPoint:CGPointMake(CGRectGetMidX(self.frame) - 150, CGRectGetMidY(self.frame))],
        [self addFriendAtPoint:CGPointMake(CGRectGetMidX(self.frame) + 150, CGRectGetMidY(self.frame))],
    ];
	self.separateGoal = [GKGoal goalToSeparateFromAgents:@[self.player.agent] maxDistance:100 maxAngle:M_PI*2];
	GKBehavior *behavior = [GKBehavior behaviorWithGoal:self.separateGoal weight:100];
    for (AAPLAgentNode *friend in self.friends) {
        friend.agent.behavior = behavior;
    }
}

- (AAPLAgentNode *)addFriendAtPoint:(CGPoint)point {
    AAPLAgentNode *friend = [[AAPLAgentNode alloc] initWithScene:self
                                                          radius:AAPLDefaultAgentRadius
                                                        position:point];
    friend.color = [SKColor cyanColor];
    [self.agentSystem addComponent:friend.agent];
    return friend;
}

- (void)setSeeking:(BOOL)seeking {
    [super setSeeking:seeking];
	// Switch between enabling seek and stop goals so that the agents stop when not seeking.
    for (GKAgent2D *agent in self.agentSystem) {
        if (seeking) {
            [agent.behavior setWeight:1 forGoal:self.seekGoal];
            [agent.behavior setWeight:0 forGoal:self.stopGoal];
        }
        else {
            [agent.behavior setWeight:0 forGoal:self.seekGoal];
            [agent.behavior setWeight:1 forGoal:self.stopGoal];
        }
    }
}

@end
