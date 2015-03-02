/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableView category that provides a callback after starting but before finishing updates.
 */

#import "UITableView+Updating.h"

@implementation UITableView (Updating)

- (void)hmc_update:(void (^)(UITableView *tableView))updateBlock {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self beginUpdates];
        updateBlock(self);
        [self endUpdates];
    });
}

@end
