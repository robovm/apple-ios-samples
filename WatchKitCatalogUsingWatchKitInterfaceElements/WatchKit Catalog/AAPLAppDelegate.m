/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The application delegate which creates the window and root view controller.
 */

#import "AAPLAppDelegate.h"

@implementation AAPLAppDelegate

- (void)applicationDidFinishLaunching:(nonnull UIApplication *)application {
    if ([WCSession isSupported]) {
        [WCSession defaultSession].delegate = self;
        [[WCSession defaultSession] activateSession];
    }
}

- (void)session:(nonnull WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)message replyHandler:(nonnull void (^)(NSDictionary<NSString *,id> * __nonnull))replyHandler {
    /*
         Because this method is likely to be called when the app is in the
         background, begin a background task. Starting a background task ensures
         that your app is not suspended before it has a chance to send its reply.
     */
    
    UIApplication *application = [UIApplication sharedApplication];
    
    __block UIBackgroundTaskIdentifier identifier = UIBackgroundTaskInvalid;
    // The "endBlock" ensures that the background task is ended and the identifier is reset.
    dispatch_block_t endBlock = ^ {
        if (identifier != UIBackgroundTaskInvalid) {
            [application endBackgroundTask:identifier];
        }
        identifier = UIBackgroundTaskInvalid;
    };
    
    identifier = [application beginBackgroundTaskWithExpirationHandler:endBlock];
    
    // Re-assign the "reply" block to include a call to "endBlock" after "reply" is called.
    replyHandler = ^(NSDictionary *replyInfo) {
        replyHandler(replyInfo);
        
        endBlock();
    };
    
    // Receives text input result from the WatchKit app extension.
    NSLog(@"Message: %@", message);
    
    // Sends a confirmation message to the WatchKit app extension that the text input result was received.
    replyHandler(@{@"Confirmation" : @"Text was received."});
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    NSLog(@"Handoff dictionary: %@", userActivity.userInfo);
    
    return YES;
}

@end
