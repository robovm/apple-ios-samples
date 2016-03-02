/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This controller displays the map and allows the user to set regions to monitor.
 */

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface RegionsViewController : UIViewController {

}

@property (nonatomic, weak) IBOutlet UITableView *updatesTableView;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end
