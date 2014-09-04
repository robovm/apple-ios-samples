/*
     File: APAAppDelegateOSX.m
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

#import "APAAppDelegateOSX.h"
#import "APAAdventureScene.h"

// Uncomment this line to show debug info in the Sprite Kit view:
//#define SHOW_DEBUG_INFO 1

@interface APAAppDelegateOSX ()
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet SKView *skView;
@property (nonatomic) APAAdventureScene *scene;

@property (assign) IBOutlet NSImageView *gameLogo;
@property (assign) IBOutlet NSProgressIndicator *loadingProgressIndicator;
@property (assign) IBOutlet NSButton *archerButton;
@property (assign) IBOutlet NSButton *warriorButton;
@end

@implementation APAAppDelegateOSX

#pragma mark - Application Lifecycle
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Start the progress indicator animation.
    [self.loadingProgressIndicator startAnimation:self];
    
    // Load the shared assets of the scene before we initialize and load it.
    [APAAdventureScene loadSceneAssetsWithCompletionHandler:^{
        // The size for the primary scene - 1024x768 is good for OS X and iOS.
        CGSize size = CGSizeMake(1024, 768);
        
        APAAdventureScene *scene = [[APAAdventureScene alloc] initWithSize:size];
        scene.scaleMode = SKSceneScaleModeAspectFit;
        self.scene = scene;
        
        [self.skView presentScene:scene];
        
        [self.loadingProgressIndicator stopAnimation:self];
        [self.loadingProgressIndicator setHidden:YES];
        
        [[NSAnimationContext currentContext] setDuration:2.0f];
        [[self.archerButton animator] setAlphaValue:1.0f];
        [[self.warriorButton animator] setAlphaValue:1.0f];
        
        [scene configureGameControllers];
    }];

#ifdef SHOW_DEBUG_INFO
    // Show debug info in view.
    self.skView.showsFPS = YES;
    self.skView.showsNodeCount = YES;
    self.skView.showsDrawCount = YES;
#endif
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

#pragma mark - Actions
- (IBAction)chooseArcher:(id)sender {
    [self startGameWithHeroType:APAHeroTypeArcher];
}

- (IBAction)chooseWarrior:(id)sender {
    [self startGameWithHeroType:APAHeroTypeWarrior];
}

#pragma mark - Starting the Game
- (void)startGameWithHeroType:(APAHeroType)type {
    [[NSAnimationContext currentContext] setDuration:2.0f];
    [[self.gameLogo animator] setAlphaValue:0.0f];
    [[self.warriorButton animator] setAlphaValue:0.0f];
    [[self.archerButton animator] setAlphaValue:0.0f];
    
    [self.scene setDefaultPlayerHeroType:type];
    [self.scene startLevel];
}

@end
