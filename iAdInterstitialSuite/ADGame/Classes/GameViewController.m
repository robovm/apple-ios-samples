/*
    File: GameViewController.m
Abstract: Main view controller for ADGame
 Version: 1.2

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2012 Apple Inc. All Rights Reserved.

*/

#import "GameViewController.h"
#import "ScoreView.h"

// Class extention for private methods.
@interface GameViewController()

// Interstitials
- (void)cycleInterstitial;
- (void)presentInterlude;

// Game Input
- (void)actOnPlayer:(int)player;

// Game Logic
- (void)score:(int)idx;
- (void)startGame;
- (void)gameStartCountdown:(NSTimer *)timer;
- (void)winGame;
- (void)resetGame;
- (void)resetGameSoon;
- (void)layoutGame;

// Graphics
- (UIBezierPath *)scorePath;

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

@synthesize titleLabel;
@synthesize player1;
@synthesize player2;
@synthesize player3;
@synthesize player4;
@synthesize scoreView;

#pragma mark -
#pragma mark Lifetime Management

- (void)viewDidLoad 
{
    [super viewDidLoad];
    [self cycleInterstitial]; // Prepare our interstitial for after the game so that we can be certain its ready to present
    [self resetGame]; // Get the game ready for the player
    scoreView.fillColor = [UIColor colorWithRed:0.4375 green:0.875 blue:1.0 alpha:0.75];
    scoreView.strokeColor = [UIColor colorWithRed:0.25 green:0.5625 blue:0.6875 alpha:0.5];
}

- (void)viewDidUnload
{
    interstitial.delegate = nil;
    
    self.titleLabel = nil;
    self.player1 = nil;
    self.player2 = nil;
    self.player3 = nil;
    self.player4 = nil;
    self.scoreView = nil;
    [interstitial release]; interstitial = nil;
    [super viewDidUnload];
}

- (void)dealloc
{
    interstitial.delegate = nil;
    
    [titleLabel release];
    [player1 release];
    [player2 release];
    [player3 release];
    [player4 release];
    [scoreView release];
    [interstitial release];
    [super dealloc];
}

#pragma mark -
#pragma mark View Layout

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self layoutGame];
}

- (void)viewDidLayoutSubviews
{
    [self layoutGame];
}

#pragma mark -
#pragma mark Interstitial Management

- (void)cycleInterstitial
{
    // Clean up the old interstitial...
    interstitial.delegate = nil;
    [interstitial release];
    // and create a new interstitial. We set the delegate so that we can be notified of when 
    interstitial = [[ADInterstitialAd alloc] init];
    interstitial.delegate = self;
}

- (void)presentInterlude
{
    // If the interstitial managed to load, then we'll present it now.
    if (interstitial.loaded) {
        [interstitial presentFromViewController:self];
    } else {
        [self resetGameSoon];
    }
}

#pragma mark ADInterstitialViewDelegate methods

// When this method is invoked, the application should remove the view from the screen and tear it down.
// The content will be unloaded shortly after this method is called and no new content will be loaded in that view.
// This may occur either when the user dismisses the interstitial view via the dismiss button or
// if the content in the view has expired.
- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd
{
    [self cycleInterstitial];
    if (gamePhase == ADGameWon) {
        [self resetGameSoon];
    }
}

// This method will be invoked when an error has occurred attempting to get advertisement content. 
// The ADError enum lists the possible error codes.
- (void)interstitialAd:(ADInterstitialAd *)interstitialAd didFailWithError:(NSError *)error
{
    [self cycleInterstitial];
    if (gamePhase == ADGameWon) {
        [self resetGameSoon];
    }
}

#pragma mark -
#pragma mark Game Input

- (void)actOnPlayer:(int)player
{
    if (gamePhase == ADGamePlaying) {
        [self score:player];
    } else if (gamePhase == ADGameWaiting) {
        [self startGame];
    }
}

- (IBAction)scorePlayer1
{
    [self actOnPlayer:0];
}

- (IBAction)scorePlayer2
{
    [self actOnPlayer:1];
}

- (IBAction)scorePlayer3
{
    [self actOnPlayer:2];
}

- (IBAction)scorePlayer4
{
    [self actOnPlayer:3];
}

#pragma mark -
#pragma mark Game Logic

- (void)score:(int)idx
{
    scores[idx] += 0.05;
    scoreView.shape = [self scorePath];
    if (scores[idx] >= 1.0) {
        gamePhase = ADGameWon;
        gameWinner = idx+1;
        [self winGame];
    }
}

- (void)startGame
{
    // Only start a game if we haven't started and one hasn't been requested.
    if (gamePhase == ADGameWaiting) {
        gamePhase = ADGameRequested;
        titleLabel.hidden = NO;
        titleLabel.text = @"";
        titleLabel.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(gameStartCountdown:) userInfo:nil repeats:YES];
    }
}

- (void)gameStartCountdown:(NSTimer *)timer
{
    switch (gamePhase) {
        case ADGameRequested:
            titleLabel.text = @"1";
            break;
        case ADGameStarted1:
            titleLabel.text = @"2";
            break;
        case ADGameStarted2:
            titleLabel.text = @"3";
            break;
        case ADGameStarted3:
            titleLabel.text = @"4";
            break;
        case ADGameStartedDeclare1:
        case ADGameStartedDeclare2:
        case ADGameStartedDeclare3:
            titleLabel.text = @"I declare a thumb war!";
            break;
        case ADGameStartedWars1:
            titleLabel.hidden = YES;
            titleLabel.text = @"Thumb Wars!";
            scoreView.hidden = NO;
            [timer invalidate];
            break;
    }
    ++gamePhase;
}

- (void)winGame
{
    titleLabel.text = [NSString stringWithFormat:@"Player %i won!", gameWinner];
    titleLabel.hidden = NO;
    [UIView animateWithDuration:1.0 animations:^{
        scoreView.alpha = 0.0;
        titleLabel.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(titleLabel.bounds));
        player1.center = CGPointMake(player1.center.x, player1.center.y + 1024.0);
        player2.center = CGPointMake(player2.center.x + 1024.0, player2.center.y);
        player3.center = CGPointMake(player3.center.x, player3.center.y - 1024.0);
        player4.center = CGPointMake(player4.center.x - 1024.0, player4.center.y);
    } completion:^(BOOL finished) {
        [self presentInterlude];
    }];
}

- (void)resetGame
{
    scores[0] = scores[1] = scores[2] = scores[3] = 0.0;
    scoreView.hidden = YES;
    scoreView.alpha = 1.0;
    scoreView.shape = [self scorePath];
    titleLabel.text = @"Thumb Wars!";
    titleLabel.hidden = NO;
    gamePhase = ADGameWaiting;
    gameWinner = 0;
    [self layoutGame];
}

- (void)resetGameSoon
{
    // Give the user a few seconds to bask in the glory of having won before resetting the game.
    [self performSelector:@selector(resetGame) withObject:nil afterDelay:3.0];
}

- (void)layoutGame
{
    if (gamePhase < ADGameWon) {
        CGRect bounds = self.view.bounds;
        player1.center = CGPointMake(CGRectGetMidX(bounds), 56.0);
        player2.center = CGPointMake(56.0, CGRectGetMidY(bounds));
        player3.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds) - 56.0);
        player4.center = CGPointMake(CGRectGetMaxX(bounds) - 56.0, CGRectGetMidY(bounds));
        scoreView.shape = [self scorePath];
        titleLabel.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    } else {
        titleLabel.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(titleLabel.bounds));
        titleLabel.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(titleLabel.bounds));
        player1.center = CGPointMake(player1.center.x, player1.center.y + 1024.0);
        player2.center = CGPointMake(player2.center.x + 1024.0, player2.center.y);
        player3.center = CGPointMake(player3.center.x, player3.center.y - 1024.0);
        player4.center = CGPointMake(player4.center.x - 1024.0, player4.center.y);
    }
}

#pragma mark -
#pragma mark Game Graphics

#define kOffset 20.0

CGPoint CenterPoint(CGPoint p1, CGPoint p2)
{
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

- (UIBezierPath *)scorePath
{
    CGRect bounds = scoreView.bounds;
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
