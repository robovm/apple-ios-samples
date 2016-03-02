/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Application delegate declaration.
 */

#import "AAPLAppDelegate.h"

@implementation AAPLAppDelegate

// hide the status bar
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    application.statusBarHidden = YES;
    return YES;
}

@end
