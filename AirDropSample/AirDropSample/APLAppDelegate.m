/*
 
     File: APLAppDelegate.m
 Abstract: Application Delegate that handles app start up and the AirDropped received files.
  Version: 1.0
 
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

#import "APLAppDelegate.h"
#import "APLProfileTableViewController.h"
#import "APLSharingTypesTableViewController.h"
#import "APLProfile.h"
#import "APLUtilities.h"

NSString * const kCustomScheme = @"adcs";
NSString * const kMainStoryboardName = @"Main";
NSString * const kProfileViewControllerIdentifier = @"ProfileViewController";
NSString * const kDocumentsInboxFolder = @"Inbox";

//Custom Notifications used when receiving content
NSString * const DisplayingSaveWindowNotification = @"DisplayingSaveWindow";
NSString * const SavedReceivedProfilesNotification = @"SavedReceivedProfiles";
NSString * const SavedCustomURLNotification = @"SavedCustomURL";

NSString * const kSavedReceivedProfilesFileNamesKey = @"SavedFileNames";


@interface APLAppDelegate()

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) APLSharingTypesTableViewController *sharingTypesViewController;

@property (strong, nonatomic) NSMutableArray *receivedProfileQueue;
@property (strong, nonatomic) UINavigationController *receivedProfilesNavigationController;
@property (strong, nonatomic) NSMutableArray *savedFileNames;

@property (strong, nonatomic) UIWindow *saveReceivedWindow;

@end


@implementation APLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.navigationController = (UINavigationController *)self.window.rootViewController;
    self.sharingTypesViewController = self.navigationController.viewControllers[0];
    
    self.savedFileNames = [NSMutableArray array];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //Check for orphaned files in the inbox
    [self handleDocumentsInbox];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (url) {
        if (url.scheme && [url.scheme isEqualToString:kCustomScheme]) {
            
            //Save the received profile and notify observers
            [APLUtilities saveCustomURL:url];
            [[NSNotificationCenter defaultCenter] postNotificationName:SavedCustomURLNotification object:nil];
            
            //Show custom URL view controller if currently in the sharing types table, otherwise don't, the user could be in the middle of something
            if ([self.navigationController visibleViewController] == self.sharingTypesViewController && !self.saveReceivedWindow) {
                [self.sharingTypesViewController showCustomURLView];
            }
        }
        else
        {
            APLProfile *profile = [APLUtilities securelyUnarchiveProfileWithFile:[url path]];
        
            if (profile) {
                
                //Enqueue profile incase another one is already being handled
                [self enqueueProfile:profile];
            }
            
            //Clean up inbox
            [self removeInboxItem:url];
        }
    }
    return YES;
}

#pragma mark - Document Inbox Handling

- (void)handleDocumentsInbox
{
    //All incoming files are stored in Documents/Inbox/
    NSString *inboxPath = [[APLUtilities documentsDirectory] stringByAppendingPathComponent:kDocumentsInboxFolder];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *inboxFiles = [fileManager contentsOfDirectoryAtPath:inboxPath error:nil];
    
    for (NSString *path in inboxFiles) {
        
        //Append file name to path and create URL
        NSURL *url = [NSURL fileURLWithPath:[inboxPath stringByAppendingPathComponent:path]];
        [self application:[UIApplication sharedApplication] openURL:url sourceApplication:@"" annotation:nil];
    }
}

- (void)removeInboxItem:(NSURL *)itemURL
{
    //Clean up the inbox once the file has been processed
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[itemURL path] error:&error];
    
    if (error) {
        NSLog(@"ERROR: Inbox file could not be deleted");
    }
}


#pragma mark - AirDropped Profile Receiving

/****************************************************
 Handling Incoming Profiles
 
 When the app receives a profile it displays it own view to give a chance to look at the profile and decide if they want it.
 
 There are two considerations when displaying a save view for the user.
 
 First the user could be doing an important task that this save view is going to interrupt. To account for this the app displays the save view in its own window, which will not disturb the main window's contents.
 
 Second while the user is deciding if they want to keep the profile, another one could arrive. Because of this possibility, this app keeps a queue of arriving profiles.
 
 When the first profile arrives a navigation controller is created to display that profile in a APLProfileViewController.
 
 When each subsequent profile arrives they are enqueued. Once the user decides whether or not to save the displayed profile, the next profile is pushed onto the navigation controller's stack.
 
 ******************************************************/

- (void)enqueueProfile:(APLProfile *)profile
{
    if (!_receivedProfileQueue) {
        _receivedProfileQueue = [NSMutableArray array];
    }
    
    @synchronized(self.receivedProfileQueue)
    {
        [self.receivedProfileQueue addObject:profile];
        
        //If first recevied, profile present
        if (self.receivedProfileQueue.count == 1) {
            [self presentFirstProfile];
        }
    }
}

- (APLProfile *)dequeueProfile
{
    @synchronized(self.receivedProfileQueue) {
        APLProfile *profile = nil;
        if (self.receivedProfileQueue.count > 0) {
            profile = [self.receivedProfileQueue firstObject];
            [self.receivedProfileQueue removeObject:profile];
        }
        return profile;
    }
}

- (void)presentFirstProfile
{
    APLProfile *profile = [self.receivedProfileQueue firstObject];
    
    if (profile) {
        
        //Notify observers that the save window will appear
        [[NSNotificationCenter defaultCenter] postNotificationName:DisplayingSaveWindowNotification object:nil];
        
        //Create Window
        self.saveReceivedWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [self.saveReceivedWindow setWindowLevel:UIWindowLevelNormal];
        
        //Create profileViewController to display received profile
        APLProfileViewController *profileViewController = [self createProfileViewControllerForProfile:profile];
        
        //Create a navigation controller to handle displaying multiple incoming profiles
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:profileViewController];
        self.receivedProfilesNavigationController = nav;
        [self.saveReceivedWindow setRootViewController:nav];
        
        //Set frame below the screen
        CGRect originalFrame = self.saveReceivedWindow.frame;
        CGRect newFrame = self.saveReceivedWindow.frame;
        newFrame.origin.y = newFrame.origin.y + newFrame.size.height;
        self.saveReceivedWindow.frame = newFrame;
        
        //Create animation to have window slide up from bottom of the screen
        [self.saveReceivedWindow makeKeyAndVisible];
        [UIView animateWithDuration:0.4f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.saveReceivedWindow.frame = originalFrame;
                         }
                         completion:nil];
    }
}


- (void)presentNextProfile
{
    APLProfile *profile = [self.receivedProfileQueue firstObject];
    if (profile) {
        
        APLProfileViewController *profileViewController = [self createProfileViewControllerForProfile:profile];
        
        //Make sure navigation controller exists
        if (self.receivedProfilesNavigationController) {
            [self.receivedProfilesNavigationController pushViewController:profileViewController animated:YES];
        }
        
     }
    else if (self.receivedProfilesNavigationController) //Queue is empty
    {
        //Animate the window away (slide down)
        [UIView animateWithDuration:0.4f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [self.saveReceivedWindow resignKeyWindow];
                             
                             CGRect newFrame = self.saveReceivedWindow.frame;
                             newFrame.origin.y = newFrame.origin.y + newFrame.size.height;;
                             self.saveReceivedWindow.frame = newFrame;
                         }
                         completion:^(BOOL finished) {
                             
                             self.saveReceivedWindow = nil;
                             self.receivedProfilesNavigationController = nil;
                             
                             //Only show profile table if at least one profile was saved
                             if ([self.savedFileNames count] > 0) {
                                 
                                 NSDictionary *userInfo = @{kSavedReceivedProfilesFileNamesKey : [self.savedFileNames copy]};
                                 
                                 //Notify observers at least one profile was saved
                                 [[NSNotificationCenter defaultCenter] postNotificationName:SavedReceivedProfilesNotification object:nil userInfo:userInfo];
                                 
                                 //Show profile table if currently in the sharing types table, otherwise don't, the user could be in the middle of something
                                 if ([self.navigationController visibleViewController] == self.sharingTypesViewController) {
                                     [self.sharingTypesViewController showProfilesTable];
                                 }
                                 
                                 [self.savedFileNames removeAllObjects];
                             }
                         }];
    }
}

- (void)saveProfile:(id)sender
{
    APLProfile *profile = [self dequeueProfile];
    
    if (profile) {
        //Save profile to persistent file
        [APLUtilities saveProfile:profile];
        
        [self.savedFileNames addObject:[profile filename]];
    }
    
    [self presentNextProfile];
}

- (void)discardProfile:(id)sender
{
    [self dequeueProfile];
    [self presentNextProfile];
}

- (APLProfileViewController *)createProfileViewControllerForProfile:(APLProfile *)profile
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kMainStoryboardName bundle:nil];
    APLProfileViewController *profileViewController = [sb instantiateViewControllerWithIdentifier:kProfileViewControllerIdentifier];
    profileViewController.profile = profile;
    profileViewController.interactive = NO;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Discard"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(discardProfile:)];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                target:self
                                                                                action:@selector(saveProfile:)];
    
    profileViewController.navigationItem.leftBarButtonItem = cancelButton;
    profileViewController.navigationItem.rightBarButtonItem = saveButton;
    
    return profileViewController;
}

@end
