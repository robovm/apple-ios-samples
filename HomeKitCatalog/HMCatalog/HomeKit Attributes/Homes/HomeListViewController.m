/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A generic View Controller for displaying a list of homes in a home manager.
 */

#import "HomeListViewController.h"
#import "UITableView+EmptyMessage.h"
#import "HomeStore.h"

@interface HomeListViewController ()

@property (nonatomic, readwrite) HMHome *currentHome;

@end

@implementation HomeListViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.homeManager.delegate = self;
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Reset the shared home so everybody knows to close out their views.
    [self updateSelectedHome:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self registerForHomeChangedNotifications];
}

- (void)dealloc {
    [self unregisterForHomeChangedNotifications];
}

- (HMHomeManager *)homeManager {
    return [HomeStore sharedStore].homeManager;
}

/**
 *  Registers to update its home if the HomeStore updates.
 */
- (void)registerForHomeChangedNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(homeStoreDidUpdateSharedHome)
                                                 name:HomeStoreDidChangeSharedHomeNotification
                                               object:[HomeStore sharedStore]];
}

/**
 *  Unregisters from the HomeStore's notifications.
 */
- (void)unregisterForHomeChangedNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Show Home"]) {
        if (sender == self) {
            // Don't update the selected home if we sent ourselves here.
            return;
        }
        HMHome *home;
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            home = self.homeManager.homes[indexPath.row];
        } else {
            home = self.homeManager.primaryHome;
        }
        [self updateSelectedHome:home];
    }
}

/**
 *  Resets the HomeStore's shared store.
 *
 *  @param selectedHome The home selected by the user.
 */
- (void)updateSelectedHome:(HMHome *)selectedHome {
    self.currentHome = selectedHome;

    // Set the shared HomeStore home.
    [HomeStore sharedStore].home = selectedHome;
}

/**
 *  Reloads the table to fit the new homes.
 *
 *  @param manager The HomeManager that updated its home list.
 */
- (void)homeManagerDidUpdateHomes:(HMHomeManager *)manager {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

/**
 *  Reloads the table to fit the new homes.
 *
 *  @param manager The HomeManager that updated its home list.
 */
- (void)homeManager:(HMHomeManager *)manager didAddHome:(HMHome *)home {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

/**
 *  Reloads the table to fit the new homes.
 *
 *  @param manager The HomeManager that updated its home list.
 */
- (void)homeManager:(HMHomeManager *)manager didRemoveHome:(HMHome *)home {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

/**
 *  Called whenever the HomeStore changes homes. If this view controller is not currently presenting a home,
 *  it will start presenting one when the HomeStore changes.
 */
- (void)homeStoreDidUpdateSharedHome {
    if ([HomeStore sharedStore].home == self.currentHome) {
        // Only respond if we werent the ones who initiated the update.
        return;
    }
    self.currentHome = [HomeStore sharedStore].home;

    // If the HomeStore has a non-nil home, and we're currently not showing a home, show it.
    if ([HomeStore sharedStore].home) {
        if (self.navigationController.topViewController == self) {
            [self performSegueWithIdentifier:@"Show Home" sender:self];
        }
    } else {
        // Pop to the root so the user choose which home again.
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger rows = self.homeManager.homes.count;
    [self.tableView hmc_addMessage:NSLocalizedString(@"No Homes", @"No Homes") ifNecessaryForRowCount:rows];
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HomeCell" forIndexPath:indexPath];
    cell.textLabel.text = [self.homeManager.homes[indexPath.row] name];
    return cell;
}

@end
