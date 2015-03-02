/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A Sprite Kit scene that provides the 2D overlay UI for the game, and displays different child nodes for title, pause, and post-game screens.
  
 */

#import <SpriteKit/SpriteKit.h>
#import "AAPLGameSimulation.h"

@class SKLabelNode;

@interface AAPLInGameScene : SKScene

+ (SKLabelNode *)labelWithText:(NSString *)text andSize:(CGFloat)textSize;
+ (SKLabelNode *)dropShadowOnLabel:(SKLabelNode *)frontLabel;

- (id)initWithSize:(CGSize)size;
- (void)touchUpAtPoint:(CGPoint)location;


@property (strong, nonatomic) SKLabelNode *scoreLabelValue;
@property (strong, nonatomic) SKLabelNode *scoreLabelValueShadow;
@property (assign, nonatomic) AAPLGameState gameState;
@property (weak, nonatomic) id<AAPLGameUIState> gameStateDelegate;

@end
