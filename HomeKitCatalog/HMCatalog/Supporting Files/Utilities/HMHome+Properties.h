/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 An HMHome category that adds many abstractions for getting certain properties easily.
 */

@import HomeKit;

@interface HMHome (Properties)

/**
 *  All the services within all the accessories within the home.
 */
@property (nonatomic, readonly) NSArray *hmc_allServices;

/**
 *  All rooms in the home, including -[HMHome roomForEntireHome].
 */
@property (nonatomic, readonly) NSArray *hmc_allRooms;

/**
 *  A dictionary mapping localized service types to an array of all services
 *  of that type.
 */
@property (nonatomic, readonly) NSDictionary *hmc_serviceTable;

/**
 *  Searches through the home's accessories to find the accessory
 *  that is bridging the provided accessory.
 *
 *  @param accessory The bridged accessory.
 *
 *  @return The accessory bridging the bridged accessory.
 */
- (HMAccessory *)hmc_bridgeForAccessory:(HMAccessory *)accessory;

/**
 *  @param identifiers An array of <code>NSUUID</code>s that match accessories in the receiver.
 *
 *  @return an array of <code>HMAccessory</code> instances corresponding to
 *  the UUIDs passed in.
 *
 */
- (NSArray *)hmc_accessoriesWithIdentifiers:(NSArray *)identifiers;

/**
 *  @param identifier The UUID to look up.
 *
 *  @return the accessory within the receiver that matches the given UUID, or nil if there
 *  is no accessory with that UUID.
 */
- (HMAccessory *)hmc_accessoryWithIdentifier:(NSUUID *)identifier;

/**
 *  @param room The room.
 *
 *  @return the name of the room, appending "Default Room" if the room is the home's
 *  <code>roomForEntireHome</code>
 */
- (NSString *)hmc_nameForRoom:(HMRoom *)room;

/**
 *  @param zone  The zone.
 *  @param rooms A list of rooms to add to the final list.
 *
 *  @return a list of rooms that exist in the home and have not yet been added to this zone.
 */
- (NSArray *)hmc_roomsNotAlreadyInZone:(HMZone *)zone includingRooms:(NSArray *)rooms;

/**
 *  @param home         The home.
 *  @param serviceGroup The service group.
 *  @param services     A list of services to add to the final list.
 *
 *  @return a list of services that exist in the home and have not yet been added to this service group.
 */
- (NSArray *)hmc_servicesNotAlreadyInServiceGroup:(HMServiceGroup *)serviceGroup includingServices:(NSArray *)services;

@end
