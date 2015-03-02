/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "GeocoderDemoAppDelegate.h"

#import "ForwardViewController.h"
#import "ReverseViewController.h"
#import "DistanceViewController.h"

@implementation GeocoderDemoAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
 
    UIViewController *viewController1, *viewController2, *viewController3;
    
    viewController1 = [[ForwardViewController alloc]
                        initWithNibName:@"ForwardViewController" bundle:nil];
    viewController1.title = @"Forward";
    viewController1.tabBarItem.image = [UIImage imageNamed:@"forward"];
    UINavigationController *navController1 = [[UINavigationController alloc]
                                               initWithRootViewController:viewController1];
    
    viewController2 = [[ReverseViewController alloc]
                        initWithNibName:@"ReverseViewController" bundle:nil];
    viewController2.title = @"Reverse";
    viewController2.tabBarItem.image = [UIImage imageNamed:@"reverse"];
    UINavigationController *navController2 = [[UINavigationController alloc]
                                               initWithRootViewController:viewController2];
    
    viewController3 = [[DistanceViewController alloc]
                       initWithNibName:@"DistanceViewController" bundle:nil];
    viewController3.title = @"Distance";
    viewController3.tabBarItem.image = [UIImage imageNamed:@"distance"];
    UINavigationController *navController3 = [[UINavigationController alloc]
                                               initWithRootViewController:viewController3];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[navController1, navController2, navController3];
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
