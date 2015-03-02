/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A set of routines for determining localized descriptions for many properties of HMService.
 */

#import "HMService+Readability.h"

static NSDictionary *_serviceTypeMap;
@implementation HMService (Readability)

+ (void)initialize {
    _serviceTypeMap = @{ HMServiceTypeLightbulb: NSLocalizedString(@"Lightbulb", @"Lightbulb"),
                         HMServiceTypeSwitch: NSLocalizedString(@"Switch", @"Switch"),
                         HMServiceTypeThermostat: NSLocalizedString(@"Thermostat", @"Thermostat"),
                         HMServiceTypeGarageDoorOpener: NSLocalizedString(@"Garage Door Opener", @"Garage Door Opener"),
                         HMServiceTypeAccessoryInformation: NSLocalizedString(@"Accessory Information", @"Accessory Information"),
                         HMServiceTypeFan: NSLocalizedString(@"Fan", @"Fan"),
                         HMServiceTypeOutlet: NSLocalizedString(@"Outlet", @"Outlet"),
                         HMServiceTypeLockMechanism: NSLocalizedString(@"Lock Mechanism", @"Lock Mechanism"),
                         HMServiceTypeLockManagement: NSLocalizedString(@"Lock Management", @"Lock Management") };
}

+ (NSString *)hmc_localizedDescriptionForServiceType:(NSString *)serviceType {
    return _serviceTypeMap[serviceType];
}

- (NSString *)hmc_localizedServiceType {
    // If we don't have a mapping, return the service type we were given.
    return [self.class hmc_localizedDescriptionForServiceType:self.serviceType] ?: self.serviceType;
}

- (BOOL)hmc_supportsAssociatedService {
    return [self.serviceType isEqualToString:HMServiceTypeOutlet] || [self.serviceType isEqualToString:HMServiceTypeSwitch];
}

+ (NSArray *)hmc_validAssociatedServiceTypes {
    return @[HMServiceTypeLightbulb,
             HMServiceTypeFan];
}

@end
