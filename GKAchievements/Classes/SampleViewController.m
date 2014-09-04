/*
 File: SampleViewController.m
 
 Abstract: Provide an example of how to successfully submit achievements and store them when network connection is not available
 
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
    }
    return self;
}

/* 
 On Pressing the button, load the AchievementViewController and add a percentage to the achievement.
 The submission of the achievement is done asynchronously, and the increase in percentage will not necessarily show up
 on the current viewing. This is an example and typically achievements should be submitted well before any ViewController is presented.
 */
- (IBAction)showAchievementsThenAddExampleAchievement
{
    [self showAchievementsViewController];    
    
    NSString * identifier       =   @"com.appledts.GameCenterSampleApps.achievement";
    NSString * hiddenIdentifier =   @"com.appledts.GameCenterSampleApps.hidden_achievement";
    
    // Submit an achievement for pressing this button 
    GKAchievement * achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
    achievementsPercentageComplete += 25;
    [achievement setPercentComplete: achievementsPercentageComplete];
    [player submitAchievement:achievement];
    
    // submit hidden achievement after the first achievement is completed. 
    if (achievement.completed || achievement.percentComplete >= 100){
        hiddenAchievementPercentageComplete += 10;
		GKAchievement * hiddenAchievement = [[[GKAchievement alloc] initWithIdentifier:hiddenIdentifier] autorelease];
		[hiddenAchievement setPercentComplete:hiddenAchievementPercentageComplete];
        [player submitAchievement:hiddenAchievement];
    }
}

// Enable GameCenter options like the button for showing achievements
- (void)enableGameCenter:(BOOL)enableGameCenter
{
	[showAchievementsButton setEnabled:enableGameCenter];
    // Enable all Game Center based UI here
}

#pragma mark - 
#pragma mark Show achievements

// View a list of unlocked achievements 
- (void)showAchievementsViewController
{
    if ([self modalViewController]) {
        [self dismissModalViewControllerAnimated:NO];
    }
    GKAchievementViewController * achievementViewController = [[GKAchievementViewController alloc] init];
    [achievementViewController setAchievementDelegate:self];
    [self presentModalViewController:achievementViewController animated:YES];
}

// Dismiss the achievement viewController 
- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController 
{
    if ([self modalViewController]) {
        // If there could be multiple modal ViewControllers up, a check is necessary.
        [self dismissModalViewControllerAnimated: YES];
    }
}

/*
 To offer a proper experience with GameKit view controllers, a UIViewController
 based OpenGL should be used. For an example please look at the OpenGL ES Application based 
 template in the new project menu. 

 If the game view does not autorotate during gameplay, please create a new UIViewController that does 
 autorotate and present the modal view controller from that. To control where the welcome 
 banners slide in from you must set the position of the status bar on rotation. You should do 
 this even if the status bar is hidden, to make sure banners and alerts appear oriented correctly.
 
 
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any stored data, images, etc that aren't in use.
}

- (void)dealloc
{
    [player release];
    [super dealloc];
}

@end
