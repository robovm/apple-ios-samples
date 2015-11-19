/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Demonstrates flocking behavior -- a combination of separation, alignment, and cohesion goals. Click (OS X) or touch (iOS) and drag and the flock of agents follows the mouse/touch location together.
 */

#import "AAPLFlockScene.h"
#import "AAPLAgentNode.h"

@interface AAPLFlockScene ()
@property NSArray<AAPLAgentNode *> *flock;
@property GKGoal *seekGoal;
@end

@implementation AAPLFlockScene

- (NSString *)sceneName {
    return @"FLOCKING";
}

- (void)didMoveToView:(nonnull SKView *)view {
    [super didMoveToView:view];

	// Create a flock of similar agents.
    NSMutableArray<GKAgent2D *> *agents = [NSMutableArray arrayWithCapacity:20];
    NSInteger agentsPerRow = 4;
    for (NSInteger i = 0; i < agentsPerRow*agentsPerRow; i++) {
		CGFloat x = CGRectGetMidX(self.frame) + i % agentsPerRow * 20;
		CGFloat y = CGRectGetMidY(self.frame) + i / agentsPerRow * 20;
        AAPLAgentNode *boid = [[AAPLAgentNode alloc] initWithScene:self
                                                            radius:10
                                                          position:CGPointMake(x, y)];
        [self.agentSystem addComponent:boid.agent];
        [agents addObject:boid.agent];
        boid.drawsTrail = NO;
    }
    self.flock = [agents copy];
    
    static const float separationRadius =  0.553f * 50;
    static const float separationAngle  = 3 * M_PI / 4.0f;
    static const float separationWeight =  10.0f;
    
    static const float alignmentRadius = 0.83333f * 50;
    static const float alignmentAngle  = M_PI / 4.0f;
    static const float alignmentWeight = 12.66f;
    
    static const float cohesionRadius = 1.0f * 100;
    static const float cohesionAngle  = M_PI / 2.0f;
    static const float cohesionWeight = 8.66f;
    
    // Separation, alignment, and cohesion goals combined cause the flock to move as a group.
    GKBehavior* behavior = [[GKBehavior alloc] init];
    [behavior setWeight:separationWeight forGoal:[GKGoal goalToSeparateFromAgents:agents maxDistance:separationRadius maxAngle:separationAngle]];
    [behavior setWeight:alignmentWeight forGoal:[GKGoal goalToAlignWithAgents:agents maxDistance:alignmentRadius maxAngle:alignmentAngle]];
    [behavior setWeight:cohesionWeight forGoal:[GKGoal goalToCohereWithAgents:agents maxDistance:cohesionRadius maxAngle:cohesionAngle]];
    for (GKAgent2D *agent in agents) {
        agent.behavior = behavior;
    }
	
	// Create the seek goal, but add it to the behavior only in -setSeeking:.
	self.seekGoal = [GKGoal goalToSeekAgent:self.trackingAgent];
}

- (void)setSeeking:(BOOL)seeking {
    [super setSeeking:seeking];
    for (GKAgent2D *agent in self.agentSystem) {
        if (seeking) {
            [agent.behavior setWeight:1 forGoal:self.seekGoal];
        }
        else {
            [agent.behavior setWeight:0 forGoal:self.seekGoal];
        }
    }
}

@end
