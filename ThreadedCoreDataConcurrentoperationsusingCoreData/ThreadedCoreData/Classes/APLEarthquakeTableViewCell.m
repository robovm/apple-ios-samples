/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Table view cell to display an earthquake.
 */

#import "APLEarthquakeTableViewCell.h"
#import "APLEarthquake.h"

@interface APLEarthquakeTableViewCell ()

// References to the subviews which display the earthquake data.
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *magnitudeLabel;
@property (nonatomic, weak) IBOutlet UIImageView *magnitudeImage;

@property (nonatomic, readonly) NSDateFormatter *dateFormatter;

@end


#pragma mark -

@implementation APLEarthquakeTableViewCell

- (void)configureWithEarthquake:(APLEarthquake *)earthquake {

    self.locationLabel.text = earthquake.location;
    self.dateLabel.text = [NSString stringWithFormat:@"%@", [self.dateFormatter stringFromDate:earthquake.date]];
    self.magnitudeLabel.text = [NSString stringWithFormat:@"%.1f", [earthquake.magnitude floatValue]];
    self.magnitudeImage.image = [self imageForMagnitude:[earthquake.magnitude floatValue]];
}

// Based on the magnitude of the earthquake, return an image indicating its seismic strength.
- (UIImage *)imageForMagnitude:(CGFloat)magnitude {
    
    if (magnitude >= 5.0) {
		return [UIImage imageNamed:@"5.0.png"];
	}
	if (magnitude >= 4.0) {
		return [UIImage imageNamed:@"4.0.png"];
	}
	if (magnitude >= 3.0) {
		return [UIImage imageNamed:@"3.0.png"];
	}
	if (magnitude >= 0.0) {
		return [UIImage imageNamed:@"2.0.png"];
	}
	return nil;
}

// On-demand initializer for read-only property.
- (NSDateFormatter *)dateFormatter {

    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone localTimeZone];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    return dateFormatter;
}

@end
