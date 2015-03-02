/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A set of routines for determining localized descriptions of many different parts of a characteristic.
 */

@import HomeKit;

@interface HMCharacteristic (Readability)

/**
 *  The type of the characteristic, e.g. <code>@"Current Lock Mechanism State"</code>
 */
@property (nonatomic, readonly) NSString *hmc_localizedCharacteristicType;

/**
 *  A string representing the value in a localized way, e.g. <code>@"24%"</code> or <code>@"354º"</code>
 */
@property (nonatomic, readonly) NSString *hmc_localizedValueDescription;

/**
 *  The decoration for the characteristic's units, localized, e.g. <code>@"%"</code> or <code>@"º"</code>
 */
@property (nonatomic, readonly) NSString *hmc_localizedUnitDecoration;

/**
 * Whether or not this characteristic has value descriptions spearate from just displaying raw values, e.g. <code>Secured</code> or <code>Jammed</code> 
 */
@property (nonatomic, readonly) BOOL hmc_hasPredeterminedValueDescriptions;

/**
 *  Returns the localized description for a provided value, taking the characteristic's metadata and possible
 *  values into account.
 *
 *  @param value The value to look up.
 *
 *  @return A string representing the value in a localized way, e.g. <code>@"24%"</code> or <code>@"354º"</code>
 */
- (NSString *)hmc_localizedDescriptionForValue:(id)value;

@end
