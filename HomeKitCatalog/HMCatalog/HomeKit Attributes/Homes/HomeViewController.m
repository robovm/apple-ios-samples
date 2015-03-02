/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that displays all elements within a home.
  It contains separate sections for Accessories, Rooms, Zones, Action Sets,
  Timer Triggers, and Service Groups.
 */

#import "HomeViewController.h"
#import "ActionSetViewController.h"
#import "AccessoryBrowserViewController.h"
#import "ServicesViewController.h"
#import "AccessoryUpdateController.h"
#import "ModifyAccessoryViewController.h"
#import "TriggerViewController.h"
#import "HMHome+Properties.h"
#import "UIViewController+Convenience.h"
#import "UIAlertController+Convenience.h"
#import "ZoneViewController.h"
#import "ServiceGroupViewController.h"
#import "HomeStore.h"
#import "UITableView+Updating.h"

/**
 *  @enum HomeTableViewSection
 *  @discussion Defines the table view sections and the data to which they pertain.
 */
typedef NS_ENUM(NSUInteger, HomeTableViewSection) {
    /**
     *  The Accessories section.
     */
    HomeTableViewSectionAccessory = 0,
    /**
     *  The Rooms section.
     */
    HomeTableViewSectionRoom,
    /**
     *  The Zones section.
     */
    HomeTableViewSectionZone,
    /**
     *  The Users section.
     */
    HomeTableViewSectionUser,
    /**
     *  The Action Sets section.
     */
    HomeTableViewSectionActionSet,
    /**
     *  The Triggers section.
     */
    HomeTableViewSectionTrigger,
    /**
     *  The Service Groups section.
     */
    HomeTableViewSectionServiceGroup
};

@interface HomeViewController () <HMHomeDelegate, HMAccessoryDelegate>

@end

@implementation HomeViewController

#pragma mark - View Controller Lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];

    id destinationViewController = [self destinationViewControllerForSegue:segue];
    id homeKitObject = [self homeKitObjectAtIndexPath:indexPath];

    // If the destination allows me to set the home, just set it.
    // We use the home all over the place.
    if ([destinationViewController respondsToSelector:@selector(setHome:)]) {
        [destinationViewController setHome:self.home];
    }

    if ([segue.identifier isEqualToString:@"Show Room"]) {
        RoomViewController *roomViewController = destinationViewController;
        roomViewController.room = homeKitObject;
    } else if ([segue.identifier isEqualToString:@"Show Zone"]) {
        ZoneViewController *zoneVC = destinationViewController;
        zoneVC.zone = homeKitObject;
    } else if ([segue.identifier isEqualToString:@"Show Action Set"]) {
        ActionSetViewController *actionSetVC = destinationViewController;
        actionSetVC.actionSet = homeKitObject;
    } else if ([segue.identifier isEqualToString:@"Show Service Group"]) {
        ServiceGroupViewController *serviceGroupVC = destinationViewController;
        serviceGroupVC.serviceGroup = homeKitObject;
    } else if ([segue.identifier isEqualToString:@"Show Accessory"]) {
        ServicesViewController *detailVC = destinationViewController;
        detailVC.accessory = homeKitObject;
        detailVC.cellDelegate = [AccessoryUpdateController new];
    } else if ([segue.identifier isEqualToString:@"Modify Accessory"]) {
        ModifyAccessoryViewController *addAccessoryVC = destinationViewController;
        addAccessoryVC.accessory = homeKitObject;
    } else if ([segue.identifier isEqualToString:@"Show Trigger"]) {
        TriggerViewController *triggerVC = destinationViewController;
        triggerVC.trigger = homeKitObject;
    }
}

/**
 *  @return The segue's <code>destinationViewController</code> or that controller's <code>topViewController</code>
 *          if the destination is a navigation controller.
 */
- (UIViewController *)destinationViewControllerForSegue:(UIStoryboardSegue *)segue {
    if ([segue.destinationViewController isKindOfClass:[UINavigationController class]]) {
        return [segue.destinationViewController topViewController];
    }
    return segue.destinationViewController;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(homeStoreDidUpdateHomes)
                                                 name:HomeStoreDidChangeSharedHomeNotification
                                               object:[HomeStore sharedStore]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = self.home.name;
    [self reloadTable];
}

#pragma mark - Table View

- (void)reloadTable {
    [self assignAccessoryDelegates];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case HomeTableViewSectionAccessory:
            return NSLocalizedString(@"Accessories", @"Accessories");
        case HomeTableViewSectionRoom:
            return NSLocalizedString(@"Rooms", @"Rooms");
        case HomeTableViewSectionZone:
            return NSLocalizedString(@"Zones", @"Zones");
        case HomeTableViewSectionUser:
            return NSLocalizedString(@"Users", @"Users");
        case HomeTableViewSectionActionSet:
            return NSLocalizedString(@"Action Sets", @"Action Sets");
        case HomeTableViewSectionTrigger:
            return NSLocalizedString(@"Timer Triggers", @"Timer Triggers");
        case HomeTableViewSectionServiceGroup:
            return NSLocalizedString(@"Service Groups", @"Service Groups");
        default:
            return @"";
    }
}

/**
 *  The title for the 'Add Item...' row in the table.
 *
 *  @param section The section with the Add row.
 *
 *  @return The title: 'Add Room...', 'Add Zone...', etc.
 */
- (NSString *)titleForAddRowInSection:(NSInteger)section {
    switch (section) {
        case HomeTableViewSectionAccessory:
            return NSLocalizedString(@"Add Accessory…", @"Add Accessory");
        case HomeTableViewSectionRoom:
            return NSLocalizedString(@"Add Room…", @"Add Room");
        case HomeTableViewSectionZone:
            return NSLocalizedString(@"Add Zone…", @"Add Zone");
        case HomeTableViewSectionUser:
            return NSLocalizedString(@"Add User…", @"Add User");
        case HomeTableViewSectionActionSet:
            return NSLocalizedString(@"Add Action Set…", @"Add Action Set");
        case HomeTableViewSectionTrigger:
            return NSLocalizedString(@"Add Timer Trigger…", @"Add Timer Trigger");
        case HomeTableViewSectionServiceGroup:
            return NSLocalizedString(@"Add Service Group…", @"Add Service Group…");
        default:
            return @"";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case HomeTableViewSectionZone:
            return NSLocalizedString(@"Zones are optional collections of rooms.", @"Zones Description");
        case HomeTableViewSectionUser:
            return NSLocalizedString(@"Users can control the accessories in your home. You can share your home "
                                     @"with anybody with an iCloud account.",
                                     @"Users Description");
        case HomeTableViewSectionActionSet:
            return NSLocalizedString(@"Action Sets allow you to control multiple accessories simultaneously. "
                                     @"You must have at least one paired accessory to create an action set.",
                                     @"Action Sets Description");
        case HomeTableViewSectionTrigger:
            return NSLocalizedString(@"Timer Triggers execute action sets at specific times. "
                                     @"You must have created at least one action set to add a "
                                     @"timer trigger.",
                                     @"Timer Trigger Description");
        case HomeTableViewSectionServiceGroup:
            return NSLocalizedString(@"Service groups organize services in a custom way. For example, add a subset of "
                                     @"lights in your living room to control them without controlling all the lights in "
                                     @"the living room.",
                                     @"Service Group Description");
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self homeKitObjectsForSection:section].count + 1; // for the 'Add' row.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self indexPathIsAdd:indexPath]) {
        return [self tableView:tableView addCellForRowAtIndexPath:indexPath];
    }
    return [self tableView:tableView homeKitObjectCellForRowAtIndexPath:indexPath];
}

/**
 *  Creates and returns a cell with "Add [object title]..." as its main text, 
 *  that will add an object to the Home when selected.
 *  
 *  If the section is Action Set or Trigger, then the method will choose whether or not to enable
 *  either of the cells based on <code>-[HomeViewController canAddTrigger]</code> and <code>-[HomeViewController canAddActionSet]</code>
 */
- (UITableViewCell *)tableView:(UITableView *)tableView addCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseIdentifier = @"AddCell";
    if ((![self canAddActionSet] && indexPath.section == HomeTableViewSectionActionSet) ||
        (![self canAddTrigger] && indexPath.section == HomeTableViewSectionTrigger)) {
        reuseIdentifier = @"DisabledAddCell";
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [self titleForAddRowInSection:indexPath.section];
    return cell;
}

/**
 *  @return the appropriate reuse identifier given the section of the index path.
 *  
 *  These reuse identifiers are declared in the storyboard and have custom behaviors
 *  associated with them, usually accessory actions or selection segues.
 */
- (NSString *)reuseIdentifierForIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case HomeTableViewSectionAccessory: {
            HMAccessory *accessory = [self homeKitObjectAtIndexPath:indexPath];
            return accessory.reachable ? @"AccessoryCell" : @"UnreachableAccessoryCell";
        }
        case HomeTableViewSectionRoom:
            return @"RoomCell";
        case HomeTableViewSectionZone:
            return @"ZoneCell";
        case HomeTableViewSectionUser:
            return @"UserCell";
        case HomeTableViewSectionActionSet:
            return @"ActionSetCell";
        case HomeTableViewSectionTrigger:
            return @"TriggerCell";
        case HomeTableViewSectionServiceGroup:
            return @"ServiceGroupCell";
        default:
            return nil;
    }
}

/**
 *  Creates a cell that represents the HomeKit object being displayed at that index.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView homeKitObjectCellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // Grab the object associated with this indexPath.
    id homeKitObject = [self homeKitObjectAtIndexPath:indexPath];

    // Get the name of the object.
    NSString *name = [homeKitObject name];

    // A bit of special behavior here, where we decide to use the home's 'nameForRoom' property
    // which will append "(Default Room)" to the roomForEntireHome.
    if ([homeKitObject isKindOfClass:[HMRoom class]]) {
        name = [self.home hmc_nameForRoom:homeKitObject];
    }

    // Grab the appropriate reuse identifier for this index path.
    NSString *reuseIdentifier = [self reuseIdentifierForIndexPath:indexPath];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.textLabel.text = name;
    return cell;
}

/**
 *  @return YES if the row can be removed. Any row that is not an 'add' row, and is not the roomForEntireHome, can be removed.
 */
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return !([self homeKitObjectAtIndexPath:indexPath] == self.home.roomForEntireHome || [self indexPathIsAdd:indexPath]);
}

/**
 *  Removes the selected HomeKit object from the table.
 */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        id object = [self homeKitObjectAtIndexPath:indexPath];
        [self removeHomeKitObject:object completionHandler:^(NSError *error) {
            if (error) {
                [self hmc_displayError:error];
                return;
            }
            [self didRemoveHomeKitObjectAtIndexPath:indexPath];
        }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.selectionStyle == UITableViewCellSelectionStyleNone) {
        return;
    }
    if ([self indexPathIsAdd:indexPath]) {
        switch (indexPath.section) {
            case HomeTableViewSectionAccessory:
                [self browseForAccessories];
                break;
            case HomeTableViewSectionRoom:
                [self addNewRoom];
                break;
            case HomeTableViewSectionZone:
                [self addNewZone];
                break;
            case HomeTableViewSectionUser:
                [self addNewUser];
                break;
            case HomeTableViewSectionActionSet:
                [self addNewActionSet];
                break;
            case HomeTableViewSectionTrigger:
                [self addNewTrigger];
                break;
            case HomeTableViewSectionServiceGroup:
                [self addNewServiceGroup];
                break;
            default:
                break;
        }
    } else if (indexPath.section == HomeTableViewSectionActionSet) {
        HMActionSet *actionSet = [self homeKitObjectAtIndexPath:indexPath];
        [self.home executeActionSet:actionSet completionHandler:^(NSError *error) {
            if (error) {
                [self hmc_displayError:error];
                return;
            }
        }];
    }
}

#pragma mark - HomeKit-related Convenience Methods

/**
 *  @return the list of Home Kit objects appropriate for a given HomeTableViewSection.
 */
- (NSArray *)homeKitObjectsForSection:(HomeTableViewSection)section {
    switch (section) {
        case HomeTableViewSectionAccessory:
            return self.home.accessories;
        case HomeTableViewSectionRoom:
            return self.home.hmc_allRooms;
        case HomeTableViewSectionZone:
            return self.home.zones;
        case HomeTableViewSectionUser:
            return self.home.users;
        case HomeTableViewSectionActionSet:
            return self.home.actionSets;
        case HomeTableViewSectionTrigger:
            return self.home.triggers;
        case HomeTableViewSectionServiceGroup:
            return self.home.serviceGroups;
        default:
            return nil;
    }
}

/**
 *  The section that corresponds to a given object,
 *  or NSNotFound if that object type doesn't exist
 *  on this table.
 *
 *  @param object The object whose section you would like to find.
 *
 *  @return The section that corresponds to that object, or NSNotFound if
 *          that object type is not represented on the table.
 */
- (HomeTableViewSection)sectionOfHomeKitObject:(id)object {
    if ([object isKindOfClass:[HMActionSet class]]) {
        return HomeTableViewSectionActionSet;
    } else if ([object isKindOfClass:[HMAccessory class]]) {
        return HomeTableViewSectionAccessory;
    } else if ([object isKindOfClass:[HMZone class]]) {
        return HomeTableViewSectionZone;
    } else if ([object isKindOfClass:[HMUser class]]) {
        return HomeTableViewSectionUser;
    } else if ([object isKindOfClass:[HMRoom class]]) {
        return HomeTableViewSectionRoom;
    } else if ([object isKindOfClass:[HMTrigger class]]) {
        return HomeTableViewSectionTrigger;
    } else if ([object isKindOfClass:[HMServiceGroup class]]) {
        return HomeTableViewSectionServiceGroup;
    }
    return NSNotFound;
}

/**
 *  @discussion
 *  Uses the homeKitObjectsForSection method to get the objects and then uses the row to get
 *  the appropriate object.
 */
- (id)homeKitObjectAtIndexPath:(NSIndexPath *)indexPath {
    if ([self indexPathIsAdd:indexPath]) {
        return nil;
    }
    NSArray *objects = [self homeKitObjectsForSection:indexPath.section];
    return objects[indexPath.row];
}

/**
 *  Looks up the appropriate row and section for a given object,
 *  and returns the appropriate index path.
 *
 *  @param object The HomeKit object you want to look up in the table.
 *
 *  @return The indexPath that represents that object in this screen,
 *          or nil if that object doesn't exist on this table.
 */
- (NSIndexPath *)indexPathOfHomeKitObject:(id)object {
    NSUInteger section = [self sectionOfHomeKitObject:object];
    NSUInteger index = [[self homeKitObjectsForSection:section] indexOfObject:object];
    if (index == NSNotFound) {
        return nil;
    }
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:section];
    return path;
}

/**
 *  Based on the class of the object passed in, calls
 *  the appropriate removal function to remove that object from the home.
 *
 *  @param object     An HMRoom, HMZone, HMUser, HMTrigger, or HMActionSet
 *  @param completion A block to be called when the object is removed, containing an
 *                    error or nil if the action was successful.
 */
- (void)removeHomeKitObject:(id)object completionHandler:(void (^)(NSError *))completion {
    if ([object isKindOfClass:[HMActionSet class]]) {
        [self.home removeActionSet:object completionHandler:^(NSError *error) {
            completion(error);
            [self updateActionSetSection];
        }];
    } else if ([object isKindOfClass:[HMAccessory class]]) {
        [self.home removeAccessory:object completionHandler:^(NSError *error) {
            completion(error);
            [self assignAccessoryDelegates];
        }];
    } else if ([object isKindOfClass:[HMRoom class]]) {
        [self.home removeRoom:object completionHandler:completion];
    } else if ([object isKindOfClass:[HMZone class]]) {
        [self.home removeZone:object completionHandler:completion];
    } else if ([object isKindOfClass:[HMUser class]]) {
        [self.home removeUser:object completionHandler:completion];
    } else if ([object isKindOfClass:[HMTrigger class]]) {
        [self.home removeTrigger:object completionHandler:completion];
    } else if ([object isKindOfClass:[HMServiceGroup class]]) {
        [self.home removeServiceGroup:object completionHandler:completion];
    }
}

/**
 *  The set of abstractions below represents the fundamental actions on the table, inserting, reloading,
 *  and deleting rows in the table. Every modification to the table flows through one of these functions.
 */

/**
 *  Finds the provided object's intended position in the table, then
 *  inserts a row at that index path, to accomodate the new object.
 *
 *  @param object The object that's been added to the table.
 */
- (void)didAddHomeKitObject:(id)object {
    NSIndexPath *indexPath = [self indexPathOfHomeKitObject:object];
    if (!indexPath) {
        return;
    }
    [self.tableView hmc_update:^(UITableView *tableView) {
        [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

/**
 *  Finds the provided object's current position in the table, then
 *  reloads the row at that index path.
 *
 *  @param object The object that's been updated inthe table.
 */
- (void)didModifyHomeKitObject:(id)object {
    NSIndexPath *indexPath = [self indexPathOfHomeKitObject:object];
    if (!indexPath) {
        return;
    }
    [self.tableView hmc_update:^(UITableView *tableView) {
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

/**
 *  Deletes the row for the provided index path, using automatic animations.
 *
 *  @param indexPath The indexPath that's been removed from the table.
 */
- (void)didRemoveHomeKitObjectAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView hmc_update:^(UITableView *tableView) {
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

/**
 *  Because the object no longer exists in the table at this point, this method
 *  reloads the section that that object corresponds to.
 *
 *  @param object The object that's been removed from the table.
 */
- (void)didRemoveHomeKitObject:(id)object {
    HomeTableViewSection section = [self sectionOfHomeKitObject:object];
    [self reloadSection:section];
}

/**
 *  Reloads a section in the table using automatic animations.
 *
 *  @param section The section to reload.
 */
- (void)reloadSection:(HomeTableViewSection)section {
    NSIndexSet *sectionIndexSet = [NSIndexSet indexSetWithIndex:section];
    [self.tableView hmc_update:^(UITableView *tableView) {
        [tableView reloadSections:sectionIndexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

/**
 *  Tells whether or not the given indexPath is an 'add' row.
 *
 *  @param indexPath The indexPath.
 *
 *  @return Whether or not it is an 'add' row.
 */
- (BOOL)indexPathIsAdd:(NSIndexPath *)indexPath {
    return indexPath.row == [self homeKitObjectsForSection:indexPath.section].count;
}

#pragma mark - HomeKit User Interaction (adding/removing/modifying objects)

/**
 *  Convenience method to access the HomeStore's home.
 *
 *  @return The share HomeStore's home.
 */
- (HMHome *)home {
    return [HomeStore sharedStore].home;
}

/**
 *  Disabled the 'Add Trigger' row if there are no action sets in the home.
 */
- (void)updateTriggerAddRow {
    NSIndexSet *triggerSection = [NSIndexSet indexSetWithIndex:HomeTableViewSectionTrigger];
    [self.tableView hmc_update:^(UITableView *tableView) {
        [tableView reloadSections:triggerSection withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

/**
 *  Disable the 'Add Action Set' row if there are no accessories in the home.
 */
- (void)updateActionSetSection {
    NSIndexSet *actionSetSection = [NSIndexSet indexSetWithIndex:HomeTableViewSectionActionSet];
    [self.tableView hmc_update:^(UITableView *tableView) {
        [self.tableView reloadSections:actionSetSection withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    [self updateTriggerAddRow];
}

/**
 *  Whether or not the user can add an action set.
 *
 *  @return YES if the home contains one or more accessories.
 */
- (BOOL)canAddActionSet {
    // You can only add action sets if there are accessories within the home.
    return self.home.accessories.count > 0;
}

/**
 *  Whether or not the user can add a trigger.
 *
 *  @return YES if the home contains one or more Action Sets.
 */
- (BOOL)canAddTrigger {
    // You can only add triggers if there are action sets within the home.
    return self.home.actionSets.count > 0;
}

/**
 *  Prompts the user to input a name for a new Trigger to be added to the home.
 */
- (void)addNewTrigger {
    [self performSegueWithIdentifier:@"Add Trigger" sender:self];
}

/**
 *  Prompts the user to input a name for a new Action Set to be added to the home.
 */
- (void)addNewActionSet {
    [self performSegueWithIdentifier:@"Add Action Set" sender:self];
}

/**
 *  Opens the accessory browser.
 */
- (void)browseForAccessories {
    [self performSegueWithIdentifier:@"Add Accessories" sender:self];
}

/**
 *  Prompts the user to input a name for a new Room to be added to the home.
 */
- (void)addNewRoom {
    [self hmc_presentAddAlertWithAttributeType:NSLocalizedString(@"Room", @"Room")
                                   placeholder:NSLocalizedString(@"Living Room", @"Living Room")
                                    completion:^(NSString *name) {
        [self addRoomWithName:name];
                                    }];
}

/**
 *  Prompts the user to input a name for a new Room to be added to the home.
 */
- (void)addNewServiceGroup {
    [self hmc_presentAddAlertWithAttributeType:NSLocalizedString(@"Service Group", @"Service Group")
                                   placeholder:NSLocalizedString(@"Table Lights", @"Table Lights")
                                     shortType:NSLocalizedString(@"Group", @"Group")
                                    completion:^(NSString *name) {
        [self addServiceGroupWithName:name];
                                    }];
}

/**
 *  Tells the home to add a room with the provided name and adds it to the table.
 *
 *  @param name The new name for the room.
 */
- (void)addRoomWithName:(NSString *)name {
    [self.home addRoomWithName:name completionHandler:^(HMRoom *newRoom, NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            return;
        }
        [self didAddHomeKitObject:newRoom];
    }];
}

/**
 *  Tells the home to add a service group with the provided name and adds it to the table.
 *
 *  @param name The new name for the service group.
 */
- (void)addServiceGroupWithName:(NSString *)name {
    [self.home addServiceGroupWithName:name completionHandler:^(HMServiceGroup *serviceGroup, NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            return;
        }
        [self didAddHomeKitObject:serviceGroup];
    }];
}

/**
 *  Tells the home to add a new user, using HomeKit's built-in popup.
 */
- (void)addNewUser {
    [self.home addUserWithCompletionHandler:^(HMUser *user, NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            return;
        }
        [self didAddHomeKitObject:user];
    }];
}

/**
 *  Prompts the user to input a name for a new Zone to be added to the home.
 */
- (void)addNewZone {
    [self hmc_presentAddAlertWithAttributeType:NSLocalizedString(@"Zone", @"Zone")
                                   placeholder:NSLocalizedString(@"Upstairs", @"Upstairs")
                                    completion:^(NSString *name) {
        [self addZoneWithName:name];
                                    }];
}

/**
 *  Tells the home to add a zone with the provided name and adds it to the table.
 *
 *  @param name The new name for the zone.
 */
- (void)addZoneWithName:(NSString *)name {
    [self.home addZoneWithName:name completionHandler:^(HMZone *newZone, NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            return;
        }
        [self didAddHomeKitObject:newZone];
    }];
}

#pragma mark - HMAccessoryDelegate methods

- (void)accessoryDidUpdateReachability:(HMAccessory *)accessory {
    [self didModifyHomeKitObject:accessory];
}

- (void)accessoryDidUpdateName:(HMAccessory *)accessory {
    [self didModifyHomeKitObject:accessory];
}

/**
 *  Assigns self as the delegate for all of the HMAccessories in the home's accessory list.
 */
- (void)assignAccessoryDelegates {
    for (HMAccessory *accessory in self.home.accessories) {
        accessory.delegate = self;
    }
}

#pragma mark - HMHomeDelegate Methods

/**
 *  Delegate callback. Updates the view controller's title
 *  when the home's name changes.
 *
 *  @param home The new name for the home.
 */
- (void)homeDidUpdateName:(HMHome *)home {
    self.navigationItem.title = home.name;
}

/**
 *  Delegate callback. Finds the index of the new accessory in the accessory list and inserts a row in the table.
 *
 *  @param home      The home that added an accessory.
 *  @param accessory The accessory that was added.
 */
- (void)home:(HMHome *)home didAddAccessory:(HMAccessory *)accessory {
    [self didAddHomeKitObject:accessory];
    [self assignAccessoryDelegates];
}

/**
 *  Delegate callback. Finds the index of the new accessory in the accessory list and removes a row from the table.
 *
 *  @param home      The home that removed an accessory.
 *  @param accessory The accessory that was removed.
 */
- (void)home:(HMHome *)home didRemoveAccessory:(HMAccessory *)accessory {
    [self didRemoveHomeKitObject:accessory];
    [self assignAccessoryDelegates];
}

#pragma mark Triggers

/**
 *  Delegate callback. Finds the index of the new trigger in the triggers list and inserts a row in the table.
 *
 *  @param home    The home that added a trigger.
 *  @param trigger The trigger that was added.
 */
- (void)home:(HMHome *)home didAddTrigger:(HMTrigger *)trigger {
    [self didAddHomeKitObject:trigger];
}

/**
 *  Delegate callback. Finds the index of the trigger in the triggers list and removes that row from the table.
 *
 *  @param home    The home that removed a trigger.
 *  @param trigger The trigger that was removed.
 */
- (void)home:(HMHome *)home didRemoveTrigger:(HMTrigger *)trigger {
    [self didRemoveHomeKitObject:trigger];
}

/**
 *  Delegate callback. Finds the index of the trigger in the triggers list and reloads that row in the table.
 *
 *  @param home    The home that updated a trigger.
 *  @param trigger The trigger that was updated.
 */
- (void)home:(HMHome *)home didUpdateNameForTrigger:(HMTrigger *)trigger {
    [self didModifyHomeKitObject:trigger];
}

#pragma mark Service Groups

/**
 *  Delegate callback. Finds the index of the new service group in the service groups list and inserts a row in the table.
 *
 *  @param home    The home that added a service group.
 *  @param group   The service group that was added.
 */
- (void)home:(HMHome *)home didAddServiceGroup:(HMServiceGroup *)group {
    [self didAddHomeKitObject:group];
}

/**
 *  Delegate callback. Finds the index of the service group in the service groups list and removes that row from the table.
 *
 *  @param home    The home that removed a service group.
 *  @param group   The service group that was removed.
 */
- (void)home:(HMHome *)home didRemoveServiceGroup:(HMServiceGroup *)group {
    [self didRemoveHomeKitObject:group];
}

/**
 *  Delegate callback. Finds the index of the service group in the service groups list and reloads that row in the table.
 *
 *  @param home    The home that updated a service group.
 *  @param group   The service group that was updated.
 */
- (void)home:(HMHome *)home didUpdateNameForServiceGroup:(HMServiceGroup *)group {
    [self didModifyHomeKitObject:group];
}

#pragma mark Action Sets

/**
 *  Delegate callback. Finds the index of the new action set in the action sets list and inserts a row in the table.
 *
 *  @param home      The home that added an action set.
 *  @param actionSet The action set that was added.
 */
- (void)home:(HMHome *)home didAddActionSet:(HMActionSet *)actionSet {
    [self updateActionSetSection];
}

/**
 *  Delegate callback. Finds the index of the action set in the action sets list and removes that row from the table.
 *
 *  @param home      The home that removed an action set.
 *  @param actionSet The action set that was removed.
 */
- (void)home:(HMHome *)home didRemoveActionSet:(HMActionSet *)actionSet {
    [self updateActionSetSection];
}

/**
 *  Delegate callback. Finds the index of the action set in the action sets list and reloads that row in the table.
 *
 *  @param home      The home that updated an action set.
 *  @param actionSet The action set that was updated.
 */
- (void)home:(HMHome *)home didUpdateNameForActionSet:(HMActionSet *)actionSet {
    [self updateActionSetSection];
}

#pragma mark Zones

/**
 *  Delegate callback. Finds the index of the new zone in the zones list and reloads that row in the table.
 *
 *  @param home The home that added a zone.
 *  @param zone The zone that was added.
 */
- (void)home:(HMHome *)home didAddZone:(HMZone *)zone {
    [self didAddHomeKitObject:zone];
}

/**
 *  Delegate callback. Finds the index of the zone in the zones list and removes that row from the table.
 *
 *  @param home The home that removed a zone.
 *  @param zone The zone that was removed.
 */
- (void)home:(HMHome *)home didRemoveZone:(HMZone *)zone {
    [self didRemoveHomeKitObject:zone];
}

/**
 *  Delegate callback. Finds the index of the zone in the zones list and reloads that row in the table.
 *
 *  @param home The home that updated a zone.
 *  @param zone The zone that was updated.
 */
- (void)home:(HMHome *)home didUpdateNameForZone:(HMZone *)zone {
    [self didModifyHomeKitObject:zone];
}

#pragma mark Rooms

/**
 *  Delegate callback. Finds the index of the new room in the rooms list and reloads that row in the table.
 *
 *  @param home The home that added a room.
 *  @param room The room that was added.
 */
- (void)home:(HMHome *)home didAddRoom:(HMRoom *)room {
    [self didAddHomeKitObject:room];
}

/**
 *  Delegate callback. Finds the index of the zone in the zones list and removes that row from the table.
 *
 *  @param home The home that removed a zone.
 *  @param zone The zone that was removed.
 */
- (void)home:(HMHome *)home didRemoveRoom:(HMRoom *)room {
    [self didRemoveHomeKitObject:room];
}

/**
 *  Delegate callback. Finds the index of the room in the rooms list and reloads that row in the table.
 *
 *  @param home The home that updated a room.
 *  @param room The room that was updated.
 */
- (void)home:(HMHome *)home didUpdateNameForRoom:(HMRoom *)room {
    [self didModifyHomeKitObject:room];
}

#pragma mark Users

/**
 *  Delegate callback. Finds the index of the new user in the users list and reloads that row in the table.
 *
 *  @param home The home that added a user.
 *  @param user The user that was added.
 */
- (void)home:(HMHome *)home didAddUser:(HMUser *)user {
    [self didAddHomeKitObject:user];
}

/**
 *  Delegate callback. Finds the index of the user in the users list and removes that row in the table.
 *
 *  @param home The home that removed a user.
 *  @param user The user that was removed.
 */
- (void)home:(HMHome *)home didRemoveUser:(HMUser *)user {
    [self didRemoveHomeKitObject:user];
}

@end
