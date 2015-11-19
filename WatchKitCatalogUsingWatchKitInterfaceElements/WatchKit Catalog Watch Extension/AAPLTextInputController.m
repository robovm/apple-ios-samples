/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller demonstrates using the Text Input Controller.
 */

@import WatchConnectivity;

#import "AAPLTextInputController.h"

@implementation AAPLTextInputController

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    NSLog(@"%@ will activate", self);
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    NSLog(@"%@ did deactivate", self);
}

- (IBAction)replyWithTextInputController {
    // Using the WKTextInputMode enum, you can specify which aspects of the Text Input Controller are shown when presented.
    [self presentTextInputControllerWithSuggestions:@[@"Yes", @"No", @"Maybe"] allowedInputMode:WKTextInputModeAllowEmoji completion:^(NSArray *results) {
        NSLog(@"Text Input Results: %@", results);
        
        if (results.firstObject != nil) {
            // Sends a non-nil result to the parent iOS application.
            [[WCSession defaultSession] sendMessage:@{@"TextInput" : results.firstObject} replyHandler:^(NSDictionary<NSString *,id> * __nonnull replyMessage) {
                NSLog(@"Reply Info: %@", replyMessage);
            } errorHandler:^(NSError * __nonnull error) {
                NSLog(@"Error: %@", [error localizedDescription]);
            }];
        }
    }];
}

@end



