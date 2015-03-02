/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  CrumbPath is an MKOverlay model class representing a path that changes over time.
  
 */

@import MapKit;

@interface CrumbPath : NSObject <MKOverlay>

// Initialize the CrumbPath with the starting coordinate.
// The CrumbPath's boundingMapRect will be set to a sufficiently large square
// centered on the starting coordinate.
//
- (id)initWithCenterCoordinate:(CLLocationCoordinate2D)coord;

// Add a location observation. A MKMapRect containing the newly added point
// and the previously added point is returned so that the view can be updated
// in that rectangle.  If the added coordinate has not moved far enough from
// the previously added coordinate it will not be added to the list and 
// MKMapRectNull will be returned.
//
- (MKMapRect)addCoordinate:(CLLocationCoordinate2D)coord boundingMapRectChanged:(BOOL *)boundingMapRectChanged;

// Synchronously evaluate a block with the current buffer of points.
- (void)readPointsWithBlockAndWait:(void (^)(MKMapPoint *pointsArray, NSUInteger pointArrayCount))block;

@end
