/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UITableViewCell to host a slider, its label and value.
 */

#import "SliderCell.h"

@implementation SliderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self != nil)
    {
        // Label for type of slider
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
        self.textLabel.textColor = [UIColor blackColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Slider
        UISlider *slider =
            [[UISlider alloc] initWithFrame:CGRectMake(self.contentView.bounds.origin.x + 55.0, 0.0,
                                                       self.contentView.bounds.size.width - 110.0, 40.0)];
        slider.continuous = YES;
        slider.tag = kSliderTag;
        [self.contentView addSubview:slider];
        
        // Label for slider values
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.font = [UIFont boldSystemFontOfSize:12.0];
        self.detailTextLabel.textColor = [UIColor blackColor];
    }
    return self;
}

@end
