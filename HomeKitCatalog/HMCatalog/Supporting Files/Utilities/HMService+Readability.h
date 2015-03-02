/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A set of routines for determining localized descriptions for many properties of HMService.
 */

@import HomeKit;

@interface HMService (Readability)

/**
 *  The type of the Service, e.g. <code>@"Lightbulb"</code>
 */
@property (nonatomic, readonly) NSString *hmc_localizedServiceType;

/**
 *  Whether or not this service supports the <code>associatedServiceType</code> property.
 */
@property (nonatomic, readonly) BOOL hmc_supportsAssociatedService;

/**
 *  <b>Note:</b> the provided service type must be one of the <code>HMServiceType</code> constants.
 *
 *  @param serviceType The service type.
 *
 *  @return A localized description of that service type.
 */
+ (NSString *)hmc_localizedDescriptionForServiceType:(NSString *)serviceType;

/**
 *  @return The valid associated service types for this service, e.g. HMServiceTypeFan or HMServiceTypeLightbulb
 */
+ (NSArray *)hmc_validAssociatedServiceTypes;

@end
