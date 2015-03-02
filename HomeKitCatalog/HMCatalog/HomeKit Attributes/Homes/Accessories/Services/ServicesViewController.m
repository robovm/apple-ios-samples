/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller which displays all the services of a provided accessory, and passes its cell delegate onto a CharacteristicsViewController.
 */

#import "ServicesViewController.h"
#import "CharacteristicsViewController.h"
#import "HMService+Readability.h"
#import "NSIndexPath+ArrayIndex.h"
#import "UITableView+Updating.h"
#import "HMHome+Properties.h"
#import "HomeViewController.h"

typedef NS_ENUM(NSUInteger, AccessoryTableViewSection) {
    AccessoryTableViewSectionServices = 0,
    AccessoryTableViewSectionBridgedAccessories
};

@interface ServicesViewController () <HMAccessoryDelegate>
@end

@implementation ServicesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.accessory.delegate = self;
    [self updateTitle];
}

#pragma mark - Table view data source

/**
 *  Two sections if we're showing bridged accessories.
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.accessory.identifiersForBridgedAccessories) {
        return 2;
    }
    return 1;
}

/**
 *  Section 1 contains the services within the accessory.
 *  Section 2 contains the bridged accessories.
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case AccessoryTableViewSectionServices:
            return self.accessory.services.count;
        case AccessoryTableViewSectionBridgedAccessories:
            return self.accessory.identifiersForBridgedAccessories.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case AccessoryTableViewSectionServices:
            return [self tableView:tableView serviceCellForRowAtIndexPath:indexPath];
        case AccessoryTableViewSectionBridgedAccessories:
            return [self tableView:tableView bridgedAccessoryCellForRowAtIndexPath:indexPath];
    }
    return nil;
}

/**
 *  @return A cell containing the name of a bridged accessory at a given index path.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView bridgedAccessoryCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AccessoryCell" forIndexPath:indexPath];
    NSUUID *identifier = self.accessory.identifiersForBridgedAccessories[indexPath.row];
    HMAccessory *accessory = [self.home hmc_accessoryWithIdentifier:identifier];
    cell.textLabel.text = accessory.name;
    return cell;
}

/**
 *  @return A cell containing the name of a service at a given index path, as well as a localized description
 *          of its service type.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView serviceCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ServiceCell" forIndexPath:indexPath];

    HMService *service = self.accessory.services[indexPath.row];

    // Inherit the name from the accessory if the Service doesn't have one.
    cell.textLabel.text = service.name ?: service.accessory.name;
    cell.detailTextLabel.text = service.hmc_localizedServiceType;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case AccessoryTableViewSectionServices:
            return NSLocalizedString(@"Services", @"Services");
        case AccessoryTableViewSectionBridgedAccessories:
            return NSLocalizedString(@"Bridged Accessories", @"Bridged Accessories");
    }
    return nil;
}

/**
 *  If an accessory is bridged, the footer will say "This accessory is being bridged into HomeKit by [bridge name]".
 */
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == AccessoryTableViewSectionServices && self.accessory.bridged) {
        NSString *formatString = NSLocalizedString(@"This accessory is being bridged into HomeKit by %@.", @"Bridge Description");
        HMAccessory *bridge = [self.home hmc_bridgeForAccessory:self.accessory];
        return [NSString stringWithFormat:formatString, bridge.name];
    }
    return nil;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Show Service"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        HMService *selectedService = self.accessory.services[indexPath.row];
        CharacteristicsViewController *characteristicsViewController = segue.destinationViewController;
        characteristicsViewController.service = selectedService;
        characteristicsViewController.cellDelegate = self.cellDelegate;
    }
}

- (void)updateTitle {
    self.navigationItem.title = self.accessory.name;
}

/**
 *  Tries to find a new accessory matching the old one,
 *  but if it fails, it pops the navigation stack.
 */
- (void)homeStoreDidUpdateHomes {
    HMAccessory *newAccessory = nil;
    for (HMAccessory *accessory in self.home.accessories) {
        if ([accessory.identifier isEqual:self.accessory.identifier]) {
            newAccessory = accessory;
        }
    }
    self.accessory = newAccessory;
    if (!self.accessory) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    [super homeStoreDidUpdateHomes];
}

#pragma mark - Accessory Delegate Callbacks

- (void)accessoryDidUpdateName:(HMAccessory *)accessory {
    self.accessory = accessory;
    [self updateTitle];
}

- (void)accessory:(HMAccessory *)accessory didUpdateNameForService:(HMService *)service {
    NSIndexPath *path = [NSIndexPath hmc_indexPathOfObject:service inArray:self.accessory.services];
    if (path) {
        [self.tableView hmc_update:^(UITableView *tableView) {
            [tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }
}

/**
 *  If the accessory becomes unreachable while we're displaying its services,
 *  pop back to the home.
 */
- (void)accessoryDidUpdateReachability:(HMAccessory *)accessory {
    if (accessory == self.accessory && !accessory.reachable) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)accessoryDidUpdateServices:(HMAccessory *)accessory {
    [self.tableView reloadData];
}

@end
