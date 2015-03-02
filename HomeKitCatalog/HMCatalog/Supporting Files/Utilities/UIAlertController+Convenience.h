/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UIAlertController category for creating simple alerts. One prompts for a name, and one displays an error message.
 */

@import UIKit;

@interface UIAlertController (Convenience)

/**
 *  A simple UIAlertController that prompts for a name, then runs a completion block passing in the name.
 *
 *  @param attributeType The type of object that will be named.
 *  @param placeholder   The placeholder text of the text field.
 *  @param completion    A block to call, passing in the provided text.
 *
 *  @return A UIAlertController instance with a UITextField, cancel button, and add button.
 */
+ (instancetype)hmc_namePromptWithAttributeType:(NSString *)attributeType placeholder:(NSString *)placeholder completion:(void (^)(NSString *name))completion;

/**
 *  A simple UIAlertController that prompts for a name, then runs a completion block passing in the name.
 *
 *  @param attributeType The type of object that will be named.
 *  @param placeholder   The placeholder text of the text field.
 *  @param shortType     A short name for the attributeType, that will be included in the 'Add' button.
 *  @param completion    A block to call, passing in the provided text.
 *
 *  @return A UIAlertController instance with a UITextField, cancel button, and add button.
 */
+ (instancetype)hmc_namePromptWithAttributeType:(NSString *)attributeType placeholder:(NSString *)placeholder shortType:(NSString *)shortType completion:(void (^)(NSString *name))completion;

/**
 *  A simple UIAlertController made to show an error message that's passed in.
 *
 *  @param body The body of the alert.
 *
 *  @return A UIAlertController with an 'Okay' button.
 */
+ (instancetype)hmc_simpleAlertControllerWithBody:(NSString *)body;

@end
