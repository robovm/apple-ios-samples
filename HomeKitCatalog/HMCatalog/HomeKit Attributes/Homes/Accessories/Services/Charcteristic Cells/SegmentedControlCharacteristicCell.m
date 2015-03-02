/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A CharacteristicCell subclass that contains a UISegmentedControl. Used for HMCharacteristics which have associated, non-numeric values, like Lock Management State.
 */

#import "SegmentedControlCharacteristicCell.h"
#import "HMCharacteristic+Readability.h"
#import "HMCharacteristic+Properties.h"
@interface SegmentedControlCharacteristicCell ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic) NSArray *possibleValues;

@end

@implementation SegmentedControlCharacteristicCell

- (void)setCharacteristic:(HMCharacteristic *)characteristic {
    [super setCharacteristic:characteristic];
    self.possibleValues = characteristic.hmc_allPossibleValues;
}

/**
 *  Re-creates the segmented control with the appropriate values.
 *
 *  @param possibleValues All possible values for the characteristic.
 */
- (void)setPossibleValues:(NSArray *)possibleValues {
    _possibleValues = possibleValues;
    [self.segmentedControl removeAllSegments];
    for (NSUInteger idx = 0; idx < _possibleValues.count; idx++) {
        id value = _possibleValues[idx];
        NSString *title = [self.characteristic hmc_localizedDescriptionForValue:value];
        [self.segmentedControl insertSegmentWithTitle:title
                                              atIndex:idx
                                             animated:NO];
    }
    [self resetSelectedIndex];
}

/**
 *  If this wasn't self-originated, then reset the selected segment on the segmented
 *  control to reflect the new value.
 */
- (void)setValue:(id)newValue notify:(BOOL)notify {
    [super setValue:newValue notify:notify];
    if (!notify) {
        [self resetSelectedIndex];
    }
}

- (void)resetSelectedIndex {
    self.segmentedControl.selectedSegmentIndex = [self.possibleValues indexOfObject:self.value];
}

/**
 *  Responds to a change in selected index, and notifies
 *  its delegate as appropriate.
 *
 *  @param sender The segmented control which was selected.
 */
- (IBAction)segmentedControlDidChange:(UISegmentedControl *)sender {
    id value = self.possibleValues[sender.selectedSegmentIndex];
    [self setValue:value notify:YES];
}

@end
