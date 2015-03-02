/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that allows the user to add services to a service group.
 */

#import "ServiceGroupViewController.h"
#import "AddServicesViewController.h"
#import "HMHome+Properties.h"
#import "ServiceCell.h"
#import "UITableView+EmptyMessage.h"
#import "UITableView+Updating.h"
#import "UIViewController+Convenience.h"

@interface ServiceGroupViewController () <HMHomeDelegate, HMAccessoryDelegate>

@end

@implementation ServiceGroupViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

/**
 *  Tries to find a new service group matching the old one,
 *  but if it fails, it pops the navigation stack.
 */
- (void)homeStoreDidUpdateHomes {
    HMServiceGroup *newServiceGroup = nil;
    for (HMServiceGroup *serviceGroup in self.home.serviceGroups) {
        if ([serviceGroup.name isEqualToString:self.serviceGroup.name]) {
            newServiceGroup = serviceGroup;
        }
    }
    self.serviceGroup = newServiceGroup;
    if (self.serviceGroup) {
        [super homeStoreDidUpdateHomes];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger rows = self.serviceGroup.services.count + 1; // for the Add row.
    return rows;
}

- (BOOL)indexPathIsAdd:(NSIndexPath *)indexPath {
    return indexPath.row == self.serviceGroup.services.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return ![self indexPathIsAdd:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self indexPathIsAdd:indexPath]) {
        return [self tableView:tableView addCellForRowAtIndexPath:indexPath];
    }
    return [self tableView:tableView serviceCellForRowAtIndexPath:indexPath];
}

/**
 *  Creates a cell containing the service at the provided index path.
 */
- (ServiceCell *)tableView:(UITableView *)tableView serviceCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ServiceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ServiceCell" forIndexPath:indexPath];
    HMService *service = self.serviceGroup.services[indexPath.row];
    cell.service = service;
    return cell;
}

/**
 *  Creates a cell that, when enabled, allows adding services to the service group.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView addCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *unAddedServices = [self.home hmc_servicesNotAlreadyInServiceGroup:self.serviceGroup includingServices:nil];
    if (unAddedServices.count == 0) {
        return [tableView dequeueReusableCellWithIdentifier:@"DisabledAddCell" forIndexPath:indexPath];
    }
    return [tableView dequeueReusableCellWithIdentifier:@"AddCell" forIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self removeServiceAtIndexPath:indexPath];
    }
}

/**
 *  Removes the service associated with the cell at a given index path.
 */
- (void)removeServiceAtIndexPath:(NSIndexPath *)indexPath {
    HMService *service = self.serviceGroup.services[indexPath.row];
    [self.serviceGroup removeService:service completionHandler:^(NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            return;
        }
        [self.tableView hmc_update:^(UITableView *tableView) {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
            [tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Add Services"]) {
        AddServicesViewController *addServicesVC = (AddServicesViewController *)[segue.destinationViewController topViewController];
        addServicesVC.serviceGroup = self.serviceGroup;
    }
}

- (void)home:(HMHome *)home didAddService:(HMService *)service toServiceGroup:(HMServiceGroup *)group {
    if (self.serviceGroup == group) {
        [self.tableView reloadData];
    }
}

- (void)home:(HMHome *)home didRemoveAccessory:(HMAccessory *)accessory {
    [self.tableView reloadData];
}

- (void)accessoryDidUpdateServices:(HMAccessory *)accessory {
    [self.tableView reloadData];
}

- (void)accessory:(HMAccessory *)accessory didUpdateNameForService:(HMService *)service {
    [self.tableView reloadData];
}

@end
