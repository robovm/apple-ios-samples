/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A Sprite Kit node that provides the post-game screen for the game, displayed by the AAPLInGameScene class.
  
 */

#import "AAPLPostGameMenu.h"
#import "AAPLGameSimulation.h"
#import "AAPLInGameScene.h"

@interface AAPLPostGameMenu ()

@property (strong, nonatomic) SKLabelNode *myLabel;
@property (strong, nonatomic) SKLabelNode *bananaText;
@property (strong, nonatomic) SKLabelNode *bananaScore;
@property (strong, nonatomic) SKLabelNode *coinText;
@property (strong, nonatomic) SKLabelNode *coinScore;
@property (strong, nonatomic) SKLabelNode *totalText;
@property (strong, nonatomic) SKLabelNode *totalScore;

@end

@implementation AAPLPostGameMenu

- (id)initWithSize:(CGSize)frameSize andDelegate:(id<AAPLGameUIState>)gameStateDelegate
{
	self = [super init];

	if (self) {

		self.gameStateDelegate = gameStateDelegate;

        CGFloat menuHeight = frameSize.height * 0.8;
		SKSpriteNode *background = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor]
																size:CGSizeMake(frameSize.width * 0.8, menuHeight)];
		background.zPosition = -1;
		background.alpha = 0.5f;
		background.position = CGPointMake(0, -0.2 * menuHeight);
		[self addChild:background];

		self.myLabel = [AAPLInGameScene labelWithText:@"Final Score" andSize:65];
		self.myLabel.position = CGPointMake(CGRectGetMidX(self.frame),
											CGRectGetMidY(self.frame));

		self.position = CGPointMake(frameSize.width * 0.5f, frameSize.height * 0.5f);
		self.userInteractionEnabled = YES;
		self.myLabel.userInteractionEnabled = YES;
		[self addChild:self.myLabel];
		[AAPLInGameScene dropShadowOnLabel:self.myLabel];

		CGPoint      bananaLocation = CGPointMake(frameSize.width * -0.4f, CGRectGetMidY(self.frame) * -0.4f);
		CGPoint	       coinLocation = CGPointMake(frameSize.width * -0.4f, CGRectGetMidY(self.frame) * -0.6f);
		CGPoint       totalLocation = CGPointMake(frameSize.width * -0.4f, CGRectGetMidY(self.frame) * -0.8f);
		CGPoint bananaScoreLocation = CGPointMake(frameSize.width * +0.4f, CGRectGetMidY(self.frame) * -0.4f);
		CGPoint   coinScoreLocation = CGPointMake(frameSize.width * +0.4f, CGRectGetMidY(self.frame) * -0.6f);
		CGPoint  totalScoreLocation = CGPointMake(frameSize.width * +0.4f, CGRectGetMidY(self.frame) * -0.8f);

		self.bananaText = [self.myLabel copy];
		self.bananaText.text = @"Bananas";
        self.bananaText.fontSize = 0.1 * menuHeight;
		[self.bananaText setScale:0.8f];
		bananaLocation.x += (CGRectGetWidth([self.bananaText calculateAccumulatedFrame]) * 0.5f) + frameSize.width * 0.1;
		self.bananaText.position = CGPointMake(bananaLocation.x,
											   -2000);
		[self addChild:self.bananaText];
		[AAPLInGameScene dropShadowOnLabel:self.bananaText];

		self.bananaScore = [self.bananaText copy];
		self.bananaScore.text = @"000";
		bananaScoreLocation.x -= ((CGRectGetWidth([self.bananaScore calculateAccumulatedFrame]) * 0.5f) + frameSize.width * 0.1);
		self.bananaScore.position = CGPointMake(bananaScoreLocation.x,
												-2000);
		[self addChild:self.bananaScore];


		self.coinText = [self.bananaText copy];
		self.coinText.text = @"Large Bananas";
		coinLocation.x += (CGRectGetWidth([self.coinText calculateAccumulatedFrame]) * 0.5f) + frameSize.width * 0.1;
		self.coinText.position = CGPointMake(coinLocation.x,
											 -2000);
		[self addChild:self.coinText];
		[AAPLInGameScene dropShadowOnLabel:self.coinText];


		self.coinScore = [self.coinText copy];
		self.coinScore.text = @"000";
		coinScoreLocation.x -= ((CGRectGetWidth([self.coinScore calculateAccumulatedFrame]) * 0.5f) + frameSize.width * 0.1);
		self.coinScore.position = CGPointMake(coinScoreLocation.x,
											  -2000);
		[self addChild:self.coinScore];

		self.totalText = [self.bananaText copy];
		self.totalText.text = @"Total";
		totalLocation.x += (CGRectGetWidth([self.totalText calculateAccumulatedFrame]) * 0.5f) + frameSize.width * 0.1;
		self.totalText.position = CGPointMake(totalLocation.x,
											  -2000);
		[self addChild:self.totalText];
		[AAPLInGameScene dropShadowOnLabel:self.totalText];


		self.totalScore = [self.totalText copy];
		self.totalScore.text = @"000";
		totalScoreLocation.x -= ((CGRectGetWidth([self.totalScore calculateAccumulatedFrame]) * 0.5f) + frameSize.width * 0.1);
		self.totalScore.position = CGPointMake(totalScoreLocation.x,
											   -2000);
		[self addChild:self.totalScore];

		SKAction *flyup = [SKAction moveTo:CGPointMake(frameSize.width * 0.5f, frameSize.height - 100) duration:0.25f];
		flyup.timingMode = SKActionTimingEaseInEaseOut;

		SKAction *flyupBananas = [SKAction moveTo:bananaLocation duration:0.25f];
		SKAction *flyupBananasScore = [SKAction moveTo:bananaScoreLocation duration:0.25f];
		flyupBananas.timingMode = SKActionTimingEaseInEaseOut;
		flyupBananasScore.timingMode = SKActionTimingEaseInEaseOut;

		SKAction *flyupCoins = [SKAction moveTo:coinLocation duration:0.25f];
		SKAction *flyupCoinsScore = [SKAction moveTo:coinScoreLocation duration:0.25f];
		flyupCoins.timingMode = SKActionTimingEaseInEaseOut;
		flyupCoinsScore.timingMode = SKActionTimingEaseInEaseOut;

		SKAction *flyupTotal = [SKAction moveTo:totalLocation duration:0.25f];
		SKAction *flyupTotalScore = [SKAction moveTo:totalScoreLocation duration:0.25f];
		flyupTotal.timingMode = SKActionTimingEaseInEaseOut;
		flyupTotalScore.timingMode = SKActionTimingEaseInEaseOut;

		NSUInteger bananasCollected = self.gameStateDelegate.bananasCollected;
		NSUInteger coinsCollected = self.gameStateDelegate.coinsCollected;
		NSUInteger totalCollected = bananasCollected + (coinsCollected * 100);

		SKAction *countUpBananas = [SKAction customActionWithDuration:(CGFloat)bananasCollected / 100.0f actionBlock:^(SKNode *node, CGFloat elapsedTime) {
			if (bananasCollected > 0) {
				SKLabelNode *label = (SKLabelNode *)node;
				NSUInteger total = (NSUInteger)((elapsedTime / ((CGFloat)bananasCollected / 100.0f)) * (CGFloat)bananasCollected);
				label.text = [NSString stringWithFormat:@"%lu", (unsigned long)total];
				if (total % 10 == 0) {
					[[AAPLGameSimulation sim] playSound:@"deposit.caf"];
				}

			}

		}];
		SKAction *countUpCoins = [SKAction customActionWithDuration:(CGFloat)coinsCollected / 100.0f actionBlock:^(SKNode *node, CGFloat elapsedTime) {
			if (coinsCollected > 0) {
				SKLabelNode *label = (SKLabelNode *)node;
				NSUInteger total = (NSUInteger)((elapsedTime / ((CGFloat)coinsCollected / 100.0f)) * (CGFloat)coinsCollected);
				label.text = [NSString stringWithFormat:@"%lu", (unsigned long)total];
				if (total % 10 == 0) {
					[[AAPLGameSimulation sim] playSound:@"deposit.caf"];
				}
			}
		}];
		SKAction *countUpTotal = [SKAction customActionWithDuration:(CGFloat)(totalCollected / 5) / 100.0f actionBlock:^(SKNode *node, CGFloat elapsedTime) {
			if (totalCollected > 0) {
				SKLabelNode *label = (SKLabelNode *)node;
				NSUInteger total = (NSUInteger)((elapsedTime / ((CGFloat)(totalCollected / 5) / 100.0f)) * (CGFloat)totalCollected);
				label.text = [NSString stringWithFormat:@"%lu", (unsigned long)total];
				if (total % 25 == 0) {
					[[AAPLGameSimulation sim] playSound:@"deposit.caf"];
				}
			}
		}];

		// Play actions in sequence: Fly up, count up. repeat with the next line.
		[self runAction:flyup completion:^{
			//-- fly up the bananas collected.
			[self.bananaText runAction:flyupBananas];
			[self.bananaScore runAction:flyupBananasScore completion:^{
				//-- count!
				[self.bananaScore runAction:countUpBananas completion:^{
					self.bananaScore.text = [NSString stringWithFormat:@"%lu", (unsigned long)bananasCollected];
					[self.coinText runAction:flyupCoins];
					[self.coinScore runAction:flyupCoinsScore completion:^{
						//-- count
						[self.coinScore runAction:countUpCoins completion:^{
							self.coinScore.text = [NSString stringWithFormat:@"%lu", (unsigned long)coinsCollected];
							[self.totalText runAction:flyupTotal];
							[self.totalScore runAction:flyupTotalScore completion:^{
								[self.totalScore runAction:countUpTotal completion:^{
									self.totalScore.text = [NSString stringWithFormat:@"%lu", (unsigned long)totalCollected];
								}];
							}];
						}];
					}];
				}];
			}];
		}];
	}

	return self;
}

- (void)touchUpAtPoint:(CGPoint)location
{
	SKNode *touchedNode = [self.scene nodeAtPoint:location];

	if (touchedNode != nil) {
		self.hidden = YES;
		[[AAPLGameSimulation sim] setGameState:AAPLGameStateInGame];
	}
}

@end
