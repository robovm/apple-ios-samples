/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A set of routines for determining localized descriptions of many different parts of a characteristic.
 */

#import "HMCharacteristic+Readability.h"
#import "HMCharacteristic+Properties.h"

static NSDictionary *_characteristicTypeMap;
static NSDictionary *_characteristicValueMap;
static NSDictionary *_characteristicUnitMap;
static NSNumberFormatter *_valueFormatter;

@implementation HMCharacteristic (Readability)

+ (void)initialize {
    [super initialize];
    _characteristicTypeMap = @{ HMCharacteristicTypePowerState: NSLocalizedString(@"Power State", @"Power State"),
                                HMCharacteristicTypeHue: NSLocalizedString(@"Hue", @"Hue"),
                                HMCharacteristicTypeSaturation: NSLocalizedString(@"Saturation", @"Saturation"),
                                HMCharacteristicTypeBrightness: NSLocalizedString(@"Brightness", @"Brightness"),
                                HMCharacteristicTypeTemperatureUnits: NSLocalizedString(@"Temperature Units", @"Temperature Units"),
                                HMCharacteristicTypeCurrentTemperature: NSLocalizedString(@"Current Temperature", @"Current Temperature"),
                                HMCharacteristicTypeTargetTemperature: NSLocalizedString(@"Target Temperature", @"Target Temperature"),
                                HMCharacteristicTypeCoolingThreshold: NSLocalizedString(@"Cooling Threshold", @"Cooling Threshold"),
                                HMCharacteristicTypeHeatingThreshold: NSLocalizedString(@"Heating Threshold", @"Heating Threshold"),
                                HMCharacteristicTypeCurrentRelativeHumidity: NSLocalizedString(@"Current Relative Humidity", @"Current Relative Humidity"),
                                HMCharacteristicTypeTargetRelativeHumidity: NSLocalizedString(@"Target Relative Humidity", @"Target Relative Humidity"),
                                HMCharacteristicTypeCurrentDoorState: NSLocalizedString(@"Current Door State", @"Current Door State"),
                                HMCharacteristicTypeTargetDoorState: NSLocalizedString(@"Target Door State", @"Target Door State"),
                                HMCharacteristicTypeObstructionDetected: NSLocalizedString(@"Obstruction Detected", @"Obstruction Detected"),
                                HMCharacteristicTypeName: NSLocalizedString(@"Name", @"Name"),
                                HMCharacteristicTypeManufacturer: NSLocalizedString(@"Manufacturer", @"Manufacturer"),
                                HMCharacteristicTypeModel: NSLocalizedString(@"Model", @"Model"),
                                HMCharacteristicTypeSerialNumber: NSLocalizedString(@"Serial Number", @"Serial Number"),
                                HMCharacteristicTypeIdentify: NSLocalizedString(@"Identify", @"Identify"),
                                HMCharacteristicTypeRotationDirection: NSLocalizedString(@"Rotation Direction", @"Rotation Direction"),
                                HMCharacteristicTypeRotationSpeed: NSLocalizedString(@"Rotation Speed", @"Rotation Speed"),
                                HMCharacteristicTypeOutletInUse: NSLocalizedString(@"Outlet In Use", @"Outlet In Use"),
                                HMCharacteristicTypeVersion: NSLocalizedString(@"Version", @"Version"),
                                HMCharacteristicTypeLogs: NSLocalizedString(@"Logs", @"Logs"),
                                HMCharacteristicTypeAudioFeedback: NSLocalizedString(@"Audio Feedback", @"Audio Feedback"),
                                HMCharacteristicTypeAdminOnlyAccess: NSLocalizedString(@"Admin Only Access", @"Admin Only Access"),
                                HMCharacteristicTypeMotionDetected: NSLocalizedString(@"Motion Detected", @"Motion Detected"),
                                HMCharacteristicTypeCurrentLockMechanismState: NSLocalizedString(@"Current Lock Mechanism State", @"Current Lock Mechanism State"),
                                HMCharacteristicTypeTargetLockMechanismState: NSLocalizedString(@"Target Lock Mechanism State", @"Target Lock Mechanism State"),
                                HMCharacteristicTypeLockMechanismLastKnownAction: NSLocalizedString(@"Lock Mechanism Last Known Action", @"Lock Mechanism Last Known Action"),
                                HMCharacteristicTypeLockManagementControlPoint: NSLocalizedString(@"Lock Management Control Point", @"Lock Management Control Point"),
                                HMCharacteristicTypeLockManagementAutoSecureTimeout: NSLocalizedString(@"Lock Management Auto Secure Timeout", @"Lock Management Auto Secure Timeout"),
                                HMCharacteristicTypeTargetHeatingCooling: NSLocalizedString(@"Target Mode", @"Target Mode"),
                                HMCharacteristicTypeCurrentHeatingCooling: NSLocalizedString(@"Current Mode", @"Current Mode") };

    NSMutableDictionary *characteristicValueMap = @{ HMCharacteristicTypePowerState: @{@NO: NSLocalizedString(@"Off", @"Off"),
                                                                                       @YES: NSLocalizedString(@"On", @"On")},
                                                     HMCharacteristicTypeObstructionDetected: @{@NO: NSLocalizedString(@"No", @"No"),
                                                                                                @YES: NSLocalizedString(@"Yes", @"Yes")},
                                                     HMCharacteristicTypeTargetDoorState: @{@(HMCharacteristicValueDoorStateOpen): NSLocalizedString(@"Open", @"Open"),
                                                                                            @(HMCharacteristicValueDoorStateOpening): NSLocalizedString(@"Opening", @"Opening"),
                                                                                            @(HMCharacteristicValueDoorStateClosed): NSLocalizedString(@"Closed", @"Closed"),
                                                                                            @(HMCharacteristicValueDoorStateClosing): NSLocalizedString(@"Closing", @"Closing"),
                                                                                            @(HMCharacteristicValueDoorStateStopped): NSLocalizedString(@"Stopped", @"Stopped")},
                                                     HMCharacteristicTypeTargetHeatingCooling: @{@(HMCharacteristicValueHeatingCoolingOff): NSLocalizedString(@"Off", @"Off"),
                                                                                                 @(HMCharacteristicValueHeatingCoolingHeat): NSLocalizedString(@"Heat", @"Heat"),
                                                                                                 @(HMCharacteristicValueHeatingCoolingCool): NSLocalizedString(@"Cool", @"Cool"),
                                                                                                 @(HMCharacteristicValueHeatingCoolingAuto): NSLocalizedString(@"Auto", @"Auto")},
                                                     HMCharacteristicTypeCurrentHeatingCooling: @{@(HMCharacteristicValueHeatingCoolingOff): NSLocalizedString(@"Off", @"Off"),
                                                                                                  @(HMCharacteristicValueHeatingCoolingHeat): NSLocalizedString(@"Heating", @"Heating"),
                                                                                                  @(HMCharacteristicValueHeatingCoolingCool): NSLocalizedString(@"Cooling", @"Cooling")},
                                                     HMCharacteristicTypeTargetLockMechanismState: @{@(HMCharacteristicValueLockMechanismStateUnsecured): NSLocalizedString(@"Unsecured", @"Unsecured"),
                                                                                                     @(HMCharacteristicValueLockMechanismStateSecured): NSLocalizedString(@"Secured", @"Secured"),
                                                                                                     @(HMCharacteristicValueLockMechanismStateUnknown): NSLocalizedString(@"Unknown", @"Unknown"),
                                                                                                     @(HMCharacteristicValueLockMechanismStateJammed): NSLocalizedString(@"Jammed", @"Jammed")},
                                                     HMCharacteristicTypeTemperatureUnits: @{@(HMCharacteristicValueTemperatureUnitCelsius): NSLocalizedString(@"Celsius", @"Celsius"),
                                                                                             @(HMCharacteristicValueTemperatureUnitFahrenheit): NSLocalizedString(@"Fahrenheit", @"Fahrenheit")},
                                                     HMCharacteristicTypeLockMechanismLastKnownAction: @{@(HMCharacteristicValueLockMechanismLastKnownActionSecuredRemotely): NSLocalizedString(@"Remotely Secured", @"Remotely Secured"),
                                                                                                         @(HMCharacteristicValueLockMechanismLastKnownActionUnsecuredRemotely): NSLocalizedString(@"Remotely Unsecured", @"Remotely Unsecured"),
                                                                                                         @(HMCharacteristicValueLockMechanismLastKnownActionSecuredWithKeypad): NSLocalizedString(@"Keypad Secured", @"Keypad Secured"),
                                                                                                         @(HMCharacteristicValueLockMechanismLastKnownActionUnsecuredWithKeypad): NSLocalizedString(@"Keypad Unsecured", @"Keypad Unsecured"),
                                                                                                         @(HMCharacteristicValueLockMechanismLastKnownActionSecuredWithAutomaticSecureTimeout): NSLocalizedString(@"Automatically Secured", @"Automatically Secured"),
                                                                                                         @(HMCharacteristicValueLockMechanismLastKnownActionSecuredUsingPhysicalMovementExterior): NSLocalizedString(@"Exterior Secured", @"Exterior Secured"),
                                                                                                         @(HMCharacteristicValueLockMechanismLastKnownActionSecuredUsingPhysicalMovementInterior): NSLocalizedString(@"Interior Secured", @"Interior Secured"),
                                                                                                         @(HMCharacteristicValueLockMechanismLastKnownActionUnsecuredUsingPhysicalMovementExterior): NSLocalizedString(@"Exterior Unsecured", @"Exterior Unsecured"),
                                                                                                         @(HMCharacteristicValueLockMechanismLastKnownActionUnsecuredUsingPhysicalMovementInterior): NSLocalizedString(@"Interior Unsecured", @"Interior Unsecured")}}.mutableCopy;

    // The current/target values are exactly the same, so just copy their maps over.
    characteristicValueMap[HMCharacteristicTypeCurrentDoorState] = characteristicValueMap[HMCharacteristicTypeTargetDoorState];
    characteristicValueMap[HMCharacteristicTypeCurrentLockMechanismState] = characteristicValueMap[HMCharacteristicTypeTargetLockMechanismState];
    characteristicValueMap[HMCharacteristicTypeOutletInUse] = characteristicValueMap[HMCharacteristicTypeObstructionDetected];
    characteristicValueMap[HMCharacteristicTypeMotionDetected] = characteristicValueMap[HMCharacteristicTypeObstructionDetected];
    characteristicValueMap[HMCharacteristicTypeAdminOnlyAccess] = characteristicValueMap[HMCharacteristicTypeObstructionDetected];
    characteristicValueMap[HMCharacteristicTypeAudioFeedback] = characteristicValueMap[HMCharacteristicTypeObstructionDetected];
    _characteristicValueMap = [NSDictionary dictionaryWithDictionary:characteristicValueMap];

    _characteristicUnitMap = @{ HMCharacteristicMetadataUnitsCelsius: NSLocalizedString(@"℃", @"Degrees Celsius"),
                                HMCharacteristicMetadataUnitsArcDegree: NSLocalizedString(@"º", @"Arc Degrees"),
                                HMCharacteristicMetadataUnitsFahrenheit: NSLocalizedString(@"℉", @"Degrees Fahrenheit"),
                                HMCharacteristicMetadataUnitsPercentage: NSLocalizedString(@"%", @"Percentage") };

    _valueFormatter = [NSNumberFormatter new];
    // Always show at least one digit.
    _valueFormatter.minimumIntegerDigits = 1;
}

- (BOOL)hmc_hasPredeterminedValueDescriptions {
    return _characteristicValueMap[self.characteristicType] != nil;
}

- (NSString *)hmc_localizedUnitDecoration {
    NSString *unit = _characteristicUnitMap[self.metadata.units];
    if (unit) {
        return unit;
    }
    return @"";
}

- (NSString *)hmc_localizedCharacteristicType {
    NSString *type = _characteristicTypeMap[self.characteristicType] ?: self.characteristicType;
    if (self.hmc_isReadOnly) {
        type = [type stringByAppendingFormat:@" (%@)", NSLocalizedString(@"Read Only", @"Read Only")];
    } else if (self.hmc_isWriteOnly) {
        type = [type stringByAppendingFormat:@" (%@)", NSLocalizedString(@"Write Only", @"Write Only")];
    }
    return type;
}

- (NSString *)hmc_localizedValueDescription {
    return [self hmc_localizedDescriptionForValue:self.value];
}

- (NSString *)hmc_localizedDescriptionForValue:(id)value {
    if (self.hmc_isIdentify) {
        return NSLocalizedString(@"Tap to Identify", @"Tap to Identify");
    }
    if (self.hmc_isWriteOnly) {
        return NSLocalizedString(@"Write-Only Characterisic", @"Write-Only Characteristic");
    }
    // First, look up if we've specified values for that characteristic type.
    NSDictionary *typeValueMap = _characteristicValueMap[self.characteristicType];
    if (typeValueMap) {
        return typeValueMap[value];
        // If we don't have anything in that, then begin constructing a value
        // for numeric characteristics.
    } else if (self.hmc_isNumeric) {
        // This formula will give you the number of decimal digits contained in a given step value.
        _valueFormatter.minimumFractionDigits = log10(1.0 / self.metadata.stepValue.doubleValue);
        // Append the unit decorator to the value description.
        return [[_valueFormatter stringFromNumber:value] stringByAppendingString:self.hmc_localizedUnitDecoration];
    }
    // Otherwise just return the value itself.
    return [value description];
}

@end
