/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The custom annotation view to display a region that is being monitored.
 */

#import <MapKit/MapKit.h>

@class RegionAnnotation;

@interface RegionAnnotationView : MKPinAnnotationView {	

}


@property (nonatomic, weak) MKMapView *map;
@property (nonatomic, weak) RegionAnnotation *theAnnotation;

- (instancetype)initWithAnnotation:(id <MKAnnotation>)annotation NS_DESIGNATED_INITIALIZER;
- (void)updateRadiusOverlay;
- (void)removeRadiusOverlay;

@end