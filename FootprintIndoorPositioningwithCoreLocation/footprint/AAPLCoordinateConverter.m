/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                This class converts coordinates from Geographic coordinate system to floorplan space.
            
*/

#import "AAPLCoordinateConverter.h"
@import MapKit;

// Struct that contains a point in meters (east and south) with respect to an origin point (in geographic space)
// We use East & South because when drawing on an image, origin (0,0) is on the top-left.
// So +eastMeters corresponds to +x and +southMeters corresponds to +y
typedef struct {
    CLLocationDistance east;
    CLLocationDistance south;
} AAPLEastSouthDistance;

@interface AAPLCoordinateConverter()

@property (assign, nonatomic) double radiansRotated;

// We pick one of the anchors on the floorplan as an origin point that we will compute distance relative to.
@property (assign, nonatomic) MKMapPoint fromAnchorMKPoint;

@property (assign, nonatomic) CGPoint fromAnchorFloorplanPoint;

@end

@implementation AAPLCoordinateConverter

// Convenience function to convert a MapKit co-ordinate into a co-ordinate meters East/South relative to some origin.
+ (AAPLEastSouthDistance)metersFromPoint:(const MKMapPoint)fromAnchorMKPoint toPoint:(const MKMapPoint)to {
    CLLocationDistance metersPerMapPoint = MKMetersPerMapPointAtLatitude(MKCoordinateForMapPoint(fromAnchorMKPoint).latitude);

    AAPLEastSouthDistance eastSouthDistance = {
        .east = (to.x - fromAnchorMKPoint.x) * metersPerMapPoint,
        .south = (to.y - fromAnchorMKPoint.y) * metersPerMapPoint,
    };
    return eastSouthDistance;
}

- (instancetype) initWithCoordinatesTopLeft:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight imageSize:(CGSize)imageSize {

    AAPLGeoAnchor topLeftAnchor = {
        .latitudeLongitude = topLeft,
        .pixel = CGPointMake(0, 0)
    };

    AAPLGeoAnchor bottomRightAnchor = {
        .latitudeLongitude = bottomRight,
        .pixel = CGPointMake(imageSize.width, imageSize.height)
    };

    AAPLGeoAnchorPair anchorPair = {
        .fromAnchor = topLeftAnchor,
        .toAnchor = bottomRightAnchor
    };

    return [self initWithAnchors:anchorPair];
}

- (instancetype)initWithAnchors:(AAPLGeoAnchorPair)anchors {
    self = [super init];
    if (self) {
        // To compute the distance between two geographical co-ordinates, we first need to
        // convert to MapKit co-ordinates...
        _fromAnchorFloorplanPoint = anchors.fromAnchor.pixel;
        _fromAnchorMKPoint = MKMapPointForCoordinate(anchors.fromAnchor.latitudeLongitude);
        MKMapPoint toAnchorMapkitPoint = MKMapPointForCoordinate(anchors.toAnchor.latitudeLongitude);

        CGFloat xDistance = anchors.toAnchor.pixel.x - anchors.fromAnchor.pixel.x;
        CGFloat yDistance = anchors.toAnchor.pixel.y - anchors.fromAnchor.pixel.y;

        // ... so that we can use MapKit's helper function to compute distance.
        // this helper function takes into account the curvature of the earth.
        CLLocationDistance distanceBetweenPointsMeters = MKMetersBetweenMapPoints(_fromAnchorMKPoint, toAnchorMapkitPoint);

        // Distance between two points in pixels (on the floorplan image)
        CGFloat distanceBetweenPointsPixels = hypotf(xDistance, yDistance);

        // Get the 2nd anchor's eastward/southward distance in meters from the first anchor point.
        AAPLEastSouthDistance hyp = [AAPLCoordinateConverter metersFromPoint:_fromAnchorMKPoint toPoint:toAnchorMapkitPoint];

        // This gives us pixels/meter
        _pixelsPerMeter = distanceBetweenPointsPixels / distanceBetweenPointsMeters;

        // Angle of diagonal to east (in geographic)
        float angleFromEast = atan2(hyp.south, hyp.east);

        // Angle of diagonal horizontal (in floorplan)
        float angleFromHorizontal = atan2(yDistance, xDistance);

        // Rotation amount from the geographic anchor line segment
        // to the floorplan anchor line segment
        _radiansRotated = angleFromHorizontal - angleFromEast;
    }

    return self;
}

- (CGPoint)pointFromCoordinate:(CLLocationCoordinate2D)coordinate {
    // Get the distance east & south with respect to the first anchor point in meters
    AAPLEastSouthDistance toFix = [AAPLCoordinateConverter metersFromPoint:self.fromAnchorMKPoint toPoint:MKMapPointForCoordinate(coordinate)];
    
    // Convert the east-south anchor point distance to pixels (still in east-south)
    CGPoint pixelsXYInEastSouth = CGPointApplyAffineTransform(CGPointMake(toFix.east, toFix.south), CGAffineTransformMakeScale(self.pixelsPerMeter, self.pixelsPerMeter));
    
    // Rotate the east-south distance to be relative to floorplan horizontal
    // This gives us an xy distance in pixels from the anchor point.
    CGPoint xy = CGPointApplyAffineTransform(pixelsXYInEastSouth, CGAffineTransformMakeRotation(self.radiansRotated));
    
    // however, we need the pixels from the (0, 0) of the floorplan
    // so we adjust by the position of the anchor point in the floorplan
    xy.x += self.fromAnchorFloorplanPoint.x;
    xy.y += self.fromAnchorFloorplanPoint.y;
    
    return xy;
}

@end
