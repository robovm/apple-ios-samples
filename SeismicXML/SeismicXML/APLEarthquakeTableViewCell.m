

/*
     File: APLEarthquakeTableViewCell.m
 Abstract: Table view cell to display an earthquake.
  Version: 3.5
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
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


@implementation APLEarthquakeTableViewCell

-(void)configureWithEarthquake:(APLEarthquake *)earthquake {

    self.locationLabel.text = earthquake.location;
    self.dateLabel.text = [NSString stringWithFormat:@"%@", [self.dateFormatter stringFromDate:earthquake.date]];
    self.magnitudeLabel.text = [NSString stringWithFormat:@"%.1f", earthquake.magnitude];
    self.magnitudeImage.image = [self imageForMagnitude:earthquake.magnitude];
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
	if (magnitude >= 2.0) {
		return [UIImage imageNamed:@"2.0.png"];
	}
	return nil;
}


// On-demand initializer for read-only property.
- (NSDateFormatter *)dateFormatter {

    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return dateFormatter;
}


@end
