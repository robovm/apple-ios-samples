/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UITableViewController that displays the propeties of a CLPlacemark.
 */

@import UIKit;
@import MapKit;

@interface PlacemarkViewController : UITableViewController <MKAnnotation>

- (instancetype)initWithPlacemark:(CLPlacemark *)placemark NS_DESIGNATED_INITIALIZER;

#pragma mark - MKAnnotation Protocol (for map pin)

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *title;

@end
