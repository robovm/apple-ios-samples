/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableView category that displays a message in the middle of the table if it's empty.
 */

#import "UITableView+EmptyMessage.h"

@implementation UITableView (EmptyMessage)

- (void)hmc_addMessage:(NSString *)message ifNecessaryForRowCount:(NSUInteger)rowCount {
    if (rowCount == 0) {
        // Display a message when the table is empty
        UILabel *messageLabel = [UILabel new];

        messageLabel.text = message;
        messageLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        messageLabel.textColor = [UIColor lightGrayColor];
        messageLabel.textAlignment = NSTextAlignmentCenter;
        [messageLabel sizeToFit];

        self.backgroundView = messageLabel;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        self.backgroundView = nil;
        self.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
}

@end
