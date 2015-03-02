/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class simulates the monkeys in the game. It includes game logic for determining each monkey's actions and also manages the monkey's animations.
  
 */

#import "AAPLSkinnedCharacter.h"

@interface AAPLMonkeyCharacter : AAPLSkinnedCharacter

@property (strong, nonatomic) SCNNode *rightHand;
@property (strong, nonatomic) SCNNode *coconut;

- (void)createAnimations;

@end
