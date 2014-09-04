/*
 
 File: SampleViewController.m
 
 Abstract: Provide an example of how to successfully submit scores to leaderboards
 and store them when submission fails.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "SampleViewController.h"

@implementation SampleViewController

@synthesize player;

- (id)initWithCoder:(NSCoder *)aDecoder 
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        context = 0;
    }
    return self;
}

- (void) viewDidLoad
{
    [self enableGameCenter:NO];
}

- (IBAction)showLeaderboardButtonAction:(id)event 
{
    NSString * leaderboardCategory = @"com.appledts.GameCenterSampleApps.leaderboard.seconds";

    // The intent here is to show the leaderboard and then submit a score. If we try to submit the score first there is no guarentee 
    // the server will have recieved the score when retreiving the current list
    [self showLeaderboard:leaderboardCategory];
    [self insertCurrentTimeIntoLeaderboard:leaderboardCategory];
}

#pragma mark - 
#pragma mark Example of a score to be inserted

// Using time as as an int of seconds from 1970 gives us a good rolling number to test against 
- (void)insertCurrentTimeIntoLeaderboard:(NSString*)leaderboard 
{         
    NSDate *today = [NSDate date];
    int64_t score = [today timeIntervalSince1970];
    GKScore * submitScore = [[GKScore alloc] initWithCategory:leaderboard];
    [submitScore setValue:score]; 
    
    // New feature in iOS5 tells GameCenter which leaderboard is the default per user.
    // This can be used to show a user's favorite course/track associated leaderboard, or just show the latest score submitted.
    [submitScore setShouldSetDefaultLeaderboard:YES];
    
    // New feature in iOS5 allows you to set the context to which the score was sent. For instance this will set the context to be 
    //the count of the button press per run time. Information stored in context isn't accessable in standard GKLeaderboardViewController,
    //instead it's accessable from GKLeaderboard's loadScoresWithCompletionHandler:
    [submitScore setContext:context++];
    
    [self.player submitScore:submitScore];
    [submitScore release];
}

// Example of how to bring up a specific leaderboard 
- (void)showLeaderboard:(NSString *)leaderboard 
{
    GKLeaderboardViewController * leaderboardViewController = [[GKLeaderboardViewController alloc] init];
    [leaderboardViewController setCategory:leaderboard];
    [leaderboardViewController setLeaderboardDelegate:self];
    [self presentModalViewController:leaderboardViewController  animated:YES];
    [leaderboardViewController release];
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController  
{
	[self dismissModalViewControllerAnimated: YES];
}

// Disable GameCenter options from view 
- (void)enableGameCenter:(BOOL)enableGameCenter 
{
    [showLeaderboardButton setEnabled:enableGameCenter];
}

- (void)didReceiveMemoryWarning 
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc 
{
    [player release];
    [super dealloc];
}

@end
