/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "BreadcrumbAppDelegate.h"
#import "SettingsKeys.h"

@import MapKit; // for MKUserTrackingModeNone

@implementation BreadcrumbAppDelegate

// The app delegate must implement the window @property
// from UIApplicationDelegate @protocol to use a main storyboard file.
//
@synthesize window;

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // it is important to registerDefaults as soon as possible,
    // because it can change so much of how your app behaves
    //
    NSMutableDictionary *defaultsDictionary = [[NSMutableDictionary alloc] init];
    
    // by default we track the user location while in the background
    [defaultsDictionary setObject:@YES forKey:TrackLocationInBackgroundPrefsKey];
    
    // by default we use the best accuracy setting (kCLLocationAccuracyBest)
    [defaultsDictionary setObject:@(kCLLocationAccuracyBest) forKey:LocationTrackingAccuracyPrefsKey];
    
    // by default we play a sound in the background to signify a location change
    [defaultsDictionary setObject:@YES forKey:PlaySoundOnLocationUpdatePrefsKey];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //..
    return YES;
}

@end
