/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  UITableViewController that displays the propeties of a CLPlacemark.
  
 */

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface PlacemarkViewController : UITableViewController <MKAnnotation>

// designated initilizers
//
// show the map and coordinate above the address info.
- (instancetype)initWithPlacemark:(CLPlacemark *)placemark preferCoord:(BOOL)shouldPreferCoord NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithPlacemark:(CLPlacemark *)placemark;


#pragma mark - MKAnnotation Protocol (for map pin)

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *title;

@end
