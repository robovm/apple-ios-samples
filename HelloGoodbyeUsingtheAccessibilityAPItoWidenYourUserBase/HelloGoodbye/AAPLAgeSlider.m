/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A custom slider that allows users to adjust their age.
  
 */

#import "AAPLAgeSlider.h"
#import "AAPLStyleUtilities.h"

@implementation AAPLAgeSlider

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.tintColor = [AAPLStyleUtilities foregroundColor];
        self.minimumValue = 18;
        self.maximumValue = 120;
    }
    return self;
}

- (NSString *)accessibilityValue {
    // Return the age as a number, not as a percentage
    return [NSNumberFormatter localizedStringFromNumber:@(self.value) numberStyle:NSNumberFormatterDecimalStyle];
}

- (void)accessibilityIncrement {
    self.value++;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)accessibilityDecrement {
    self.value--;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
