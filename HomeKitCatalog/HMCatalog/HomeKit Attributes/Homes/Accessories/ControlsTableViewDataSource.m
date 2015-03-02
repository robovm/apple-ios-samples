/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableViewDataSource that populates the table in ControlsViewController.
 */

#import "ControlsTableViewDataSource.h"
#import "HomeStore.h"
#import "ServiceCell.h"
#import "UITableView+EmptyMessage.h"
#import "HMService+Readability.h"
#import "HMHome+Properties.h"

@interface NSDictionary (SortedKeys)
@property (nonatomic, readonly) NSArray *sortedKeys;
@end

@implementation NSDictionary (SortedKeys)

- (NSArray *)sortedKeys {
    return [self.allKeys sortedArrayUsingSelector:@selector(compare:)];
}

@end

@interface ControlsTableViewDataSource () <HMHomeDelegate, HMAccessoryDelegate>

@property (nonatomic) NSDictionary *serviceTable;
@property (nonatomic) NSArray *sortedKeys;
@property (nonatomic) UITableView *tableView;
@property (nonatomic, readonly) HMHome *home;

@end

@implementation ControlsTableViewDataSource

+ (instancetype)dataSourceForTableView:(UITableView *)tableView {
    return [[self alloc] initWithTableView:tableView];
}

- (instancetype)initWithTableView:(UITableView *)tableView {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.tableView = tableView;
    self.tableView.dataSource = self;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTable)
                                                 name:HomeStoreDidChangeSharedHomeNotification
                                               object:[HomeStore sharedStore]];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 *  @return The number of different service types in the table.
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = self.sortedKeys.count;
    [tableView hmc_addMessage:[self emptyMessage] ifNecessaryForRowCount:sections];
    return sections;
}

/**
 *  @return A message that corresponds to the current most important reason
 *  that there are no services in the table. Either "No Accessories" or "No Services".
 */
- (NSString *)emptyMessage {
    if (self.home.accessories.count == 0) {
        return NSLocalizedString(@"No Accessories", @"No Accessories");
    } else {
        return NSLocalizedString(@"No Services", @"No Services");
    }
    return nil;
}

/**
 *  @return The localized service type corresponding to that section.
 */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sortedKeys[section];
}

/**
 *  Convenience passthrough to the HomeStore's home.
 */
- (HMHome *)home {
    return [HomeStore sharedStore].home;
}

/**
 *  @return the number of services corresponding to the service type in the indexPath's section.
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    return [self.serviceTable[title] count];
}

/**
 *  Creates a ServiceCell corresponding to the service at the provided index path.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HMService *service = [self serviceForIndexPath:indexPath];
    NSString *reuseIdentifier = @"ServiceCell";
    if (!service.accessory.reachable) {
        reuseIdentifier = @"UnreachableServiceCell";
    }
    ServiceCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.service = service;
    return cell;
}

/**
 *  Finds the appropriate service in corresponding to a given indexPath.
 *
 *  @param indexPath The indexPath you're looking up. The section corresponds to the represented service type,
 *                   and the row corresponds to the service within the section.
 *
 *  @return The service associated with the index path.
 */
- (HMService *)serviceForIndexPath:(NSIndexPath *)indexPath {
    NSString *title = [self tableView:self.tableView titleForHeaderInSection:indexPath.section];
    HMService *service = self.serviceTable[title][indexPath.row];
    return service;
}

/**
 *  @return the currently selected service in the list.
 *
 *  @return The service that's selected right now.
 */
- (HMService *)selectedService {
    return [self serviceForIndexPath:self.tableView.indexPathForSelectedRow];
}

/**
 *  Regenerates a service table based on the current accessories in the list,
 *  and re-sets all of the accessory delegates to this controller.
 */
- (void)resetAccessories {
    self.serviceTable = self.home.hmc_serviceTable;
    self.sortedKeys = self.serviceTable.sortedKeys;
    for (HMAccessory *accessory in self.home.accessories) {
        accessory.delegate = self;
    }
}

/**
 *  Resets the accessories and reassigns the home's delegate.
 */
- (void)reloadTable {
    [self resetAccessories];
    [self.tableView reloadData];
}

- (void)home:(HMHome *)home didAddAccessory:(HMAccessory *)accessory {
    [self reloadTable];
}

- (void)home:(HMHome *)home didRemoveAccessory:(HMAccessory *)accessory {
    [self reloadTable];
}

- (void)accessoryDidUpdateReachability:(HMAccessory *)accessory {
    [self reloadTable];
}

- (void)accessory:(HMAccessory *)accessory didUpdateNameForService:(HMService *)service {
    [self reloadTable];
}

- (void)accessory:(HMAccessory *)accessory didUpdateAssociatedServiceTypeForService:(HMService *)service {
    [self reloadTable];
}

- (void)accessoryDidUpdateServices:(HMAccessory *)accessory {
    [self reloadTable];
}

- (void)accessoryDidUpdateName:(HMAccessory *)accessory {
    [self reloadTable];
}

@end
