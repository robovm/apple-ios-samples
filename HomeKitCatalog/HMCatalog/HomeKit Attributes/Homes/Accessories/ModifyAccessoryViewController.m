/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that allows for renaming, reassigning, and identifying accessories before and after they've been added to a home.
 */

#import "ModifyAccessoryViewController.h"
#import "UIViewController+Convenience.h"
#import "HMHome+Properties.h"
#import "UITableView+Updating.h"
#import "NSError+HomeKit.h"

typedef NS_ENUM(NSUInteger, AddAccessoryTableViewSection) {
    AddAccessoryTableViewSectionName = 0,
    AddAccessoryTableViewSectionRooms,
    AddAccessoryTableViewSectionIdentify,
};

@interface ModifyAccessoryViewController () <HMHomeDelegate, HMAccessoryDelegate>

// We need to maintain a separate list of rooms because we're
// going to add self.home.roomForEntireHome to the list of rooms.
@property (nonatomic) NSArray *rooms;

@property (nonatomic) NSIndexPath *selectedIndexPath;
@property (nonatomic) HMRoom *selectedRoom;
@property (nonatomic) IBOutlet UITextField *nameField;
@property (nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (nonatomic) UIActivityIndicatorView *activityIndicator;

@property (nonatomic) dispatch_group_t saveAccessoryGroup;

@property (nonatomic) BOOL editingExistingAccessory;
@property (nonatomic) BOOL didEncounterError;

@end

@implementation ModifyAccessoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.selectedRoom = self.accessory.room ?: self.home.roomForEntireHome;

    self.accessory.delegate = self;

    // Create a dispatch_group to keep track of all the necessary parts
    // of accessory modification.
    self.saveAccessoryGroup = dispatch_group_create();

    // Create an activity indicator so display in place of the 'Add' button.
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

    // If the accessory belongs to the home already, we are in 'edit' mode.
    self.editingExistingAccessory = [self accessoryHasBeenAddedToHome];
    if (self.editingExistingAccessory) {
        // Show 'save' instead of 'add.'
        self.addButton.title = NSLocalizedString(@"Save", @"Save");
    } else {
        // If we're not editing an existing accessory, then let the back
        // button show in the left.
        self.navigationItem.leftBarButtonItem = nil;
    }

    // Put the accessory's name in the 'name' field.
    [self resetNameField];

    // Register a cell for the rooms.
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"RoomCell"];
}

/**
 *  Replaces the activity indicator with the 'Add' or 'Save' button.
 */
- (void)hideActivityIndicator {
    [self.activityIndicator stopAnimating];
    self.navigationItem.rightBarButtonItem = self.addButton;
}

/**
 *  Temporarily replaces the 'Add' or 'Save' button with an activity indicator.
 */
- (void)showActivityIndicator {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    [self.activityIndicator startAnimating];
}

/**
 *  Called whenever the user taps the 'add' button.
 *  
 *  This method:
 *    1. Adds the accessory to the home, if not already added.
 *    2. Updates the accessory's name, if necessary.
 *    3. Assigns the accessory to the selected room, if necessary.
 */
- (IBAction)didTapAddButton {
    // Save some variables to use inside the block.
    __block HMHome *home = self.home;
    __block HMRoom *room = self.selectedRoom;
    NSString *name = [self trimmedName];
    __weak typeof(self) weakSelf = self;
    [self showActivityIndicator];

    if (self.editingExistingAccessory) {
        [self home:home assignAccessory:self.accessory toRoom:room];
        [self updateName:name forAccessory:self.accessory];
    } else {
        dispatch_group_enter(self.saveAccessoryGroup);
        [self.home addAccessory:self.accessory completionHandler:^(NSError *error) {
            if (error) {
                [weakSelf hideActivityIndicator];
                [weakSelf hmc_displayError:error];
                weakSelf.didEncounterError = YES;
            } else {
                // Once it's successfully added to the home, add it to the room that's selected.
                [weakSelf home:home assignAccessory:weakSelf.accessory toRoom:room];
                [weakSelf updateName:name forAccessory:weakSelf.accessory];
            }
            dispatch_group_leave(weakSelf.saveAccessoryGroup);
        }];
    }

    dispatch_group_notify(self.saveAccessoryGroup, dispatch_get_main_queue(), ^{
        [self hideActivityIndicator];
        if (!self.didEncounterError) {
            [self dismiss:nil];
        }
    });
}

/**
 *  Informs the delegate that the accessory has been saved, and
 *  dismisses the view controller.
 */
- (IBAction)dismiss:(id)sender {
    [self.delegate accessoryViewController:self didSaveAccessory:self.accessory];
    if (self.editingExistingAccessory) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

/**
 *  @return YES if the accessory has already been added to the home.
 */
- (BOOL)accessoryHasBeenAddedToHome {
    return [self.home.accessories containsObject:self.accessory];
}

/**
 *  Updates the accessories name. This function will enter and leave the saved dispatch group.
 *  If the accessory's name is already equal to the passed-in name, this method does nothing.
 *
 *  @param name      The new name for the accessory.
 *  @param accessory The accessory to rename.
 */
- (void)updateName:(NSString *)name forAccessory:(HMAccessory *)accessory {
    if ([accessory.name isEqualToString:name]) {
        return;
    }
    dispatch_group_enter(self.saveAccessoryGroup);
    [accessory updateName:name completionHandler:^(NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            self.didEncounterError = YES;
        }
        dispatch_group_leave(self.saveAccessoryGroup);
    }];
}

/**
 *  Assigns the given accessory to the provided room. This method will enter and leave the saved dispatch group.
 *
 *  @param home      The home to assign.
 *  @param accessory The accessory to be assigned.
 *  @param room      The room to which to assign the accessory.
 */
- (void)home:(HMHome *)home assignAccessory:(HMAccessory *)accessory toRoom:(HMRoom *)room {
    if (accessory.room == room) {
        return;
    }
    dispatch_group_enter(self.saveAccessoryGroup);
    [home assignAccessory:accessory toRoom:room completionHandler:^(NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            self.didEncounterError = YES;
        }
        dispatch_group_leave(self.saveAccessoryGroup);
    }];
}

/**
 *  Tells the current accessory to identify itself.
 */
- (void)identifyAccessory {
    [self.accessory identifyWithCompletionHandler:^(NSError *error) {
        if (error) {
            [self hmc_displayError:error];
        }
    }];
}

/**
 *  Tells the home to unblock the current accessory.
 */
- (void)unblockAccessory {
    [self.home unblockAccessory:self.accessory completionHandler:^(NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            return;
        }
        [self reloadTable];
    }];
}

- (void)reloadTable {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

/**
 *  Tries to find a new accessory matching the given identifier,
 *  but if that fails, dismisses.
 */
- (void)homeStoreDidUpdateHomes {
    for (HMAccessory *accessory in self.home.accessories) {
        if ([accessory.name isEqualToString:self.accessory.name]) {
            self.accessory = accessory;
            self.accessory.delegate = self;
        }
    }
    [super homeStoreDidUpdateHomes];
}

/**
 *  Enables the name field if the accessory's name changes.
 */
- (void)resetNameField {
    NSString *action;
    if (self.editingExistingAccessory) {
        action = NSLocalizedString(@"Edit %@", @"Edit Accessory");
    } else {
        action = NSLocalizedString(@"Add %@", @"Add Accessory");
    }
    self.navigationItem.title = [NSString stringWithFormat:action, self.accessory.name];
    self.nameField.text = self.accessory.name;
    [self enableAddButtonIfApplicable];
}

- (void)enableAddButtonIfApplicable {
    self.addButton.enabled = [self trimmedName].length > 0;
}

- (NSString *)trimmedName {
    return [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (IBAction)didChangeNameField:(id)sender {
    [self enableAddButtonIfApplicable];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.accessory.blocked) {
        return 4;
    }
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == AddAccessoryTableViewSectionRooms) {
        return self.home.hmc_allRooms.count;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == AddAccessoryTableViewSectionRooms) {
        return UITableViewAutomaticDimension;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == AddAccessoryTableViewSectionRooms) {
        return [self tableView:tableView roomCellForRowAtIndexPath:indexPath];
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

/**
 *  Creates a cell with the name of each room within the home, displaying a checkmark if the room
 *  is the currently selected room.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView roomCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RoomCell" forIndexPath:indexPath];
    HMRoom *room = self.home.hmc_allRooms[indexPath.row];

    cell.textLabel.text = [self.home hmc_nameForRoom:room];

    // Put a checkmark on the selected room.
    if (room == self.selectedRoom) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case AddAccessoryTableViewSectionRooms: {
            self.selectedRoom = self.home.hmc_allRooms[indexPath.row];
            [self.tableView hmc_update:^(UITableView *tableView) {
                [tableView reloadSections:[NSIndexSet indexSetWithIndex:AddAccessoryTableViewSectionRooms] withRowAnimation:UITableViewRowAnimationAutomatic];
            }];
            break;
        }
        case AddAccessoryTableViewSectionIdentify: {
            [self identifyAccessory];
            break;
        }
        default:
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [super tableView:tableView indentationLevelForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
}

- (void)accessoryDidUpdateName:(HMAccessory *)accessory {
    [self resetNameField];
}

- (void)home:(HMHome *)home didUpdateNameForRoom:(HMRoom *)room {
    [self reloadTable];
}

- (void)home:(HMHome *)home didAddRoom:(HMRoom *)room {
    [self reloadTable];
}

- (void)home:(HMHome *)home didRemoveRoom:(HMRoom *)room {
    [self reloadTable];
}

- (void)home:(HMHome *)home didAddAccessory:(HMAccessory *)accessory {
    // Bridged accessories don't call the original completion handler if their bridges
    // are added to the home. We must respond to -[HMHomeDelegate home:didAddAccessory:]
    // and assign bridged accessories properly.
    if (self.selectedRoom) {
        [self home:home assignAccessory:accessory toRoom:self.selectedRoom];
    }
}

- (void)home:(HMHome *)home didUnblockAccessory:(HMAccessory *)accessory {
    [self reloadTable];
}

@end
