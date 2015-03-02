/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A set of abstractions on HMCharacteristic that wrap common operations like checking if the characteristic is boolean, numeric, and floating point.
 */

@import HomeKit;

@interface HMCharacteristic (Properties)

/**
 *  This characteristic is read only.
 */
@property (nonatomic, readonly) BOOL hmc_isReadOnly;

/**
 *  This characteristic is write only.
 */
@property (nonatomic, readonly) BOOL hmc_isWriteOnly;

/**
 *  This characteristic is the 'Identify' characteristic.
 */
@property (nonatomic, readonly) BOOL hmc_isIdentify;

/**
 *  This characteristic is boolean.
 */
@property (nonatomic, readonly) BOOL hmc_isBoolean;

/**
 *  This characteristic has numeric values.
 */
@property (nonatomic, readonly) BOOL hmc_isNumeric;

/**
 *  This characteristic has numeric values that are all integers.
 */
@property (nonatomic, readonly) BOOL hmc_isInteger;

/**
 *  This characteristic has numeric values that are all floating point.
 */
@property (nonatomic, readonly) BOOL hmc_isFloatingPoint;

/**
 * Whether or not this characteristic has value descriptions spearate from just displaying raw values, e.g. <code>Secured</code> or <code>Jammed</code> 
 */
@property (nonatomic, readonly) BOOL hmc_hasPredeterminedValueDescriptions;

/**
 *  The number of possible values that this characteristic can contain.
 *  The standard formula for the number of values between two numbers is <code>((greater - lesser) + 1)</code>,
 *  and this takes step value into account.
 */
@property (nonatomic, readonly) NSInteger hmc_numberOfChoices;

/**
 *  All of the possible values that this characteristic can contain.
 */
@property (nonatomic, readonly) NSArray *hmc_allPossibleValues;

@end
