/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A generic UITableViewController subclass that automatically responds to HomeKit refreshing its objects.
 */

#import "HomeKitTableViewController.h"
#import "HomeStore.h"

@interface HomeKitTableViewController ()

@end

@implementation HomeKitTableViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_homeStoreDidUpdateHomes)
                                                 name:HomeStoreDidUpdateHomesNotification
                                               object:[HomeStore sharedStore]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.home.delegate = self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (HMHome *)home {
    return [HomeStore sharedStore].home;
}

- (void)homeStoreDidUpdateHomes {
    // For most cases, subclasses will only need to
    // reload the table. More complicated views will need
    // to perform more complicated adjustment.
    [self.tableView reloadData];
}

- (void)_homeStoreDidUpdateHomes {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.home.delegate = self;
        [self homeStoreDidUpdateHomes];
    });
}

@end
