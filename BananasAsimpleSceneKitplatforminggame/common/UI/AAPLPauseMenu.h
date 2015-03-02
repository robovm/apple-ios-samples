/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A Sprite Kit node that provides the pause screen for the game, displayed by the AAPLInGameScene class.
  
 */

#import <SpriteKit/SpriteKit.h>

@interface AAPLPauseMenu : SKNode

- (id)initWithSize:(CGSize)frameSize;
- (void)touchUpAtPoint:(CGPoint)location;

@end
