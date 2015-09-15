/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Application Delegate
*/

#import "MultichannelMixerTestDelegate.h"

@implementation MultichannelMixerTestDelegate

@synthesize window, navigationController, myViewController;

#pragma mark -Audio Session Interruption Notification

- (void)handleInterruption:(NSNotification *)notification
{
    UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    
    NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
	   
    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        [self->myViewController stopForInterruption];
    }
    
    if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        // make sure to activate the session
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
    
        if (nil != error) NSLog(@"AVAudioSession set active failed with error: %@", error);
    }
}

#pragma mark -Audio Session Route Change Notification

- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
    case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        NSLog(@"     NewDeviceAvailable");
        break;
    case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        NSLog(@"     OldDeviceUnavailable");
        break;
    case AVAudioSessionRouteChangeReasonCategoryChange:
        NSLog(@"     CategoryChange");
        NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
        break;
    case AVAudioSessionRouteChangeReasonOverride:
        NSLog(@"     Override");
        break;
    case AVAudioSessionRouteChangeReasonWakeFromSleep:
        NSLog(@"     WakeFromSleep");
        break;
    case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
        NSLog(@"     NoSuitableRouteForCategory");
        break;
    default:
        NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {

    // override point for customization after application launch
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    window = [[UIWindow alloc] initWithFrame:screenBounds];
    
    // Add the view controller's view to the window and display
    self.window.rootViewController = navigationController;
    [window makeKeyAndVisible];
    
    try {
         NSError *error = nil;
        
        // Configure the audio session
        AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
        
        // our default category -- we change this for conversion and playback appropriately
        [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set audio category");

        NSTimeInterval bufferDuration = .005;
        [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set IOBufferDuration");
        
        double hwSampleRate = 44100.0;
        [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set preferred sample rate");
        
        // add interruption handler
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:) 
                                                     name:AVAudioSessionInterruptionNotification 
                                                   object:sessionInstance];
        
        // we don't do anything special in the route change notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRouteChange:)
                                                     name:AVAudioSessionRouteChangeNotification 
                                                   object:sessionInstance];
        
        // activate the audio session
        [sessionInstance setActive:YES error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set audio session active\n");
        
        // just print out the sample rate
        printf("Hardware Sample Rate: %.1f Hz\n", sessionInstance.sampleRate);
    } catch (CAXException e) {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
        printf("You probably want to fix this before continuing!");
    }

    // initialize the mixerController object
    [myViewController.mixerController initializeAUGraph];
    
    // set up the mixer according to our interface defaults
    [myViewController setUIDefaults];
}

- (void)dealloc {
    self.window = nil;
    self.navigationController = nil;
    self.myViewController = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionInterruptionNotification 
                                                  object:[AVAudioSession sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification 
                                                  object:[AVAudioSession sharedInstance]];
    
    [super dealloc];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
     
    printf("applicationDidEnterBackground\n");
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
     
     printf("applicationWillEnterForeground\n");
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    printf("applicationWillResignActive\n");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    printf("applicationDidBecomeActive\n");
}

@end
