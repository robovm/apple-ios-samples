/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A CharacteristicCell subclass that contains a slider. Used for numeric characteristics that have a wide range of options.
 */

#import "SliderCharacteristicCell.h"

@interface SliderCharacteristicCell ()

@property (weak, nonatomic) IBOutlet UISlider *valueSlider;

@end

@implementation SliderCharacteristicCell

/**
 *  @discussion Inherits the behavior of its superclass,
 *  as well as setting the slider's properties based on
 *  the characteristic's metadata.
 *
 *  @param characteristic The cell's characteristic.
 */
- (void)setCharacteristic:(HMCharacteristic *)characteristic {
    self.valueSlider.minimumValue = characteristic.metadata.minimumValue.doubleValue;
    self.valueSlider.maximumValue = characteristic.metadata.maximumValue.doubleValue;
    [super setCharacteristic:characteristic];
}

- (void)setValue:(id)value notify:(BOOL)notify {
    [super setValue:value notify:notify];
    if (!notify) {
        self.valueSlider.value = [value doubleValue];
    }
}

/**
 *  Sliders do not immediately push their updates to HomeKit. Rather, their values are to be gathered and sent
 *  after a certain amount of time.
 *
 *  @return Whether or not to send HomeKit a message immediately.
 */
+ (BOOL)updatesImmediately {
    return NO;
}

/**
 *  @discussion Restricts a value to the step value provided in the cell's
 *  characteristic's metadata.
 *
 *  @param sliderValue The provided value.
 *
 *  @return The value adjusted to align with a step value.
 */
- (NSNumber *)roundedValueForSliderValue:(float)value {
    if (!self.characteristic.metadata.stepValue || [self.characteristic.metadata.stepValue isEqualToNumber:@0]) {
        return @(value);
    }
    double stepValue = self.characteristic.metadata.stepValue.doubleValue;
    double newStep = round(value / stepValue);
    double stepped = newStep * stepValue;
    return @(stepped);
}

/**
 *  Responds to a change in slider value and alerts its delegate appropriately.
 *
 *  @param sender The slider which updated its value.
 */
- (IBAction)didChangeSliderValue:(UISlider *)sender {
    id newValue = [self roundedValueForSliderValue:sender.value];
    [self setValue:newValue notify:YES];
}

@end
