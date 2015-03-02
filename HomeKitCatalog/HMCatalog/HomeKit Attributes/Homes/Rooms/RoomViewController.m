/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that lists the accessories within a room.
 */

#import "RoomViewController.h"
#import "ModifyAccessoryViewController.h"
#import "NSIndexPath+ArrayIndex.h"
#import "UIViewController+Convenience.h"
#import "UITableView+EmptyMessage.h"
#import "UITableView+Updating.h"
#import "HMHome+Properties.h"

@interface RoomViewController () <HMHomeDelegate, HMAccessoryDelegate>

@end

@implementation RoomViewController

#pragma mark - View Controller Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = self.room.name;
    [self assignAccessoryDelegates];
    [self.tableView reloadData];
}

/**
 *  Tries to find a new room matching the old room,
 *  but if it fails, it pops the navigation stack.
 */
- (void)homeStoreDidUpdateHomes {
    HMRoom *newRoom = nil;
    for (HMRoom *room in self.home.hmc_allRooms) {
        if ([room.name isEqualToString:self.room.name]) {
            newRoom = room;
        }
    }
    self.room = newRoom;
    if (self.room) {
        [self.tableView reloadData];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger rows = self.room.accessories.count;
    NSString *title = NSLocalizedString(@"No Accessories", @"No Accessories");
    [tableView hmc_addMessage:title ifNecessaryForRowCount:rows];
    return rows;
}

/**
 *  Disallow removing homes from rooms if it's in the default room.
 */
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (self.room != self.home.roomForEntireHome);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HMAccessory *accessory = self.room.accessories[indexPath.row];
    NSString *reuseIdentifier = @"AccessoryCell";
    if (!accessory.reachable) {
        reuseIdentifier = @"UnreachableAccessoryCell";
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    accessory.delegate = self;
    cell.textLabel.text = accessory.name;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return nil;
    }
    return NSLocalizedString(@"Accessories", @"Accessories");
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"Unassign", @"Unassign");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self unassignAccessoryAtIndexPath:indexPath];
    }
}

#pragma mark - HomeKit-related convenience methods.

/**
 *  Assigns an accessory to the default room.
 *
 *  @param indexPath The indexPath of the accessory to reassign.
 */
- (void)unassignAccessoryAtIndexPath:(NSIndexPath *)indexPath {
    HMAccessory *accessory = self.room.accessories[indexPath.row];
    [self.home assignAccessory:accessory toRoom:self.home.roomForEntireHome completionHandler:^(NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            return;
        }
        [self didReassignAccessoryAtIndexPath:indexPath];
    }];
}

/**
 *  Reloads the row associated with an accessory.
 *
 *  @param accessory The accessory to reload.
 */
- (void)didModifyAccessory:(HMAccessory *)accessory {
    NSIndexPath *path = [NSIndexPath hmc_indexPathOfObject:accessory inArray:self.room.accessories];
    if (!path) {
        return;
    }
    [self.tableView hmc_update:^(UITableView *tableView) {
        [tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

/**
 *  Removes the row associated with the indexPath passed in.
 *
 *  @param indexPath The indexPath to reload.
 */
- (void)didReassignAccessoryAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return;
    }
    [self.tableView hmc_update:^(UITableView *tableView) {
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

#pragma mark - Navigation

/**
 *  Blocks access to unreachable accessories.
 */
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    HMAccessory *accessory = self.room.accessories[indexPath.row];
    return accessory.reachable;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Modify Accessory"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        ModifyAccessoryViewController *addAccessoryViewController = (ModifyAccessoryViewController *)[segue.destinationViewController topViewController];
        addAccessoryViewController.accessory = self.room.accessories[indexPath.row];
    }
}

/**
 *  Assigns each accessory's delegate to this controller.
 */
- (void)assignAccessoryDelegates {
    for (HMAccessory *accessory in self.room.accessories) {
        accessory.delegate = self;
    }
}

#pragma mark - HMHomeDelegate methods

- (void)home:(HMHome *)home didUpdateNameForRoom:(HMRoom *)room {
    self.navigationItem.title = self.room.name;
}

- (void)home:(HMHome *)home didRemoveRoom:(HMRoom *)room {
    if (room == self.room) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - HMAccessoryDelegate methods

- (void)accessoryDidUpdateReachability:(HMAccessory *)accessory {
    [self didModifyAccessory:accessory];
}

- (void)accessoryDidUpdateName:(HMAccessory *)accessory {
    [self didModifyAccessory:accessory];
}

@end
