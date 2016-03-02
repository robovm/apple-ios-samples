/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The custom MKAnnotation object representing the city of San Francisco.
 */

#import "SFAnnotation.h"

@implementation SFAnnotation 

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D theCoordinate;
    theCoordinate.latitude = 37.786996;
    theCoordinate.longitude = -122.419281;
    return theCoordinate; 
}

- (NSString *)title
{
    return @"San Francisco";
}

// optional
- (NSString *)subtitle
{
    return @"Founded: June 29, 1776";
}

+ (MKAnnotationView *)createViewAnnotationForMapView:(MKMapView *)mapView annotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *returnedAnnotationView =
        [mapView dequeueReusableAnnotationViewWithIdentifier:NSStringFromClass([SFAnnotation class])];
    if (returnedAnnotationView == nil)
    {
        returnedAnnotationView =
            [[MKAnnotationView alloc] initWithAnnotation:annotation
                                         reuseIdentifier:NSStringFromClass([SFAnnotation class])];

        returnedAnnotationView.canShowCallout = YES;
  
        // offset the flag annotation so that the flag pole rests on the map coordinate
        returnedAnnotationView.centerOffset = CGPointMake( returnedAnnotationView.centerOffset.x + returnedAnnotationView.image.size.width/2, returnedAnnotationView.centerOffset.y - returnedAnnotationView.image.size.height/2 );
    }
    else
    {
        returnedAnnotationView.annotation = annotation;
    }
    return returnedAnnotationView;
}

@end
