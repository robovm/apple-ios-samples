/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableViewCell subclass that displays a characteristic's 'target value'.
 */

#import "ActionCell.h"
#import "HMCharacteristic+Readability.h"

@implementation ActionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    // Overwrite the style when being initialized.
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.detailTextLabel.textColor = [UIColor lightGrayColor];
    return self;
}

- (void)setCharacteristic:(HMCharacteristic *)characteristic targetValue:(id)value {
    NSString *targetDescription = [NSString stringWithFormat:@"%@ → %@", characteristic.hmc_localizedCharacteristicType, [characteristic hmc_localizedDescriptionForValue:value]];
    self.textLabel.text = targetDescription;

    NSString *contextDescription = NSLocalizedString(@"%@ in %@", @"Service in Accessory");
    self.detailTextLabel.text = [NSString stringWithFormat:contextDescription, characteristic.service.name, characteristic.service.accessory.name];
}

@end
