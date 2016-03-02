
/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Table view cell to display an earthquake.
 */

@import UIKit;

@class APLEarthquake;

@interface APLEarthquakeTableViewCell : UITableViewCell

- (void)configureWithEarthquake:(APLEarthquake *)earthquake;

@end
