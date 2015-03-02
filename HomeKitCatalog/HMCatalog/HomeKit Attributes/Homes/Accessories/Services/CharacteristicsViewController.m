/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that displays a list of characteristics within an HMService.
 */

#import "CharacteristicsViewController.h"
#import "CharacteristicsTableViewDataSource.h"
#import "NSError+HomeKit.h"
#import "HMCharacteristic+Readability.h"
#import "HMHome+Properties.h"
#import "HomeViewController.h"

@interface CharacteristicsViewController ()

@property (nonatomic) CharacteristicsTableViewDataSource *tableViewDataSource;

@end

@implementation CharacteristicsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableViewDataSource = [CharacteristicsTableViewDataSource dataSourceWithService:self.service
                                                                               tableView:self.tableView
                                                                                delegate:self.cellDelegate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.title = self.service.name;
    [self reloadTableView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self setNotificationsEnabled:NO];
}

/**
 *  Sets notification enabled on every accessory if the accessory supports notification.
 *
 *  @param notificationsEnabled Whether to enable or disable notification.
 */
- (void)setNotificationsEnabled:(BOOL)notificationsEnabled {
    for (HMCharacteristic *characteristic in self.service.characteristics) {
        if (![characteristic.properties containsObject:HMCharacteristicPropertySupportsEventNotification]) {
            continue;
        }
        [characteristic enableNotification:notificationsEnabled completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Error enabling notification on %@: %@", characteristic.hmc_localizedCharacteristicType, error.hmc_localizedTranslation);
            }
        }];
    }
}

- (IBAction)reloadTableView {
    [self setNotificationsEnabled:YES];
    self.tableViewDataSource.service = self.service;
    self.service.accessory.delegate = self;
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

/**
 *  Tries to find a new service based on the previous service,
 *  but if that fails, pops off the navigation stack.
 */
- (void)homeStoreDidUpdateHomes {
    self.service = [self newServiceMatchingService:self.service];

    if (!self.service) {
        [self.navigationController popViewControllerAnimated:YES];
    }

    [self reloadTableView];
}

/**
 *  Searches through the home for a new instance of the now-stale
 *  service which we're holding.
 *
 *  First, search for an accessory that matches our stored accessory.
 *  If we find one:
 *     Search for one and only one service within that accessory's
 *     services array that matches based on service type.
 *     If there are more than one, reset it to nil and bail.
 *  Otherwise:
 *     If the service has a name:
 *        Search through all services on the home to find the 
 *        service that matches this service's name.
 *
 *  @param service The old service we want to replace.
 *
 *  @return A new, matching service within the home.
 */
- (HMService *)newServiceMatchingService:(HMService *)service {
    HMService *newService = nil;

    // Search for a new HMAccessory that matches based on UUID.
    HMAccessory *newAccessory = nil;
    for (HMAccessory *accessory in self.home.accessories) {
        if ([accessory.identifier isEqual:self.service.accessory.identifier]) {
            newAccessory = accessory;
            break;
        }
    }
    // If we were able to find a matching accessory,
    // search through it for one and only one service
    // with a matching service type.
    if (newAccessory) {
        for (HMService *service in newAccessory.services) {
            if ([service.serviceType isEqualToString:self.service.serviceType]) {
                if (!newService) {
                    newService = service;
                } else {
                    // If we've already found one matching service,
                    // this means we've found a second that matches.
                    // That means we can't be sure which is which,
                    // so we just bail the type-matching.
                    newService = nil;
                    break;
                }
            }
        }
    }
    // If we still don't have a matching service, fall back
    // to matching on name.
    if (!newService && self.service.name) {
        for (HMService *service in self.home.hmc_allServices) {
            if ([service.name isEqualToString:self.service.name]) {
                newService = service;
            }
        }
    }
    return newService;
}

#pragma mark - HMAccessoryDelegate Methods

/**
 *  If the accessory becomes unreachable while we're displaying its services,
 *  pop back to the home.
 */
- (void)accessoryDidUpdateReachability:(HMAccessory *)accessory {
    if (accessory == self.service.accessory && !accessory.reachable) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

/**
 *  Search for the cell corresponding to that characteristic and
 *  update its value.
 */
- (void)accessory:(HMAccessory *)accessory service:(HMService *)service didUpdateValueForCharacteristic:(HMCharacteristic *)characteristic {
    NSUInteger index = [self.service.characteristics indexOfObject:characteristic];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        CharacteristicCell *cell = (CharacteristicCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.value = characteristic.value;
    }
}

/**
 *  If HomeKit updates our associated service type, we need to respond to it.
 */
- (void)accessory:(HMAccessory *)accessory didUpdateAssociatedServiceTypeForService:(HMService *)service {
    if (service == self.service) {
        [self.tableViewDataSource didUpdateAssociatedServiceType];
    }
}

@end
