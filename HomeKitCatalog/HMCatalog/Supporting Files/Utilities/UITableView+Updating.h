/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableView category that provides a callback after starting but before finishing updates.
 */

@import UIKit;

@interface UITableView (Updating)

/**
 *  Calls the provided updateBlock on the main thread between calls to <code>beginUpdates</code>
 *  and <code>endUpdates</code>.
 *
 *  @param updateBlock A block that would normally appear between calls to <code>beginUpdates</code>
 *  and <code>endUpdates</code>.
 */
- (void)hmc_update:(void (^)(UITableView *tableView))updateBlock;

@end
