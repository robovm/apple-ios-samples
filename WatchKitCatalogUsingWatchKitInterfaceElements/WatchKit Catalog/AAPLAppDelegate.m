/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The application delegate which creates the window and root view controller.
 */

#import "AAPLAppDelegate.h"

@implementation AAPLAppDelegate

- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply {
    /*
        Because this method is likely to be called when the app is in the
        background, begin a background task. Starting a background task ensures
        that your app is not suspended before it has a chance to send its reply.
    */

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
    reply = ^(NSDictionary *replyInfo) {
        reply(replyInfo);
        
        // This dispatch_after of 2 seconds is only needed on iOS 8.2. On iOS 8.3+, it is not needed. You can call endBlock() by itself.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
            endBlock();
        });
    };
    
    // Receives text input result from the WatchKit app extension.
    NSLog(@"User Info: %@", userInfo);
    
    // Sends a confirmation message to the WatchKit app extension that the text input result was received.
    reply(@{@"Confirmation" : @"Text was received."});
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    NSLog(@"Handoff dictionary: %@", userActivity.userInfo);
    
    return YES;
}

@end
