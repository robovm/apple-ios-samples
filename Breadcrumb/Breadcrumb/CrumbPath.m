/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "CrumbPath.h"

#import <pthread.h> // for pthread_rwlock_init


#define MINIMUM_DELTA_METERS 10.0

@interface CrumbPath ()

// Updated by -addCoordinate:boundingMapRectChanged: if needed to contain the new coordinate.
@property (nonatomic, readwrite) MKMapRect boundingMapRect;

@property MKMapPoint *pointBuffer;
@property NSUInteger pointCount;
@property NSUInteger pointBufferCapacity;

@property pthread_rwlock_t rwLock;

@end


#pragma mark -

@implementation CrumbPath

- (id)initWithCenterCoordinate:(CLLocationCoordinate2D)coord
{
	self = [super init];
    if (self != nil)
	{
        // Initialize point storage and place this first coordinate in it
        _pointBufferCapacity = 1000;
        _pointBuffer = malloc(sizeof(MKMapPoint) * self.pointBufferCapacity);
        MKMapPoint origin = MKMapPointForCoordinate(coord);
        self.pointBuffer[0] = origin;
        _pointCount = 1;
        
        // Default -boundingMapRect size is 1km^2 centered on coord
        double oneKilometerInMapPoints = 1000 * MKMapPointsPerMeterAtLatitude(coord.latitude);
        MKMapSize oneSquareKilometer = {oneKilometerInMapPoints, oneKilometerInMapPoints};
        _boundingMapRect = (MKMapRect){origin, oneSquareKilometer};
        
        // Clamp the rect to be within the world
        _boundingMapRect = MKMapRectIntersection(self.boundingMapRect, MKMapRectWorld);
        
        // Initialize read-write lock for drawing and updates
        //
        // We didn't use this lock during this method because
        // it's our user's responsibility not to use us before
        // -init completes.
        pthread_rwlock_init(&_rwLock, NULL);
    }
    return self;
}

- (void)dealloc
{
    free(_pointBuffer);
    pthread_rwlock_destroy(&_rwLock);
}

- (CLLocationCoordinate2D)coordinate
{
    __block CLLocationCoordinate2D centerCoordinate;
    [self readPointsWithBlockAndWait:^(MKMapPoint *pointsArray, NSUInteger pointsCount) {
        centerCoordinate = MKCoordinateForMapPoint(pointsArray[0]);
    }];
    return centerCoordinate;
}

- (void)readPointsWithBlockAndWait:(void (^)(MKMapPoint *pointsArray, NSUInteger pointArrayCount))block
{
    // Acquire the write lock so the list of points isn't changed while we read it
    pthread_rwlock_wrlock(&_rwLock);
    block(self.pointBuffer, self.pointCount);
    pthread_rwlock_unlock(&_rwLock);
}

- (MKMapRect)growOverlayBounds:(MKMapRect)overlayBounds toInclude:(MKMapRect)otherRect
{
    // The -boundingMapRect we choose was too small.
    // We grow it to be both rects, plus about
    // an extra kilometer in every direction that was too small before.
    // Usually the crumb-trail will keep growing in the direction it grew before
    // so this minimizes having to regrow, without growing off-trail.
    
    MKMapRect grownBounds = MKMapRectUnion(overlayBounds, otherRect);
    
    // Pedantically, to grow the overlay by one real kilometer, we would need to
    // grow different sides by a different number of map points, to account for
    // the number of map points per meter changing with latitude.
    // But we don't need to be exact. The center of the rect that ran over
    // is a good enough estimate for where we'll be growing the overlay.
    
    double oneKilometerInMapPoints = 1000*MKMapPointsPerMeterAtLatitude(MKCoordinateForMapPoint(otherRect.origin).latitude);
    
    // Grow by an extra kilometer in the direction of each overrun.
    if (MKMapRectGetMinY(otherRect) < MKMapRectGetMinY(overlayBounds))
    {
        grownBounds.origin.y -= oneKilometerInMapPoints;
        grownBounds.size.height += oneKilometerInMapPoints;
    }
    if (MKMapRectGetMaxY(otherRect) > MKMapRectGetMaxY(overlayBounds))
    {
        grownBounds.size.height += oneKilometerInMapPoints;
    }
    if (MKMapRectGetMinX(otherRect) < MKMapRectGetMinX(overlayBounds))
    {
        grownBounds.origin.x -= oneKilometerInMapPoints;
        grownBounds.size.width += oneKilometerInMapPoints;
    }
    if (MKMapRectGetMaxX(otherRect) > MKMapRectGetMaxX(overlayBounds))
    {
        grownBounds.size.width += oneKilometerInMapPoints;
    }
    
    // Clip to world size
    grownBounds = MKMapRectIntersection(grownBounds, MKMapRectWorld);
    
    return grownBounds;
}

- (MKMapRect)mapRectContainingPoint:(MKMapPoint)p1 andPoint:(MKMapPoint)p2
{
    MKMapSize pointSize = {0,0};
    MKMapRect newPointRect = (MKMapRect){p1,pointSize};
    MKMapRect prevPointRect = (MKMapRect){p2,pointSize};
    return MKMapRectUnion(newPointRect, prevPointRect);
}

- (MKMapRect)addCoordinate:(CLLocationCoordinate2D)newCoord boundingMapRectChanged:(BOOL *)boundingMapRectChangedOut
{
    // Acquire the write lock because we are going to be changing the list of points
    pthread_rwlock_wrlock(&_rwLock);
    
    //Assume no changes until we make one.
    BOOL boundingMapRectChanged = NO;
    MKMapRect updateRect = MKMapRectNull;
    
    // Convert to map space
    MKMapPoint newPoint = MKMapPointForCoordinate(newCoord);
    
    // Get the distance between this new point and the previous point.
    MKMapPoint prevPoint = self.pointBuffer[self.pointCount - 1];
    CLLocationDistance metersApart = MKMetersBetweenMapPoints(newPoint, prevPoint);
    
    // Ignore the point if it's too close to the previous one.
    if (metersApart > MINIMUM_DELTA_METERS)
    {
        // Grow the points buffer if necessary
        if (self.pointBufferCapacity == self.pointCount)
        {
            _pointBufferCapacity *= 2;
            _pointBuffer = realloc(self.pointBuffer, sizeof(MKMapPoint) * self.pointBufferCapacity);
        }
        
        // Add the new point to the points buffer
        self.pointBuffer[self.pointCount] = newPoint;
        _pointCount++;
        
        // Compute MKMapRect bounding prevPoint and newPoint
        updateRect = [self mapRectContainingPoint:newPoint andPoint:prevPoint];
        
        //Update the -boundingMapRect to hold the new point if needed
        MKMapRect overlayBounds = self.boundingMapRect;
        if (NO == MKMapRectContainsRect(overlayBounds,updateRect))
        {
            self.boundingMapRect = [self growOverlayBounds:overlayBounds toInclude:updateRect];
            boundingMapRectChanged = YES;
        }
    }
    
    // Report if -boundingMapRect changed
    if (boundingMapRectChangedOut)
    {
        *boundingMapRectChangedOut = boundingMapRectChanged;
    }
    
    pthread_rwlock_unlock(&_rwLock);
    
    return updateRect;
}

@end
