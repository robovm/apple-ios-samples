/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The application delegate class.
 */

#import "AppDelegate.h"

@interface AppDelegate () <UINavigationControllerDelegate>
@end


@implementation AppDelegate

//| ----------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [(UINavigationController*)self.window.rootViewController setDelegate:self];
    
    return YES;
}

#pragma mark -
#pragma mark UINavigationControllerDelegate

//| ----------------------------------------------------------------------------
//  Force the navigation controller to defer to the topViewController for
//  its supportedInterfaceOrientations.  This allows some of the demos
//  to rotate into landscape while keeping others in portrait.
//
- (NSUInteger)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController
{
    return navigationController.topViewController.supportedInterfaceOrientations;
}

@end
