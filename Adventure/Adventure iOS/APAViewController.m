/*
     File: APAViewController.m
 Abstract: n/a
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "APAViewController.h"
#import "APAAdventureScene.h"

// Uncomment this line to show debug info in the Sprite Kit view:
//#define SHOW_DEBUG_INFO 1

@interface APAViewController ()
@property (nonatomic) IBOutlet SKView *skView;
@property (nonatomic) IBOutlet UIImageView *gameLogo;
@property (nonatomic) IBOutlet UIActivityIndicatorView *loadingProgressIndicator;
@property (nonatomic) IBOutlet UIButton *archerButton;
@property (nonatomic) IBOutlet UIButton *warriorButton;
@property (nonatomic) APAAdventureScene *scene;
@end

@implementation APAViewController

#pragma mark - View Lifecycle
- (void)viewWillAppear:(BOOL)animated {
    // Start the progress indicator animation.
    [self.loadingProgressIndicator startAnimating];
    
    // Load the shared assets of the scene before we initialize and load it.
    [APAAdventureScene loadSceneAssetsWithCompletionHandler:^{
        CGSize viewSize = self.view.bounds.size;
        
        // On iPhone/iPod touch we want to see a similar amount of the scene as on iPad.
        // So, we set the size of the scene to be double the size of the view, which is
        // the whole screen, 3.5- or 4- inch. This effectively scales the scene to 50%.
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            viewSize.height *= 2;
            viewSize.width *= 2;
        }
        
        APAAdventureScene *scene = [[APAAdventureScene alloc] initWithSize:viewSize];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        self.scene = scene;
        
        [scene configureGameControllers];
        
        [self.loadingProgressIndicator stopAnimating];
        [self.loadingProgressIndicator setHidden:YES];
        
        [self.skView presentScene:scene];
        
        [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.archerButton.alpha = 1.0f;
            self.warriorButton.alpha = 1.0f;
        } completion:NULL];
    }];
#ifdef SHOW_DEBUG_INFO
    // Show debug information.
    self.skView.showsFPS = YES;
    self.skView.showsDrawCount = YES;
    self.skView.showsNodeCount = YES;
#endif
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Rotation
- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

#pragma mark - UI Display and Actions
- (void)hideUIElements:(BOOL)shouldHide animated:(BOOL)shouldAnimate {
    CGFloat alpha = shouldHide ? 0.0f : 1.0f;
    
    if (shouldAnimate) {
        [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.gameLogo.alpha = alpha;
            self.archerButton.alpha = alpha;
            self.warriorButton.alpha = alpha;
        } completion:NULL];
    } else {
        [self.gameLogo setAlpha:alpha];
        [self.warriorButton setAlpha:alpha];
        [self.archerButton setAlpha:alpha];
    }
}

- (IBAction)chooseArcher:(id)sender {
    [self startGameWithHeroType:APAHeroTypeArcher];
}

- (IBAction)chooseWarrior:(id)sender {
    [self startGameWithHeroType:APAHeroTypeWarrior];
}

#pragma mark - Starting the Game
- (void)startGameWithHeroType:(APAHeroType)type {
    [self hideUIElements:YES animated:YES];
    [self.scene setDefaultPlayerHeroType:type];
    [self.scene startLevel];
}

@end
