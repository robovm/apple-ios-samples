/*
 
 File:GKAuthenticationAppDelegate.m
 
 Abstract: Provide an example of how to successfully authenticate with GameKit
 
 NOTE: This code will not run properly until Game Center is enabled in iTunes Connect.
 
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

#include <sys/types.h>
#include <sys/sysctl.h>

#import "GKAuthenticationAppDelegate.h"


@implementation GKAuthenticationAppDelegate


@synthesize window;
@synthesize mainViewController;


#pragma mark -
#pragma mark Game Center Support

@synthesize currentPlayerID, 
            gameCenterAuthenticationComplete;



#pragma mark -
#pragma mark Game Center Support

// Check for the availability of Game Center API. 
BOOL isGameCenterAPIAvailable()
{
    // Check for presence of GKLocalPlayer API.
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // The device must be running running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported); 
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions  
{        
    // Override point for customization after application launch.  

    // Add the main view controller's view to the window and display.
    [self.window addSubview:mainViewController.view];
    [self.window makeKeyAndVisible];
    
    self.gameCenterAuthenticationComplete = NO;
    
    if (!isGameCenterAPIAvailable()) {
        // Game Center is not available. 
        self.gameCenterAuthenticationComplete = NO;
    } else {
        
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        
        /*
         The authenticateWithCompletionHandler method is like all completion handler methods and runs a block
         of code after completing its task. The difference with this method is that it does not release the 
         completion handler after calling it. Whenever your application returns to the foreground after 
         running in the background, Game Kit re-authenticates the user and calls the retained completion 
         handler. This means the authenticateWithCompletionHandler: method only needs to be called once each 
         time your application is launched. This is the reason the sample authenticates in the application 
         delegate's application:didFinishLaunchingWithOptions: method instead of in the view controller's 
         viewDidLoad method.
         
         Remember this call returns immediately, before the user is authenticated. This is because it uses 
         Grand Central Dispatch to call the block asynchronously once authentication completes.
         */
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:^(NSError *error) {
            // If there is an error, do not assume local player is not authenticated. 
            if (localPlayer.isAuthenticated) {
                
                // Enable Game Center Functionality 
                self.gameCenterAuthenticationComplete = YES;

                if (! self.currentPlayerID || ! [self.currentPlayerID isEqualToString:localPlayer.playerID]) {

                    // Current playerID has changed. Create/Load a game state around the new user. 
                    self.currentPlayerID = localPlayer.playerID;
                    
                    // Load game instance for new current player, if none exists create a new.
                }
            } else {     
                // No user is logged into Game Center, run without Game Center support or user interface. 
                self.gameCenterAuthenticationComplete = NO;
            }
        }];
    }    
    
    // The user is not authenticated until the Completion Handler block is called. 
    return YES;
}

    

- (void)applicationDidEnterBackground:(UIApplication *)application  
{
    /*
     Invalidate Game Center GKAuthentication and save game state, so the game doesn't start until the GKAuthentication 
     Completion Handler is run. This prevents a new user from using the old users game state.
     */
    self.gameCenterAuthenticationComplete = NO;
}


/*
- (void)applicationWillEnterForeground:(UIApplication *)application  
{
    // Do not call authenticateWithCompletionHandler again here.Once you have set the CompletionHandler in the 
    // original call in application:didFinishLaunchingWithOptions, it will dispatch the block next time the 
    // application enters foreground. 
}
*/



#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application  
{
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc 
{
    [currentPlayerID release];
    [mainViewController release];
    [window release];
    [super dealloc];
}

@end
