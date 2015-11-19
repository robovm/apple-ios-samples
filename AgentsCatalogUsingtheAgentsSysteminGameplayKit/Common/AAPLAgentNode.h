/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A SpriteKit node whose position is managed by a GameplayKit agent. Also provides the standard appearance for agents in this demo.
 */

@import SpriteKit;
@import GameplayKit;

@interface AAPLAgentNode : SKNode <GKAgentDelegate>

- (instancetype)initWithScene:(SKScene *)scene radius:(float)radius position:(CGPoint)position;

@property (readonly) GKAgent2D *agent;
@property (nonatomic, readwrite) SKColor *color;
@property (nonatomic) BOOL drawsTrail;

@end
