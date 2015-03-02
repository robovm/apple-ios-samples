/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that provides a list of services and lets the user select services to be added to the provided Service Group.
  The services are not added to the service group until the 'Done' button is pressed.
 */

#import "AddServicesViewController.h"
#import "ServiceCell.h"
#import "HMHome+Properties.h"
#import "UIViewController+Convenience.h"
#import "UITableView+Updating.h"

@interface AddServicesViewController () <HMHomeDelegate>

@property (nonatomic) NSArray *displayedServices;
@property (nonatomic) NSMutableArray *selectedServices;

@end

@implementation AddServicesViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectedServices = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadTable];
}

/**
 *  Tries to find a new service group matching the old one,
 *  but if that fails, dismisses.
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
        [self dismiss];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.displayedServices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ServiceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ServiceCell" forIndexPath:indexPath];
    HMService *service = self.displayedServices[indexPath.row];
    cell.service = service;
    cell.accessoryType = [self.selectedServices containsObject:service] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self handleServiceSelectionAtIndexPath:indexPath];
}

/**
 *  When an indexPath is selected, this function either adds or removes the selected service from the
 *  service group.
 */
- (void)handleServiceSelectionAtIndexPath:(NSIndexPath *)indexPath {
    // Get the service associated with this index.
    HMService *service = self.displayedServices[indexPath.row];

    // Call the appropriate add/remove operation with the block from above.
    if ([self.selectedServices containsObject:service]) {
        [self.selectedServices removeObject:service];
    } else {
        [self.selectedServices addObject:service];
    }
    [self.tableView hmc_update:^(UITableView *tableView) {
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

/**
 *  Adds the selected services to the service group.
 *  
 *  Calls the provided completion handler once all services have been added.
 */
- (void)addSelectedServicesWithCompletionHandler:(void (^)())completion {
    // Create a dispatch group for each of the service additions.
    dispatch_group_t addServicesGroup = dispatch_group_create();
    __weak typeof(self) weakSelf = self;
    for (HMService *service in self.selectedServices) {
        dispatch_group_enter(addServicesGroup);
        [self.serviceGroup addService:service completionHandler:^(NSError *error) {
            if (error) {
                [weakSelf hmc_displayError:error];
            }
            dispatch_group_leave(addServicesGroup);
        }];
    }
    dispatch_group_notify(addServicesGroup, dispatch_get_main_queue(), completion);
}

- (IBAction)saveAndDismiss {
    __weak typeof(self) weakSelf = self;
    [self addSelectedServicesWithCompletionHandler:^{
        [weakSelf dismiss];
    }];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)reloadTable {
    [self resetDisplayedServices];
    [self.tableView reloadData];
}

- (void)resetDisplayedServices {
    self.displayedServices = [self.home hmc_servicesNotAlreadyInServiceGroup:self.serviceGroup includingServices:self.selectedServices];
}

@end
