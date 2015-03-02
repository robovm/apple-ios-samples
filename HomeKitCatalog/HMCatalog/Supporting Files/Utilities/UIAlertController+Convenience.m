/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UIAlertController category for creating simple alerts. One prompts for a name, and one displays an error message.
 */

#import "UIAlertController+Convenience.h"

@implementation UIAlertController (Convenience)

+ (instancetype)hmc_namePromptWithAttributeType:(NSString *)attributeType placeholder:(NSString *)placeholder completion:(void (^)(NSString *name))completion {
    return [self hmc_namePromptWithAttributeType:attributeType placeholder:placeholder shortType:attributeType completion:completion];
}

+ (instancetype)hmc_namePromptWithAttributeType:(NSString *)attributeType placeholder:(NSString *)placeholder shortType:(NSString *)shortType completion:(void (^)(NSString *name))completion {
    UIAlertController *promptForNameController = [self alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"New %@", @"New item"), attributeType]
                                                                        message:NSLocalizedString(@"Enter a name.", @"Enter a name.")
                                                                 preferredStyle:UIAlertControllerStyleAlert];

    [promptForNameController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = placeholder;
        textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [promptForNameController dismissViewControllerAnimated:YES completion:nil];
    }];

    NSString *addString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Add", @"Add"), shortType];

    UIAlertAction *addNewObject = [UIAlertAction actionWithTitle:addString style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *newName = [promptForNameController.textFields.firstObject text];
        NSString *trimmedName = [newName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        // If the user didn't input anything useful,
        // don't even bother with the completion handler.
        if (trimmedName.length > 0) {
            completion(trimmedName);
        }
        [promptForNameController dismissViewControllerAnimated:YES completion:nil];
    }];

    [promptForNameController addAction:cancel];
    [promptForNameController addAction:addNewObject];

    return promptForNameController;
}

+ (instancetype)hmc_simpleAlertControllerWithBody:(NSString *)body {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error")
                                                                        message:body
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okayAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", @"Okay")
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           [controller dismissViewControllerAnimated:YES completion:nil];
                                                       }];
    [controller addAction:okayAction];
    return controller;
}

@end
