/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The custom MKAnnotation object representing a generic location, hosting a title and image.
 */

#import "CustomAnnotation.h"
#import "CustomAnnotationView.h"    // MKAnnotationView for the Tea Garden

@implementation CustomAnnotation

+ (MKAnnotationView *)createViewAnnotationForMapView:(MKMapView *)mapView annotation:(id <MKAnnotation>)annotation
{
    MKAnnotationView *returnedAnnotationView =
        (CustomAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:NSStringFromClass([CustomAnnotation class])];
    if (returnedAnnotationView == nil)
    {
        returnedAnnotationView =
        [[CustomAnnotationView alloc] initWithAnnotation:annotation
                                         reuseIdentifier:NSStringFromClass([CustomAnnotation class])];
    }
    
    return returnedAnnotationView;
}

@end
