/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The annotation to represent a region that is being monitored.
 */

@import MapKit;

@interface RegionAnnotation : NSObject <MKAnnotation> {

}

@property (nonatomic, strong) CLRegion *region;
@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, readwrite) CLLocationDistance radius;
@property (nonatomic, copy) NSString *title;

- (instancetype)initWithCLRegion:(CLRegion *)newRegion;

@end
