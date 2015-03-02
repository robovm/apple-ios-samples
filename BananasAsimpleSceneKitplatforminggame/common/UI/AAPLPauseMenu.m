/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A Sprite Kit node that provides the pause screen for the game, displayed by the AAPLInGameScene class.
  
 */

#import "AAPLPauseMenu.h"
#import "AAPLAppDelegate.h"
#import "AAPLGameSimulation.h"
#import "AAPLInGameScene.h"

@interface AAPLPauseMenu ()

@property (strong, nonatomic) SKLabelNode *myLabel;

@end

@implementation AAPLPauseMenu

- (id)initWithSize:(CGSize)frameSize
{
	self = [super init];

	if (self) {

		self.myLabel = [AAPLInGameScene labelWithText:@"Resume" andSize:65];
		self.myLabel.position = CGPointMake(CGRectGetMidX(self.frame),
											CGRectGetMidY(self.frame));

		self.position = CGPointMake(frameSize.width * 0.5f, frameSize.height * 0.5f);

		[self addChild:self.myLabel];

		[AAPLInGameScene dropShadowOnLabel:self.myLabel];
	}

	return self;
}

- (void)touchUpAtPoint:(CGPoint)location
{
	SKNode *touchedNode = [self.scene nodeAtPoint:location];

	if (touchedNode == self.myLabel) {
		self.hidden = YES;
		[[AAPLGameSimulation sim] setGameState:AAPLGameStateInGame];
	}
}

@end

