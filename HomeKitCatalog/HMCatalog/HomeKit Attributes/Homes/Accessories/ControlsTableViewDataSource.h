/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableViewDataSource that populates the table in ControlsViewController.
 */
@import UIKit;
@import HomeKit;

@interface ControlsTableViewDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, readonly) HMService *selectedService;

- (void)reloadTable;
+ (instancetype)dataSourceForTableView:(UITableView *)tableView;

@end
