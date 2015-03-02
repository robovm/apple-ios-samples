/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The delegate for the application.
  
 */

#import "AAPLAppDelegate.h"
#import "AAPLStartViewController.h"
#import "AAPLStyleUtilities.h"

@implementation AAPLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    AAPLStartViewController *startViewController = [[AAPLStartViewController alloc] init];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:startViewController];
    navigationController.navigationBar.tintColor = [AAPLStyleUtilities foregroundColor];
    self.window.rootViewController = navigationController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

@end
