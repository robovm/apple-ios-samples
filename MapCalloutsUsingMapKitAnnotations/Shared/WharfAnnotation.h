/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The custom MKAnnotation object representing Fisherman's Wharf.
 */

#import <MapKit/MapKit.h>

@interface WharfAnnotation : NSObject <MKAnnotation>

+ (MKAnnotationView *)createViewAnnotationForMapView:(MKMapView *)mapView annotation:(id <MKAnnotation>)annotation;

@end
