/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UIViewController category for displaying errors on the main thread.
 */

#import "UIViewController+Convenience.h"
#import "UIAlertController+Convenience.h"
#import "NSError+HomeKit.h"

@implementation UIViewController (Convenience)

- (void)hmc_displayError:(NSError *)error {
    // Log the error to the console if the user cancelled or if we're already displaying an error.
    if (self.presentedViewController || error.code == HMErrorCodeOperationCancelled || error.code == HMErrorCodeUserDeclinedAddingUser) {
        NSLog(@"%@", error.hmc_localizedTranslation);
        return;
    }
    [self hmc_displayMessage:error.hmc_localizedTranslation];
}

- (void)hmc_displayMessage:(NSString *)message {
    UIAlertController *errorController = [UIAlertController hmc_simpleAlertControllerWithBody:message];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"%@", message);
        [self presentViewController:errorController animated:YES completion:nil];
    });
}

- (void)hmc_presentAddAlertWithAttributeType:(NSString *)attributeType placeholder:(NSString *)placeholder completion:(void (^)(NSString *))completion {
    [self hmc_presentAddAlertWithAttributeType:attributeType placeholder:placeholder shortType:attributeType completion:completion];
}

- (void)hmc_presentAddAlertWithAttributeType:(NSString *)attributeType placeholder:(NSString *)placeholder shortType:(NSString *)shortType completion:(void (^)(NSString *))completion {
    UIAlertController *alertController = [UIAlertController hmc_namePromptWithAttributeType:attributeType
                                                                                placeholder:placeholder
                                                                                  shortType:shortType
                                                                                 completion:completion];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end