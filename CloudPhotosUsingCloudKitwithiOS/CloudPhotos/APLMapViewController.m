/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The view controller responsible for showing the location a CKRecord photo was taken.
 */

#import "APLMapViewController.h"

@import MapKit;

@interface APLMapViewController () <MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet MKMapView *mapView;

@end


#pragma mark -

@implementation APLMapViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.location != nil)
    {
        MKCoordinateRegion newRegion;
        newRegion.center.latitude = self.location.coordinate.latitude;
        newRegion.center.longitude = self.location.coordinate.longitude;
        newRegion.span.latitudeDelta = 0.008;
        newRegion.span.longitudeDelta = 0.008;
        self.mapView.region = newRegion;
        
        MKPointAnnotation *myAnnotation = [[MKPointAnnotation alloc] init];
        myAnnotation.coordinate = self.location.coordinate;;

        // get nearby address for our callout
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:self.location completionHandler:^(NSArray *placemarks, NSError *error) {
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                if (placemarks != nil && placemarks.count > 0)
                {
                    CLPlacemark *placemark = placemarks[0];
                    if (placemark.locality != nil && placemark.administrativeArea != nil)
                    {
                        myAnnotation.title = self.title;
                        if (placemark.thoroughfare != nil)
                        {
                            myAnnotation.subtitle =
                                [NSString stringWithFormat:@"%@: %@, %@", placemark.thoroughfare, placemark.locality, placemark.administrativeArea];
                        }
                        else
                        {
                            myAnnotation.subtitle =
                                [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.administrativeArea];
                        }
                        [self.mapView addAnnotation:myAnnotation];
                        [self.mapView selectAnnotation:myAnnotation animated:NO];
                    }
                }
            });
        }];
    }
}

@end

