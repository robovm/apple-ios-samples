/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A Sprite Kit node that provides the post-game screen for the game, displayed by the AAPLInGameScene class.
  
 */

#import <SpriteKit/SpriteKit.h>
#import "AAPLGameSimulation.h"

@interface AAPLPostGameMenu : SKNode

- (id)initWithSize:(CGSize)frameSize andDelegate:(id<AAPLGameUIState>)gameStateDelegate;
- (void)touchUpAtPoint:(CGPoint)location;

@property (weak, nonatomic) id<AAPLGameUIState> gameStateDelegate;

@end
