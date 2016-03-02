/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The custom MKAnnotation object representing the Golden Gate Bridge.
 */

#import "BridgeAnnotation.h"

@implementation BridgeAnnotation

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D theCoordinate;
    theCoordinate.latitude = 37.810000;
    theCoordinate.longitude = -122.477450;
    return theCoordinate; 
}

// required if you set the MKPinAnnotationView's "canShowCallout" property to YES
- (NSString *)title
{
    return @"Golden Gate Bridge";
}

// optional
- (NSString *)subtitle
{
    return @"Opened: May 27, 1937";
}

+ (MKAnnotationView *)createViewAnnotationForMapView:(MKMapView *)mapView annotation:(id <MKAnnotation>)annotation
{
    // try to dequeue an existing pin view first
    MKAnnotationView *returnedAnnotationView =
        [mapView dequeueReusableAnnotationViewWithIdentifier:NSStringFromClass([BridgeAnnotation class])];
    if (returnedAnnotationView == nil)
    {
        returnedAnnotationView =
            [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                            reuseIdentifier:NSStringFromClass([BridgeAnnotation class])];

        ((MKPinAnnotationView *)returnedAnnotationView).pinTintColor = [MKPinAnnotationView purplePinColor];
        ((MKPinAnnotationView *)returnedAnnotationView).animatesDrop = YES;
        ((MKPinAnnotationView *)returnedAnnotationView).canShowCallout = YES;
    }
    
    return returnedAnnotationView;
}

@end