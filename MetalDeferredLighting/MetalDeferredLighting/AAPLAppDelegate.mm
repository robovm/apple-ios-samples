/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Application delegate for Metal Sample Code. Creates the renderer at app launch and sets it as the view and controller delegate. starts and stops game loop as needed.
  
 */

#import "AAPLAppDelegate.h"
#import "AAPLView.h"
#import "AAPLViewController.h"
#import "AAPLRenderer.h"

@implementation AAPLAppDelegate
{
@private
    AAPLRenderer *_renderer;
}

// Override point for customization after application launch.
- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    AAPLViewController *controller = (AAPLViewController *)self.window.rootViewController;
    
    if(!controller)
    {
        NSLog(@">> ERROR: Failed creating a view controller!");
        
        return NO;
    }
    
    _renderer = [AAPLRenderer new];
    
    if(!_renderer)
    {
        NSLog(@">> ERROR: Failed creating a renderer!");
        
        return NO;
    }
    
    controller.delegate = _renderer;
    
    AAPLView *renderView = (AAPLView *)controller.view;
    
    if(!renderView)
    {
        NSLog(@">> ERROR: Failed creating a renderer view!");
        
        return NO;
    }
    
    renderView.delegate = _renderer;
    
    // load all renderer assets and configure view before starting game loop
    [_renderer configure:renderView];
    
    // run the game loop
    [controller dispatch];
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    AAPLViewController *controller = (AAPLViewController *)self.window.rootViewController;
    
    [controller stop];
    
    _renderer = nil;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state.
    // This can occur for certain types of temporary interruptions (such as an
    // incoming phone call or SMS message) or when the user quits the application
    // and it begins the transition to the background state.
    
    // Use this method to pause ongoing tasks, disable timers, and throttle down
    // OpenGL ES frame rates. Games should use this method to pause the game.
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate
    // timers, and store enough application state information to restore your
    // application to its current state in case it is terminated later.
    
    // If your application supports background execution, this method is called
    // instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state;
    // here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application
    // was inactive. If the application was previously in the background, optionally
    // refresh the user interface.
}

@end
