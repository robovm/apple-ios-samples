/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A set of abstractions on HMCharacteristic that wrap common operations like checking if the characteristic is boolean, numeric, and floating point.
 */

#import "HMCharacteristic+Properties.h"
#import "HMCharacteristic+Readability.h"

@implementation HMCharacteristic (Properties)

- (BOOL)hmc_isReadOnly {
    return [self.properties containsObject:HMCharacteristicPropertyReadable] &&
           ![self.properties containsObject:HMCharacteristicPropertyWritable];
}

- (BOOL)hmc_isWriteOnly {
    return [self.properties containsObject:HMCharacteristicPropertyWritable] &&
           ![self.properties containsObject:HMCharacteristicPropertyReadable];
}

- (BOOL)hmc_isBoolean {
    return [self.metadata.format isEqualToString:HMCharacteristicMetadataFormatBool];
}

- (BOOL)hmc_isNumeric {
    static NSArray *numericFormats;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        numericFormats = @[HMCharacteristicMetadataFormatInt,
                           HMCharacteristicMetadataFormatFloat,
                           HMCharacteristicMetadataFormatUInt8,
                           HMCharacteristicMetadataFormatUInt16,
                           HMCharacteristicMetadataFormatUInt32,
                           HMCharacteristicMetadataFormatUInt64];
    });
    return [numericFormats containsObject:self.metadata.format];
}

- (BOOL)hmc_isInteger {
    return self.hmc_isNumeric && !self.hmc_isFloatingPoint;
}

- (BOOL)hmc_isFloatingPoint {
    return [self.metadata.format isEqualToString:HMCharacteristicMetadataFormatFloat];
}

- (NSInteger)hmc_numberOfChoices {
    double choices = (self.metadata.maximumValue.integerValue - self.metadata.minimumValue.integerValue);
    if (self.metadata.stepValue) {
        choices /= self.metadata.stepValue.integerValue;
    }
    return choices + 1;
}

- (NSArray *)hmc_allPossibleValues {
    if (!self.hmc_isInteger) {
        return nil;
    }
    NSMutableArray *values = [NSMutableArray array];
    NSInteger stepValue = 1;
    if (self.metadata.stepValue) {
        stepValue = self.metadata.stepValue.integerValue;
    }
    for (NSInteger i = 0; i < self.hmc_numberOfChoices; i += stepValue) {
        id choice = @(i);
        [values addObject:choice];
    }
    return [NSArray arrayWithArray:values];
}

- (BOOL)hmc_isIdentify {
    return [self.characteristicType isEqualToString:HMCharacteristicTypeIdentify];
}

@end
