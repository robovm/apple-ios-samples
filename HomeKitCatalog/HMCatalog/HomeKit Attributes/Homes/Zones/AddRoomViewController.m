/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that lists rooms within a home and allows the user to add the rooms to a provided zone.
 */

#import "AddRoomViewController.h"
#import "UITableView+EmptyMessage.h"
#import "UIViewController+Convenience.h"
#import "HMHome+Properties.h"
#import "UITableView+Updating.h"

@interface AddRoomViewController () <HMHomeDelegate>

@property (nonatomic) NSMutableArray *selectedRooms;
@property (nonatomic) NSArray *displayedRooms;

@end

@implementation AddRoomViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.selectedRooms = [NSMutableArray array];
    [self resetDisplayedRooms];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.displayedRooms.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RoomCell" forIndexPath:indexPath];

    HMRoom *room = self.displayedRooms[indexPath.row];
    cell.textLabel.text = room.name;
    cell.accessoryType = [self.selectedRooms containsObject:room] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self handleRoomSelectionAtIndexPath:indexPath];
}

/**
 *  When an indexPath is selected, this function either adds or removes the selected room from the
 *  zone.
 */
- (void)handleRoomSelectionAtIndexPath:(NSIndexPath *)indexPath {
    // Get the room associated with this index.
    HMRoom *room = self.displayedRooms[indexPath.row];

    // Call the appropriate add/remove operation with the block from above.
    if ([self.selectedRooms containsObject:room]) {
        [self.selectedRooms removeObject:room];
    } else {
        [self.selectedRooms addObject:room];
    }
    [self.tableView hmc_update:^(UITableView *tableView) {
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

/**
 *  Adds the selected rooms to the zone.
 *
 *  Calls the provided completion handler once all rooms have been added.
 */
- (void)addSelectedRoomsWithCompletionHandler:(void (^)())completion {
    // Create a dispatch group for each of the room additions.
    dispatch_group_t addRoomsGroup = dispatch_group_create();
    __weak typeof(self) weakSelf = self;
    for (HMRoom *room in self.selectedRooms) {
        dispatch_group_enter(addRoomsGroup);
        [self.zone addRoom:room completionHandler:^(NSError *error) {
            if (error) {
                [weakSelf hmc_displayError:error];
            }
            dispatch_group_leave(addRoomsGroup);
        }];
    }
    dispatch_group_notify(addRoomsGroup, dispatch_get_main_queue(), completion);
}

- (IBAction)saveAndDismiss {
    __weak typeof(self) weakSelf = self;
    [self addSelectedRoomsWithCompletionHandler:^{
        [weakSelf dismiss];
    }];
}

- (IBAction)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}
/**
 *  Resets the displayedRooms list to display all of the rooms in the home
 *  except the ones already inside this zone.
 */
- (void)resetDisplayedRooms {
    self.displayedRooms = [self.home hmc_roomsNotAlreadyInZone:self.zone includingRooms:self.selectedRooms];
    [self.tableView reloadData];
}

/**
 *  Tries to find a new zone corresponding to our old zone,
 *  but if that fails, dismisses.
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
        [self resetDisplayedRooms];
    } else {
        [self dismiss];
    }
}

- (void)home:(HMHome *)home didUpdateNameForZone:(HMZone *)zone {
    if (zone == self.zone) {
        self.navigationItem.title = zone.name;
    }
}

- (void)home:(HMHome *)home didUpdateNameForRoom:(HMRoom *)room {
    [self resetDisplayedRooms];
}

- (void)home:(HMHome *)home didAddRoom:(HMRoom *)room {
    [self resetDisplayedRooms];
}

- (void)home:(HMHome *)home didRemoveRoom:(HMRoom *)room {
    [self resetDisplayedRooms];
}

@end