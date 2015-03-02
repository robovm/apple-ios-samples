/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLCell.h"
#import "AAPLCustomCellBackground.h"

@interface AAPLCell ()
@property (nonatomic, strong) UIColor *labelColor;
@end


#pragma mark -

@implementation AAPLCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.selectedBackgroundView = [[AAPLCustomCellBackground customCellBackground] init];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    
    [super setSelected:selected];
    if (selected) {
        _labelColor = self.label.textColor;
        self.label.textColor = [UIColor blackColor];
        [self setNeedsDisplay];
    }
    else {
        if (self.labelColor)
            self.label.textColor = self.labelColor;
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    
    [super setHighlighted:highlighted];
    if (highlighted) {
        _labelColor = self.label.textColor;
        self.label.textColor = [UIColor blackColor];
        [self setNeedsDisplay];
    }
    else {
        if (self.labelColor)
            self.label.textColor = self.labelColor;
    }
}

@end
