/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableView category that displays a message in the middle of the table if it's empty.
 */

@import UIKit;

@interface UITableView (EmptyMessage)

/**
 *  Sets the receiver's backgroundView to a UILabel displaying the message provided, or clears
 *  it if the row count is not 0.
 *
 *  @param message  The message to display if rowCount is 0.
 *  @param rowCount The number of rows in the table. If it is 0, then the message
                    will be displayed in the middle of the table, in gray.
 */
- (void)hmc_addMessage:(NSString *)message ifNecessaryForRowCount:(NSUInteger)rowCount;

@end
