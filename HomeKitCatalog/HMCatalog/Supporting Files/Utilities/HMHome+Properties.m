/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 An HMHome category that adds many abstractions for getting certain properties easily.
 */

#import "HMHome+Properties.h"
#import "HMService+Readability.h"

@implementation HMHome (Properties)

- (NSArray *)hmc_allServices {
    // Use KVC Collection Operators to isolate the individual services from all of the accessories.
    // Basically, concatenate each of the 'services' arrays.
    // https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/KeyValueCoding/Articles/CollectionOperators.html
    return [self.accessories valueForKeyPath:@"@unionOfArrays.services"];
}

- (NSDictionary *)hmc_serviceTable {
    // Create a mutable dictionary whose keys will correspond to the header titles in the table.
    NSMutableDictionary *serviceDictionary = [NSMutableDictionary dictionary];

    // Iterate through all of the services in the home.
    for (HMService *service in self.hmc_allServices) {

        // We don't want to display the Accessory Information or Lock Management services, so just skip them.
        if ([service.serviceType isEqualToString:HMServiceTypeAccessoryInformation] ||
            [service.serviceType isEqualToString:HMServiceTypeLockManagement]) {
            continue;
        }

        // Grab an existing list (or create one if there isn't a list in the dictionary corresponding to this service type.
        NSMutableArray *servicesInDictionary = serviceDictionary[service.hmc_localizedServiceType] ?: [NSMutableArray array];

        // Add the current service to the list of matching services.
        [servicesInDictionary addObject:service];

        // Reset the existing services in the dictionary.
        serviceDictionary[service.hmc_localizedServiceType] = servicesInDictionary;
    }
    return [NSDictionary dictionaryWithDictionary:serviceDictionary];
}

- (NSArray *)hmc_allRooms {
    return [@[self.roomForEntireHome] arrayByAddingObjectsFromArray:self.rooms];
}

- (HMAccessory *)hmc_accessoryWithIdentifier:(NSUUID *)identifier {
    for (HMAccessory *accessory in self.accessories) {
        if ([accessory.identifier isEqual:identifier]) {
            return accessory;
        }
    }
    return nil;
}

- (NSArray *)hmc_accessoriesWithIdentifiers:(NSArray *)identifiers {
    NSPredicate *identifierPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [identifiers containsObject:[evaluatedObject identifier]];
    }];
    return [self.accessories filteredArrayUsingPredicate:identifierPredicate];
}

- (HMAccessory *)hmc_bridgeForAccessory:(HMAccessory *)accessory {
    if (!accessory.bridged) {
        return nil;
    }
    for (HMAccessory *bridge in self.accessories) {
        if ([bridge.identifiersForBridgedAccessories containsObject:accessory.identifier]) {
            return bridge;
        }
    }
    return nil;
}

- (NSString *)hmc_nameForRoom:(HMRoom *)room {
    NSString *name = room.name;
    if (room == self.roomForEntireHome) {
        name = [name stringByAppendingFormat:@" (%@)", NSLocalizedString(@"Default Room", @"Default Room")];
    }
    return name;
}

- (NSArray *)hmc_roomsNotAlreadyInZone:(HMZone *)zone includingRooms:(NSArray *)rooms {
    NSMutableArray *allRooms = self.rooms.mutableCopy;
    [allRooms removeObjectsInArray:zone.rooms];
    if (rooms) {
        [allRooms addObjectsFromArray:rooms];
    }
    return [NSArray arrayWithArray:allRooms];
}

- (NSArray *)hmc_servicesNotAlreadyInServiceGroup:(HMServiceGroup *)serviceGroup includingServices:(NSArray *)services {
    NSMutableArray *allServices = self.hmc_allServices.mutableCopy;
    [allServices removeObjectsInArray:serviceGroup.services];
    if (services) {
        [allServices addObjectsFromArray:services];
    }
    return [NSArray arrayWithArray:allServices];
}

@end
