/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Displays the address data in the placemark acquired from the reverse geocoder.
 */

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface PlacemarkViewController : UITableViewController

@property (nonatomic, strong) MKPlacemark *placemark;

@end
