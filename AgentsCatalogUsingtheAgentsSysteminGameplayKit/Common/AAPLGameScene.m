/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Common superclass for the scenes in this demo. Manages an update loop for agents, and provides a mouse/touch tracking agent for use in some of the demo scenes.
 */

#import "AAPLGameScene.h"

#import "AAPLSeekScene.h"
#import "AAPLWanderScene.h"
#import "AAPLFleeScene.h"
#import "AAPLAvoidScene.h"
#import "AAPLSeparateScene.h"
#import "AAPLAlignScene.h"
#import "AAPLFlockScene.h"
#import "AAPLPathScene.h"

@interface AAPLGameScene ()
@property (nonatomic, readwrite) GKComponentSystem *agentSystem;
@property (nonatomic, readwrite) GKAgent2D *trackingAgent;
@property (nonatomic, readwrite) GKGoal *stopGoal;
@property NSTimeInterval lastUpdateTime;
@end

@implementation AAPLGameScene

+ (AAPLGameScene *)sceneWithType:(AAPLSceneType)sceneType size:(CGSize)size {
	Class sceneClass;
	
	switch (sceneType) {
		case AAPLSceneTypeSeek:
			sceneClass = [AAPLSeekScene class];
			break;
			
		case AAPLSceneTypeWander:
			sceneClass = [AAPLWanderScene class];
			break;
			
		case AAPLSceneTypeFlee:
			sceneClass = [AAPLFleeScene class];
			break;
			
		case AAPLSceneTypeAvoid:
			sceneClass = [AAPLAvoidScene class];
			break;
			
		case AAPLSceneTypeSeparate:
			sceneClass = [AAPLSeparateScene class];
			break;
			
		case AAPLSceneTypeAlign:
			sceneClass = [AAPLAlignScene class];
			break;
			
		case AAPLSceneTypeFlock:
			sceneClass = [AAPLFlockScene class];
			break;
			
		case AAPLSceneTypePath:
			sceneClass = [AAPLPathScene class];
			break;
			
		default:
			sceneClass = [AAPLGameScene class];
			break;
	}
	
	return [[sceneClass alloc] initWithSize:CGSizeMake(800, 600)];
}

- (NSString *)sceneName {
    return @"Default";
}

- (GKGoal *)stopGoal {
    if (_stopGoal == nil) {
        _stopGoal = [GKGoal goalToReachTargetSpeed:0];
    }
    return _stopGoal;
}

- (void)didMoveToView:(SKView *)view {
#if !TARGET_OS_IPHONE
    NSString *fontName = [NSFont systemFontOfSize:65].fontName;
    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:fontName];
    label.text = self.sceneName;
    label.fontSize = 65;
    label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    label.verticalAlignmentMode = SKLabelVerticalAlignmentModeTop;
    label.position = CGPointMake(CGRectGetMinX(self.frame) + 10,
                                 CGRectGetMaxY(self.frame) - 46);
    [self addChild:label];
#endif
    
    self.agentSystem = [[GKComponentSystem alloc] initWithComponentClass:[GKAgent2D class]];
    self.trackingAgent = [[GKAgent2D alloc] init];
    self.trackingAgent.position = (vector_float2){CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)};
}

- (void)update:(NSTimeInterval)currentTime {
    // Calculate delta since last update and pass along to the agent system.
    if (_lastUpdateTime == 0) {
        _lastUpdateTime = currentTime;
    }
    
    float delta = currentTime - _lastUpdateTime;
    _lastUpdateTime = currentTime;
    [self.agentSystem updateWithDeltaTime:delta];
}

#pragma mark - Input Handling

#if TARGET_OS_IPHONE
- (void)touchesBegan:(nonnull NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    self.seeking = YES;
}

- (void)touchesCancelled:(nullable NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    self.seeking = NO;
}

- (void)touchesEnded:(nonnull NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    self.seeking = NO;
}

- (void)touchesMoved:(nonnull NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint position = [touch locationInNode:self];
    self.trackingAgent.position = (vector_float2){position.x, position.y};
}

#else
- (void)mouseDown:(nonnull NSEvent *)theEvent {
    self.seeking = YES;
}

- (void)mouseUp:(nonnull NSEvent *)theEvent {
    self.seeking = NO;
}

- (void)mouseDragged:(nonnull NSEvent *)theEvent {
    CGPoint position = [theEvent locationInNode:self];
    self.trackingAgent.position = (vector_float2){position.x, position.y};
}
#endif

@end
