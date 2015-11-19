/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UITableViewController that Displays a list of CLPlacemarks.
 */

@import UIKit;

@interface PlacemarksListViewController : UITableViewController

- (instancetype)initWithPlacemarks:(NSArray*)placemarks NS_DESIGNATED_INITIALIZER;

@end
