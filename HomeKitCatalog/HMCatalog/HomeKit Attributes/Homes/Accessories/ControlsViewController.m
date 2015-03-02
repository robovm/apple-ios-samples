/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller which displays a list of HMServices, separated by Service Type.
 */

#import "ControlsViewController.h"
#import "CharacteristicsViewController.h"
#import "ControlsTableViewDataSource.h"
#import "AccessoryUpdateController.h"
#import "AccessoryBrowserViewController.h"
#import "HomeStore.h"

@interface ControlsViewController () <HMHomeManagerDelegate>

@property (nonatomic) ControlsTableViewDataSource *tableViewDataSource;
@property (nonatomic) AccessoryUpdateController *cellController;

@end

@implementation ControlsViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    self.cellController = [AccessoryUpdateController new];
    self.tableViewDataSource = [ControlsTableViewDataSource dataSourceForTableView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.navigationItem.title = self.home.name;
    [self enableAddButtonIfNecessary];
    [self.tableViewDataSource reloadTable];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Show Service"]) {
        HMService *service = [self.tableViewDataSource selectedService];
        CharacteristicsViewController *detailVC = segue.destinationViewController;
        detailVC.service = service;
        detailVC.cellDelegate = self.cellController;
    }
}

- (void)enableAddButtonIfNecessary {
    // Don't enable the add button if we don't have a home.
    self.navigationItem.rightBarButtonItem.enabled = (self.home != nil);
}

@end
