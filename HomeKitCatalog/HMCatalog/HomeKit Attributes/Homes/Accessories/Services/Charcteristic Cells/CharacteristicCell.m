/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableViewCell subclass that displays the current value of an HMCharacteristic and 
  notifies its delegate of changes. Subclasses of this class will provide additional controls to display different kinds of data.
 */

#import "CharacteristicCell.h"
#import "NSError+HomeKit.h"
#import "HMCharacteristic+Readability.h"
#import "HMCharacteristic+Properties.h"

@implementation CharacteristicCell

/**
 *  @discussion Saves the passed-in characteristic and sets up the cell based on the
 *  saved characteristic.
 *
 *  @param characteristic An HMCharacteristic.
 */
- (void)setCharacteristic:(HMCharacteristic *)characteristic {
    _characteristic = characteristic;
    self.typeLabel.text = _characteristic.hmc_localizedCharacteristicType;
    self.selectionStyle = _characteristic.hmc_isIdentify ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    // By default, fill in the current value with the characteristic's default.
    self.value = _characteristic.value ?: _characteristic.metadata.minimumValue;
    if (_characteristic.hmc_isWriteOnly) {
        return;
    }
    [self.delegate characteristicCell:self readInitialValueForCharacteristic:_characteristic completion:^(id value, NSError *error) {
        if (error) {
            NSLog(@"Error reading value for %@: %@", _characteristic.hmc_localizedCharacteristicType, error.hmc_localizedTranslation);
        } else {
            self.value = value;
        }
    }];
}

- (void)resetValueLabel {
    self.valueLabel.text = [self.characteristic hmc_localizedDescriptionForValue:self.value];
}

- (void)setValue:(id)value {
    [self setValue:value notify:NO];
}

+ (BOOL)updatesImmediately {
    return YES;
}

/**
 *  Sets the value that this cell represents, and optionally alerts its delegates.
 *
 *  @param newValue The new value to be set.
 *  @param notify   Whether or not to notify delegates.
 */
- (void)setValue:(id)newValue notify:(BOOL)notify {
    if ([newValue isEqual:_value]) {
        return;
    }
    _value = newValue;
    [self resetValueLabel];
    if (notify) {
        [self.delegate characteristicCell:self didUpdateValue:newValue forCharacteristic:self.characteristic immediate:[self.class updatesImmediately]];
    }
}

@end
