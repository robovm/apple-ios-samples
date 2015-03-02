/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Application delegate implementation.
  
 */

#import "AAPLAppDelegate.h"
#import "AAPLRootViewController.h"

@implementation AAPLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    // Configure the root view controller, and set it as the root of the navigation controller
    AAPLRootViewController* rootViewController = [[AAPLRootViewController alloc] init];
    
    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    
    [self.window setRootViewController:navigationController];
    
    return YES;
}

@end
