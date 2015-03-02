/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that lists the roms within a provided zone.
 */

#import "ZoneViewController.h"
#import "RoomViewController.h"
#import "AddRoomViewController.h"
#import "UIViewController+Convenience.h"
#import "UITableView+Updating.h"
#import "HMHome+Properties.h"

@interface ZoneViewController () <HMHomeDelegate>

@end

@implementation ZoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = self.zone.name;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

/**
 *  Tries to find a new zone matching the old one.
 *  If it fails, pop the navigation stack.
 */
- (void)homeStoreDidUpdateHomes {
    HMZone *newZone = nil;
    for (HMZone *zone in self.home.zones) {
        if ([zone.name isEqualToString:self.zone.name]) {
            newZone = zone;
        }
    }
    self.zone = newZone;
    if (self.zone) {
        [super homeStoreDidUpdateHomes];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Table view data source

- (BOOL)indexPathIsAdd:(NSIndexPath *)indexPath {
    return indexPath.row == self.zone.rooms.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.zone.rooms.count + 1; // for the 'Add' row.
}

/**
 *  @return a list of rooms not already added to this zone.
 */
- (NSArray *)filteredRooms {
    return [self.home hmc_roomsNotAlreadyInZone:self.zone includingRooms:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self indexPathIsAdd:indexPath]) {
        NSString *reuseIdentifier = @"AddCell";
        if ([self filteredRooms].count == 0) {
            reuseIdentifier = @"DisabledAddCell";
        }
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
        return cell;
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RoomCell" forIndexPath:indexPath];

    HMRoom *room = self.zone.rooms[indexPath.row];
    cell.textLabel.text = room.name;

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ![self indexPathIsAdd:indexPath];
}

/**
 *  Removes a room from the zone.
 */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.zone removeRoom:self.zone.rooms[indexPath.row] completionHandler:^(NSError *error) {
            if (error) {
                [self hmc_displayError:error];
                return;
            }
            [tableView hmc_update:^(UITableView *tableView) {
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }];
            [self reloadAddRow];
        }];
    }
}

- (void)reloadAddRow {
    NSIndexPath *addRowIndexPath = [NSIndexPath indexPathForRow:self.zone.rooms.count inSection:0];
    [self.tableView hmc_update:^(UITableView *tableView) {
        [tableView reloadRowsAtIndexPaths:@[addRowIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Add Rooms"]) {
        AddRoomViewController *addRoomVC = (AddRoomViewController *)[segue.destinationViewController topViewController];
        addRoomVC.zone = self.zone;
    }
}

#pragma mark - HMHomeDelegate methods

- (void)home:(HMHome *)home didUpdateNameForZone:(HMZone *)zone {
    self.navigationItem.title = self.zone.name;
}

- (void)home:(HMHome *)home didRemoveZone:(HMZone *)zone {
    if (zone == self.zone) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)home:(HMHome *)home didRemoveRoom:(HMRoom *)room fromZone:(HMZone *)zone {
    [self.tableView reloadData];
}

- (void)home:(HMHome *)home didAddRoom:(HMRoom *)room toZone:(HMZone *)zone {
    [self.tableView reloadData];
}

@end
