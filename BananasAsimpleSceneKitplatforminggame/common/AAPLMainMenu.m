/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A Sprite Kit node that provides the title screen for the game, displayed by the AAPLInGameScene class.
  
 */

#import "AAPLMainMenu.h"
#import "AAPLGameSimulation.h"
#import "AAPLInGameScene.h"

@interface AAPLMainMenu ()

@property (strong, nonatomic) SKSpriteNode *gameLogo;
@property (strong, nonatomic) SKLabelNode *myLabelBackground;

@end

@implementation AAPLMainMenu

- (id)initWithSize:(CGSize)frameSize
{
	self = [super init];

	if (self) {

		self.position = CGPointMake(frameSize.width * 0.5f, frameSize.height * 0.15f);
		self.userInteractionEnabled = YES;

		self.gameLogo = [SKSpriteNode spriteNodeWithImageNamed:@"art.scnassets/level/interface/logo_bananas.png"];

		// resize logo to fit the screen
		CGSize size = self.gameLogo.size;
		CGFloat factor = frameSize.width / size.width;
		size.width *= factor;
		size.height *= factor;
		self.gameLogo.size = size;

		self.gameLogo.anchorPoint = CGPointMake(1, 0);
		self.gameLogo.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
		[self addChild:self.gameLogo];
	}

	return self;
}

- (void)touchUpAtPoint:(CGPoint)location
{
	self.hidden = YES;
	[[AAPLGameSimulation sim] setGameState:AAPLGameStateInGame];
}

@end
