/*
     File: AppDelegate.m
 Abstract: The application delegate class used for installing our UITabBarController
  Version: 1.6
 
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "AppDelegate.h"
#import "FeaturedViewController.h"

#define kCustomizeTabBar        0   // compile time option to turn on or off custom tab bar appearance

//  NSUserDefaults key values:
NSString *kTabBarOrderPrefKey   = @"kTabBarOrder";  // the ordering of the tabs

#pragma mark -

@interface AppDelegate () <UIApplicationDelegate, UITabBarControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UITabBarController *myTabBarController;

@end

#pragma mark -

@implementation AppDelegate

@synthesize myTabBarController, window;

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // add the tab bar controller's current view as a subview of the window
    myTabBarController = (UITabBarController *) self.window.rootViewController;
	
	// customize the More page's navigation bar color
	myTabBarController.moreNavigationController.navigationBar.tintColor = [UIColor grayColor];
    
    //  Adding controller from the Four.storyboard
    NSArray *classController = [myTabBarController viewControllers];
    NSMutableArray *controllerArray = [NSMutableArray arrayWithArray:classController];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Four" bundle:nil];
    UIViewController *four = [storyboard instantiateInitialViewController];
    
    [controllerArray insertObject:four atIndex:3];
    
    [myTabBarController setViewControllers:controllerArray];
	
#if kCustomizeTabBar
    // set the bar tint color for iOS 7 and later
    if ([UIToolbar instancesRespondToSelector:@selector(setBarTintColor:)])
    {
        myTabBarController.tabBar.barTintColor = [UIColor darkGrayColor];
    }
    else
    {
        // set the bar tint color for iOS 6 and earlier
        myTabBarController.tabBar.tintColor = [UIColor darkGrayColor];
    }
    
    myTabBarController.tabBar.selectedImageTintColor = [UIColor yellowColor];
    
    // note:
    // 1) you can also apply additional custom appearance to UITabBar using:
    // "backgroundImage" and "selectionIndicatorImage"
    // 2) you can also customize the appearance of individual UITabBarItems as well.
#endif
    
	// restore the tab-order from prefs
	NSArray *classNames = [[NSUserDefaults standardUserDefaults] arrayForKey:kTabBarOrderPrefKey];
	if (classNames.count > 0)
	{
		NSMutableArray *controllers = [[NSMutableArray alloc] init];
		for (NSString *className in classNames)
		{
			for (UIViewController* controller in myTabBarController.viewControllers)
			{
				NSString* controllerClassName = nil;
				
				if ([controller isKindOfClass:[UINavigationController class]])
				{
					controllerClassName = NSStringFromClass([[(UINavigationController*)controller topViewController] class]);
				}
				else
				{
					controllerClassName = NSStringFromClass([controller class]);
				}
				
				if ([className isEqualToString:controllerClassName])
				{
					[controllers addObject:controller];
					break;
				}
			}
		}
		
		if (controllers.count == myTabBarController.viewControllers.count)
		{
			myTabBarController.viewControllers = controllers;
		}
		
	}
	
	// listen for changes in view controller from the More screen
	myTabBarController.moreNavigationController.delegate = self;
    
    // choose to make one of our view controllers ("FeaturedViewController"),
    // not movable/reorderable in More's edit screen
    //
    NSMutableArray *customizeableViewControllers = (NSMutableArray *)myTabBarController.viewControllers;
    for (UIViewController *viewController in customizeableViewControllers)
    {
        if ([viewController isKindOfClass:[FeaturedViewController class]])
        {
            [customizeableViewControllers removeObject:viewController];
            break;
        }
    }
    myTabBarController.customizableViewControllers = customizeableViewControllers;
    return YES;
}

- (void)saveTabOrder
{
	// store the tab-order to preferences
	//
	NSMutableArray *classNames = [[NSMutableArray alloc] init];
	for (UIViewController *controller in myTabBarController.viewControllers)
	{
		if ([controller isKindOfClass:[UINavigationController class]])
		{
			UINavigationController *navController = (UINavigationController *)controller;
			
			[classNames addObject:NSStringFromClass([navController.topViewController class])];
		}
		else
		{
			[classNames addObject:NSStringFromClass([controller class])];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:classNames forKey:kTabBarOrderPrefKey];
	
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // this will store tab ordering.
	[self saveTabOrder];
}


#pragma mark - UINavigationControllerDelegate (More screen)

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if (viewController == (myTabBarController.moreNavigationController.viewControllers)[0])
	{
		// returned to the More page
	}
}

#pragma mark - State Restoration

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

@end