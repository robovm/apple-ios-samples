/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A CharacteristicCell subclass that contains a single switch. Used for Boolean characteristics.
 */

#import "SwitchCharacteristicCell.h"

@interface SwitchCharacteristicCell ()

@property (weak, nonatomic) IBOutlet UISwitch *valueSwitch;

@end

@implementation SwitchCharacteristicCell

- (void)setValue:(id)value notify:(BOOL)notify {
    [super setValue:value notify:notify];
    if (!notify) {
        [self.valueSwitch setOn:[value boolValue] animated:YES];
    }
}

/**
 *  Respond to a switch-flip and alerts its delegate as appropriate.
 *
 *  @param sender The switch which was flipped.
 */
- (IBAction)didChangeSwitchValue:(UISwitch *)sender {
    [self setValue:@(sender.on) notify:YES];
}

@end
