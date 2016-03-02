/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The custom MKAnnotation object representing Fisherman's Wharf.
 */

#import "WharfAnnotation.h"

@implementation WharfAnnotation

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D theCoordinate;
    theCoordinate.latitude = 37.808333;
    theCoordinate.longitude = -122.415556;
    return theCoordinate; 
}

// required if you set the MKPinAnnotationView's "canShowCallout" property to YES
- (NSString *)title
{
    return @"Fisherman's Wharf";
}

+ (MKAnnotationView *)createViewAnnotationForMapView:(MKMapView *)mapView annotation:(id <MKAnnotation>)annotation
{
    // try to dequeue an existing pin view first
    MKAnnotationView *returnedAnnotationView =
    [mapView dequeueReusableAnnotationViewWithIdentifier:NSStringFromClass([WharfAnnotation class])];
    if (returnedAnnotationView == nil)
    {
        returnedAnnotationView =
        [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                        reuseIdentifier:NSStringFromClass([WharfAnnotation class])];
        ((MKPinAnnotationView *)returnedAnnotationView).animatesDrop = YES;
        ((MKPinAnnotationView *)returnedAnnotationView).canShowCallout = YES;

#if TARGET_OS_IPHONE
        ((MKPinAnnotationView *)returnedAnnotationView).pinTintColor = [UIColor orangeColor];
#else
        ((MKPinAnnotationView *)returnedAnnotationView).pinTintColor = [NSColor orangeColor];
#endif
    }
    
    return returnedAnnotationView;
}

@end