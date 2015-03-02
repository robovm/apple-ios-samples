/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A Sprite Kit scene that provides the 2D overlay UI for the game, and displays different child nodes for title, pause, and post-game screens.
  
 */

#import "AAPLInGameScene.h"
#import "AAPLMainMenu.h"
#import "AAPLPauseMenu.h"
#import "AAPLPostGameMenu.h"

@interface AAPLInGameScene ()

@property (strong, nonatomic) SKLabelNode *timeLabelValue;
@property (strong, nonatomic) SKLabelNode *timeLabelValueShadow;
@property (strong, nonatomic) SKLabelNode *scoreLabel;
@property (strong, nonatomic) SKLabelNode *scoreLabelShadow;
@property (strong, nonatomic) SKLabelNode *timeLabel;
@property (strong, nonatomic) SKLabelNode *timeLabelShadow;
@property (strong, nonatomic) AAPLMainMenu *menuNode;
@property (strong, nonatomic) AAPLPauseMenu *pauseNode;
@property (strong, nonatomic) AAPLPostGameMenu *postGameNode;

@end

@implementation AAPLInGameScene

- (id)initWithSize:(CGSize)size
{
	if (self = [super initWithSize:size]) {

		self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1];

		self.timeLabel = [AAPLInGameScene labelWithText:@"Time" andSize:24];
		[self addChild:self.timeLabel];
		CGRect af = [self.timeLabel calculateAccumulatedFrame];
		self.timeLabel.position = CGPointMake(self.frame.size.width - af.size.width, self.frame.size.height - (af.size.height));

		_timeLabelValue = [AAPLInGameScene labelWithText:@"102:00" andSize:20];
		[self addChild:_timeLabelValue];
		CGRect timeLabelValueSize = [_timeLabelValue calculateAccumulatedFrame];
		_timeLabelValue.position = CGPointMake(self.frame.size.width - af.size.width - timeLabelValueSize.size.width - 10, self.frame.size.height - (af.size.height));

		self.scoreLabel = [AAPLInGameScene labelWithText:@"Score" andSize:24];
		[self addChild:self.scoreLabel];
		af = [self.scoreLabel calculateAccumulatedFrame];
		self.scoreLabel.position = CGPointMake(af.size.width * 0.5f, self.frame.size.height - (af.size.height));

		_scoreLabelValue = [AAPLInGameScene labelWithText:@"0" andSize:24];
		[self addChild:_scoreLabelValue];
		_scoreLabelValue.position = CGPointMake(af.size.width * 0.75f + (timeLabelValueSize.size.width) , self.frame.size.height - (af.size.height));

		// Add drop shadows to each label above.
		self.timeLabelValueShadow = [AAPLInGameScene dropShadowOnLabel:_timeLabelValue];
		self.scoreLabelShadow = [AAPLInGameScene dropShadowOnLabel:self.scoreLabel];
		self.timeLabelShadow = [AAPLInGameScene dropShadowOnLabel:self.timeLabel];
		self.scoreLabelValueShadow = [AAPLInGameScene dropShadowOnLabel:_scoreLabelValue];
	}

	return self;
}

- (void)setGameState:(AAPLGameState)gameState
{

	[self.menuNode removeFromParent];
	[self.pauseNode removeFromParent];
	[self.postGameNode removeFromParent];

	if (gameState == AAPLGameStatePreGame) {
		self.menuNode = [[AAPLMainMenu alloc] initWithSize:self.frame.size];
		[self addChild:self.menuNode];
	} else if (gameState == AAPLGameStateInGame) {
		[self hideInGameUI:NO];
	} else if (gameState == AAPLGameStatePaused) {
		self.pauseNode = [[AAPLPauseMenu alloc] initWithSize:self.frame.size];
		[self addChild:self.pauseNode];
	} else if (gameState == AAPLGameStatePostGame) {
		self.postGameNode = [[AAPLPostGameMenu alloc] initWithSize:self.frame.size andDelegate:self.gameStateDelegate];
		[self addChild:self.postGameNode];
		[self hideInGameUI:YES];
	}

	_gameState = gameState;
}

- (void)hideInGameUI:(BOOL)hide
{
	[self.scoreLabelValue setHidden:hide];
	[self.scoreLabelValueShadow setHidden:hide];
	[self.timeLabelValue setHidden:hide];
	[self.timeLabelValueShadow setHidden:hide];
	[self.scoreLabel setHidden:hide];
	[self.scoreLabelShadow setHidden:hide];
	[self.timeLabel setHidden:hide];
	[self.timeLabelShadow setHidden:hide];
}

+ (SKLabelNode *)labelWithText:(NSString *)text andSize:(CGFloat)textSize
{
	NSString *fontName = @"Optima-ExtraBlack";
	SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:fontName];

	myLabel.text = text;
	myLabel.fontSize = textSize;
	myLabel.fontColor = [SKColor yellowColor];

	return myLabel;
}

+ (SKLabelNode *)dropShadowOnLabel:(SKLabelNode *)frontLabel
{
	SKLabelNode *myLabelBackground = [frontLabel copy];
	myLabelBackground.userInteractionEnabled = NO;
	myLabelBackground.fontColor = [SKColor blackColor];
	myLabelBackground.position = CGPointMake(2 + frontLabel.position.x, -2 + frontLabel.position.y);

	myLabelBackground.zPosition = frontLabel.zPosition - 1;
	[frontLabel.parent addChild:myLabelBackground];
	return myLabelBackground;
}

- (void)update:(NSTimeInterval)currentTime
{
	// Update the score and time labels with the correct data.
	[self.gameStateDelegate setScoreLabelLocation:self.scoreLabelValue.position];

	[_scoreLabelValue setText:[NSString stringWithFormat:@"%lu", (unsigned long)self.gameStateDelegate.score]];
	[_scoreLabelValueShadow setText:_scoreLabelValue.text];

	if (self.gameStateDelegate.secondsRemaining > 60) {
		NSUInteger minutes = (NSUInteger)(self.gameStateDelegate.secondsRemaining / 60.0f);
		NSUInteger seconds = (NSUInteger)fmod(self.gameStateDelegate.secondsRemaining, 60.0);
		[_timeLabelValue setText:[NSString stringWithFormat:@"%lu:%02lu", (unsigned long)minutes, (unsigned long)seconds]];
		[self.timeLabelValueShadow setText:_timeLabelValue.text];
	} else {
		NSUInteger seconds = (NSUInteger)fmod(self.gameStateDelegate.secondsRemaining, 60.0);
		[_timeLabelValue setText:[NSString stringWithFormat:@"0:%02lu", (unsigned long)seconds]];
		[self.timeLabelValueShadow setText:_timeLabelValue.text];
	}
}

- (void)touchUpAtPoint:(CGPoint)location
{
	if (_gameState == AAPLGameStatePaused) {
		[self.pauseNode touchUpAtPoint:location];
	} else if (_gameState == AAPLGameStatePostGame) {
		[self.postGameNode touchUpAtPoint:location];
	} else if (_gameState == AAPLGameStatePreGame) {
		[self.menuNode touchUpAtPoint:location];
	} else if (_gameState == AAPLGameStateInGame) {
		SKNode *touchedNode = [self.scene nodeAtPoint:location];

		if (touchedNode == self.timeLabelValue) {
			[[AAPLGameSimulation sim] setGameState:AAPLGameStatePaused];
		}
	}
}

@end
