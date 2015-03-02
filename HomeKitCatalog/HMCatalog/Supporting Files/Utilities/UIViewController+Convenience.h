/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UIViewController category for displaying errors on the main thread.
 */

@import UIKit;

@interface UIViewController (Convenience)

/**
 *  Displays a UIAlertController on the main thread with the error's localizedTranslation at the body.
 *
 *  @param error The error to display.
 */
- (void)hmc_displayError:(NSError *)error;

/**
 *  Presents a simple UIAlertController with a textField, set up to
 *  accept a name. Once the name is entered, the completion handler will
 *  be called and the name will be passed in.
 *
 *  @param attributeType The kind of object being added
 *  @param placeholder   A sample name for the attribute.
 *  @param completion    The block to run when the user taps the add button.
 */
- (void)hmc_presentAddAlertWithAttributeType:(NSString *)attributeType placeholder:(NSString *)placeholder completion:(void (^)(NSString *))completion;

/**
 *  Presents a simple UIAlertController with a textField, set up to
 *  accept a name. Once the name is entered, the completion handler will
 *  be called and the name will be passed in.
 *
 *  @param attributeType The kind of object being added
 *  @param placeholder   A sample name for the attribute.
 *  @param shortType     A shortened name of the attribute.
 *  @param completion    The block to run when the user taps the add button.
 */
- (void)hmc_presentAddAlertWithAttributeType:(NSString *)attributeType placeholder:(NSString *)placeholder shortType:(NSString *)shortType completion:(void (^)(NSString *))completion;

@end
