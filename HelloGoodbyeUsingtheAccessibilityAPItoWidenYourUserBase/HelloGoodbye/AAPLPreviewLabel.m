/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A custom label that appears on the Preview tab in the profile view controller.
  
 */

#import "AAPLPreviewLabel.h"
#import "AAPLStyleUtilities.h"

@implementation AAPLPreviewLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.text = NSLocalizedString(@"Preview", @"Name of the card preview tab");
        self.font = [AAPLStyleUtilities largeFont];
        self.textColor = [AAPLStyleUtilities previewTabLabelColor];
    }
    return self;
}

- (BOOL)accessibilityActivate {
    [self.delegate didActivatePreviewLabel:self];
    return YES;
}

- (UIAccessibilityTraits)accessibilityTraits {
    return ([super accessibilityTraits] | UIAccessibilityTraitButton);
}

@end
