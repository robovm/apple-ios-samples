/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller runs the Four-In-A-Row game. Handles UI input for player turns and uses GKMinmaxStrategist for AI turns.
 */

@import GameplayKit;

#import "AAPLViewController.h"

#import "AAPLBoard.h"
#import "AAPLPlayer.h"
#import "AAPLMinmaxStrategy.h"

// Switch this off to manually make moves for the black (O) player.
#define USE_AI_PLAYER 1

@interface AAPLViewController ()

@property AAPLBoard *board;
@property GKMinmaxStrategist *strategist;
@property (nonatomic, strong) IBOutletCollection(UIButton) NSArray *columnButtons;

@property UIBezierPath *chipPath;
@property NSArray<NSMutableArray<CAShapeLayer *> *> *chipLayers;

@end

@implementation AAPLViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.strategist = [[GKMinmaxStrategist alloc] init];

    // 4 AI turns + 3 human turns in between = 7 turns for dominant AI (if heuristic good).
	self.strategist.maxLookAheadDepth = 7;
	self.strategist.randomSource = [[GKARC4RandomSource alloc] init];

    NSMutableArray *columns = [NSMutableArray arrayWithCapacity:AAPLBoard.width];
    for (NSInteger column = 0; column < AAPLBoard.width; column++) {
        columns[column] = [NSMutableArray arrayWithCapacity:AAPLBoard.height];
    }
    self.chipLayers = [columns copy];
    
    [self resetBoard];
}

- (void)viewDidLayoutSubviews {
    UIButton *button = self.columnButtons[0];
    CGFloat length = MIN(button.frame.size.width - 10, button.frame.size.height / 6 - 10);
    CGRect rect = CGRectMake(0, 0, length, length);
    self.chipPath = [UIBezierPath bezierPathWithOvalInRect:rect];
    
    [self.chipLayers enumerateObjectsUsingBlock:^(NSArray<CAShapeLayer *> *columnLayers, NSUInteger column, BOOL *stop) {
        [columnLayers enumerateObjectsUsingBlock:^(CAShapeLayer *chip, NSUInteger row, BOOL *stop) {
            chip.path = self.chipPath.CGPath;
            chip.frame = self.chipPath.bounds;
            chip.position = [self positionForChipLayerAtColumn:column row:row];
        }];
    }];
}

- (IBAction)makeMove:(UIButton *)sender {
    NSInteger column = sender.tag;

    if ([self.board canMoveInColumn:column]) {
        [self.board addChip:self.board.currentPlayer.chip inColumn:column];
		[self updateButton:sender];
		[self updateGame];
    }
}

- (void)updateButton:(UIButton *)button {
    NSInteger column = button.tag;
    button.enabled = [self.board canMoveInColumn:column];
 
    NSInteger row = AAPLBoard.height;
    AAPLChip chip = AAPLChipNone;
    while (chip == AAPLChipNone && row > 0) {
        chip = [self.board chipInColumn:column row:--row];
    }

    if (chip != AAPLChipNone) {
        [self addChipLayerAtColumn:column row:row color:[AAPLPlayer playerForChip:chip].color];
    }
}

- (CGPoint)positionForChipLayerAtColumn:(NSInteger)column row:(NSInteger)row {
    UIButton *columnButton = self.columnButtons[column];
    CGFloat xOffset = CGRectGetMidX(columnButton.frame);
    CGFloat yStride = self.chipPath.bounds.size.height + 10;
    CGFloat yOffset = CGRectGetMaxY(columnButton.frame) - yStride / 2;
    return CGPointMake(xOffset, yOffset - yStride * row);
}

- (void)addChipLayerAtColumn:(NSInteger)column row:(NSInteger)row color:(UIColor *)color {
    if (self.chipLayers[column].count < row + 1) {
        // Create and position a layer for the new chip.
        CAShapeLayer *newChip = [CAShapeLayer layer];
        newChip.path = self.chipPath.CGPath;
        newChip.frame = self.chipPath.bounds;
        newChip.fillColor = color.CGColor;
        newChip.position = [self positionForChipLayerAtColumn:column row:row];
        
        // Animate the chip falling into place.
        [self.view.layer addSublayer:newChip];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.y"];
        animation.fromValue = @(-newChip.frame.size.height);
        animation.toValue = @(newChip.position.y);
        animation.duration = 0.5;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        [newChip addAnimation:animation forKey:nil];
        self.chipLayers[column][row] = newChip;
    }
}

- (void)resetBoard {
    self.board = [[AAPLBoard alloc] init];
    for (UIButton *button in self.columnButtons) {
        [self updateButton:button];
    }
    [self updateUI];

	self.strategist.gameModel = self.board;
    
    for (NSMutableArray<CAShapeLayer *> *column in self.chipLayers) {
        for (CAShapeLayer *chip in column) {
            [chip removeFromSuperlayer];
        }
        [column removeAllObjects];
    }
}

- (void)updateGame {
    NSString *gameOverTitle = nil;
    if ([self.board isWinForPlayer:self.board.currentPlayer]) {
        gameOverTitle = [NSString stringWithFormat:@"%@ Wins!", self.board.currentPlayer.name];
    }
    else if (self.board.isFull) {
        gameOverTitle = @"Draw!";
    }
    
    if (gameOverTitle) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:gameOverTitle message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Play Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self resetBoard];
        }];
        
        [alert addAction:alertAction];

        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    self.board.currentPlayer = self.board.currentPlayer.opponent;

    [self updateUI];
}

- (void)updateUI {
    self.navigationItem.title = [NSString stringWithFormat:@"%@ Turn", self.board.currentPlayer.name];
    self.navigationController.navigationBar.backgroundColor = self.board.currentPlayer.color;
    
#if USE_AI_PLAYER
    if (self.board.currentPlayer.chip == AAPLChipBlack) {
        // Disable buttons & show spinner while AI player "thinks".
        for (UIButton *button in self.columnButtons) {
            button.enabled = NO;
        }

        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        
        [spinner startAnimating];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];

		// Invoke GKMinmaxStrategist on background queue -- all that lookahead might take a while.
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSTimeInterval strategistTime = CFAbsoluteTimeGetCurrent();
			NSInteger column = [self columnForAIMove];
			NSTimeInterval delta = CFAbsoluteTimeGetCurrent() - strategistTime;

            static const NSTimeInterval aiTimeCeiling = 2.0;

            /*
                Make the player wait for the AI for a minimum time so that they
                notice the AI moving even if it's fast.
            */
			NSTimeInterval delay = MIN(aiTimeCeiling - delta, aiTimeCeiling);
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[self makeAIMoveInColumn:column];
			});

		});
    }
#endif
}

- (NSInteger)columnForAIMove {
    NSInteger column;

	AAPLMove *aiMove = [self.strategist bestMoveForPlayer:self.board.currentPlayer];
	
    NSAssert(aiMove != nil, @"AI should always be able to move (detect endgame before invoking AI)");

    column = aiMove.column;

	return column;
}

- (void)makeAIMoveInColumn:(NSInteger)column {
    // Done "thinking", hide spinner.
    self.navigationItem.leftBarButtonItem = nil;

    [self.board addChip:self.board.currentPlayer.chip inColumn:column];
	for (UIButton *button in self.columnButtons) {
		[self updateButton:button];
	}

    [self updateGame];
}

@end
