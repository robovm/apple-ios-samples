/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Simple app delegate.
*/

#import "AppDelegate.h"

#import "ViewController.h"
#import "CircleLayout.h"

@interface AppDelegate ()
@property (strong, nonatomic) ViewController *viewController;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _viewController = [[ViewController alloc] initWithCollectionViewLayout:[[CircleLayout alloc] init]];
    
    self.window.rootViewController = self.viewController;

    [self.window makeKeyAndVisible];
    return YES;
}


@end
