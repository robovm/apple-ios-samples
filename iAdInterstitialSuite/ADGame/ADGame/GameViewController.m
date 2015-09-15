/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Main view controller for ADGame
*/

#import "GameViewController.h"
#import "ScoreView.h"

// Class extention for private methods.
@interface GameViewController()
{
    NSInteger gamePhase;
    NSInteger gameWinner;
    CGFloat scores[4];
    ADInterstitialAd *interstitial;
}

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIButton *player1;
@property (nonatomic, strong) IBOutlet UIButton *player2;
@property (nonatomic, strong) IBOutlet UIButton *player3;
@property (nonatomic, strong) IBOutlet UIButton *player4;
@property (nonatomic, strong) IBOutlet ScoreView *scoreView;

// Graphics
@property (NS_NONATOMIC_IOSONLY, readonly, copy) UIBezierPath *scorePath;

@end


#pragma mark -
@implementation GameViewController

// Game Phases
enum {
    ADGameWaiting = 0,
    ADGameRequested,
    ADGameStarted1,
    ADGameStarted2,
    ADGameStarted3,
    ADGameStartedDeclare1,
    ADGameStartedDeclare2,
    ADGameStartedDeclare3,
    ADGameStartedWars1,
    ADGamePlaying,
    ADGameWon,
};

#pragma mark -
#pragma mark Lifetime Management

- (void)viewDidLoad  {
    [super viewDidLoad];
    [self cycleInterstitial]; // Prepare our interstitial for after the game so that we can be certain its ready to present
    
    [UIViewController prepareInterstitialAds];
    
    [self resetGame]; // Get the game ready for the player
    self.scoreView.fillColor = [UIColor colorWithRed:0.4375 green:0.875 blue:1.0 alpha:0.75];
    self.scoreView.strokeColor = [UIColor colorWithRed:0.25 green:0.5625 blue:0.6875 alpha:0.5];
}

- (void)dealloc {
    interstitial.delegate = nil;
}

#pragma mark -
#pragma mark View Layout

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self layoutGame];
}

- (void)viewDidLayoutSubviews {
    [self layoutGame];
}

#pragma mark -
#pragma mark Interstitial Management

- (void)cycleInterstitial {
    // Clean up the old interstitial...
    interstitial.delegate = nil;
    // and create a new interstitial. We set the delegate so that we can be notified of when
    interstitial = [[ADInterstitialAd alloc] init];
    
    interstitial.delegate = self;
}

- (void)presentInterlude {
    // If the interstitial managed to load, then we'll present it now.
    if (interstitial.loaded) {
       [self requestInterstitialAdPresentation];
    }
    else {
        [self resetGameSoon];
    }
}

#pragma mark ADInterstitialViewDelegate methods

// When this method is invoked, the application should remove the view from the screen and tear it down.
// The content will be unloaded shortly after this method is called and no new content will be loaded in that view.
// This may occur either when the user dismisses the interstitial view via the dismiss button or
// if the content in the view has expired.
- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd {
    [self cycleInterstitial];
    if (gamePhase == ADGameWon) {
        [self resetGameSoon];
    }
}

// This method will be invoked when an error has occurred attempting to get advertisement content. 
// The ADError enum lists the possible error codes.
- (void)interstitialAd:(ADInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    [self cycleInterstitial];
    if (gamePhase == ADGameWon) {
        [self resetGameSoon];
    }
}

#pragma mark -
#pragma mark Game Input

- (void)actOnPlayer:(int)player {
    if (gamePhase == ADGamePlaying) {
        [self score:player];
    }
    else if (gamePhase == ADGameWaiting) {
        [self startGame];
    }
}

- (IBAction)scorePlayer1 {
    [self actOnPlayer:0];
}

- (IBAction)scorePlayer2 {
    [self actOnPlayer:1];
}

- (IBAction)scorePlayer3 {
    [self actOnPlayer:2];
}

- (IBAction)scorePlayer4 {
    [self actOnPlayer:3];
}

#pragma mark -
#pragma mark Game Logic

- (void)score:(int)idx {
    scores[idx] += 0.05;
    self.scoreView.shape = self.scorePath;
    if (scores[idx] >= 1.0) {
        gamePhase = ADGameWon;
        gameWinner = idx+1;
        [self winGame];
    }
}

- (void)startGame {
    // Only start a game if we haven't started and one hasn't been requested.
    if (gamePhase == ADGameWaiting) {
        gamePhase = ADGameRequested;
        self.titleLabel.hidden = NO;
        self.titleLabel.text = @"";
        self.titleLabel.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(gameStartCountdown:) userInfo:nil repeats:YES];
    }
}

- (void)gameStartCountdown:(NSTimer *)timer {
    switch (gamePhase) {
        case ADGameRequested:
            self.titleLabel.text = @"1";
            break;
        case ADGameStarted1:
            self.titleLabel.text = @"2";
            break;
        case ADGameStarted2:
            self.titleLabel.text = @"3";
            break;
        case ADGameStarted3:
            self.titleLabel.text = @"4";
            break;
        case ADGameStartedDeclare1:
        case ADGameStartedDeclare2:
        case ADGameStartedDeclare3:
            self.titleLabel.text = @"I declare a thumb war!";
            break;
        case ADGameStartedWars1:
            self.titleLabel.hidden = YES;
            self.titleLabel.text = @"Thumb Wars!";
            self.scoreView.hidden = NO;
            [timer invalidate];
            break;
    }
    ++gamePhase;
}

- (void)winGame {
    self.titleLabel.text = [NSString stringWithFormat:@"Player %ld won!", gameWinner];
    self.titleLabel.hidden = NO;
    [UIView animateWithDuration:1.0 animations:^{
        self.scoreView.alpha = 0.0;
        self.titleLabel.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.titleLabel.bounds));
        self.player1.center = CGPointMake(self.player1.center.x, self.player1.center.y + 1024.0);
        self.player2.center = CGPointMake(self.player2.center.x + 1024.0, self.player2.center.y);
        self.player3.center = CGPointMake(self.player3.center.x, self.player3.center.y - 1024.0);
        self.player4.center = CGPointMake(self.player4.center.x - 1024.0, self.player4.center.y);
    } completion:^(BOOL finished) {
        [self presentInterlude];
    }];
}

- (void)resetGame {
    scores[0] = scores[1] = scores[2] = scores[3] = 0.0;
    self.scoreView.hidden = YES;
    self.scoreView.alpha = 1.0;
    self.scoreView.shape = self.scorePath;
    self.titleLabel.text = @"Thumb Wars!";
    self.titleLabel.hidden = NO;
    gamePhase = ADGameWaiting;
    gameWinner = 0;
    [self layoutGame];
}

- (void)resetGameSoon {
    // Give the user a few seconds to bask in the glory of having won before resetting the game.
    [self performSelector:@selector(resetGame) withObject:nil afterDelay:3.0];
}

- (void)layoutGame {
    if (gamePhase < ADGameWon) {
        CGRect bounds = self.view.bounds;
        self.player1.center = CGPointMake(CGRectGetMidX(bounds), 56.0);
        self.player2.center = CGPointMake(56.0, CGRectGetMidY(bounds));
        self.player3.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds) - 56.0);
        self.player4.center = CGPointMake(CGRectGetMaxX(bounds) - 56.0, CGRectGetMidY(bounds));
        self.scoreView.shape = self.scorePath;
        self.titleLabel.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    }
    else {
        self.titleLabel.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.titleLabel.bounds) + 140);
        self.player1.center = CGPointMake(self.player1.center.x, self.player1.center.y + 1024.0);
        self.player2.center = CGPointMake(self.player2.center.x + 1024.0, self.player2.center.y);
        self.player3.center = CGPointMake(self.player3.center.x, self.player3.center.y - 1024.0);
        self.player4.center = CGPointMake(self.player4.center.x - 1024.0, self.player4.center.y);
    }
}

#pragma mark -
#pragma mark Game Graphics

#define kOffset 20.0

CGPoint CenterPoint(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

- (UIBezierPath *)scorePath {
    CGRect bounds = self.scoreView.bounds;
    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    CGFloat xradius = bounds.size.width / 2.0 - kOffset, yradius = bounds.size.height / 2.0 - kOffset;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint p1 = CGPointMake(center.x, center.y - yradius * scores[0] - kOffset);
    CGPoint p2 = CGPointMake(center.x - xradius * scores[1] - kOffset, center.y);
    CGPoint p3 = CGPointMake(center.x, center.y + yradius * scores[2] + kOffset);
    CGPoint p4 = CGPointMake(center.x + xradius * scores[3] + kOffset, center.y);
    CGPoint cp12 = CenterPoint(CenterPoint(p1, p2), center);
    CGPoint cp23 = CenterPoint(CenterPoint(p2, p3), center);
    CGPoint cp34 = CenterPoint(CenterPoint(p3, p4), center);
    CGPoint cp41 = CenterPoint(CenterPoint(p4, p1), center);
    [path moveToPoint:p1];
    [path addQuadCurveToPoint:p2 controlPoint:cp12];
    [path addQuadCurveToPoint:p3 controlPoint:cp23];
    [path addQuadCurveToPoint:p4 controlPoint:cp34];
    [path addQuadCurveToPoint:p1 controlPoint:cp41];
    [path closePath];
    [path appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(cp12.x, cp12.y, cp34.x - cp12.x, cp34.y - cp12.y)]];
    
    return path;
}

@end
