/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "CrumbPathRenderer.h"
#import "CrumbPath.h"


@implementation CrumbPathRenderer

- (void)drawMapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale
          inContext:(CGContextRef)context;
{
    CrumbPath *crumbs = (CrumbPath *)(self.overlay);
    
    CGFloat lineWidth = MKRoadWidthAtZoomScale(zoomScale);
    
    // outset the map rect by the line width so that points just outside
    // of the currently drawn rect are included in the generated path.
    MKMapRect clipRect = MKMapRectInset(mapRect, -lineWidth, -lineWidth);
    
    __block CGPathRef path = nil;
    [crumbs readPointsWithBlockAndWait:^(MKMapPoint *points, NSUInteger pointsCount){
        path = [self newPathForPoints:points
                           pointCount:pointsCount
                             clipRect:clipRect
                            zoomScale:zoomScale];
    }];
    
    if (path != nil)
    {
        CGContextAddPath(context, path);
        CGContextSetRGBStrokeColor(context, 0.0f, 0.0f, 1.0f, 0.5f);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextSetLineCap(context, kCGLineCapRound);
        CGContextSetLineWidth(context, lineWidth);
        CGContextStrokePath(context);
        CGPathRelease(path);
    }
}


#pragma mark - Private Implementation

static BOOL LineBetweenPointsIntersectsRect(MKMapPoint p0, MKMapPoint p1, MKMapRect r)
{
    double minX = MIN(p0.x, p1.x);
    double minY = MIN(p0.y, p1.y);
    double maxX = MAX(p0.x, p1.x);
    double maxY = MAX(p0.y, p1.y);
    
    MKMapRect r2 = MKMapRectMake(minX, minY, maxX - minX, maxY - minY);
    return MKMapRectIntersectsRect(r, r2);
}

static inline double POW2(a) { return a * a; }

- (CGPathRef)newPathForPoints:(MKMapPoint *)points
                      pointCount:(NSUInteger)pointCount
                        clipRect:(MKMapRect)mapRect
                       zoomScale:(MKZoomScale)zoomScale
{
    CGMutablePathRef path = nil;
    
    // The fastest way to draw a path in an MKOverlayView is to simplify the
    // geometry for the screen by eliding points that are too close together
    // and to omit any line segments that do not intersect the clipping rect.  
    // While it is possible to just add all the points and let CoreGraphics 
    // handle clipping and flatness, it is much faster to do it yourself:
    //
    if (pointCount > 1)
    {
        path = CGPathCreateMutable();
        
        BOOL needsMove = YES;
        
        // Calculate the minimum distance between any two points by figuring out
        // how many map points correspond to MIN_POINT_DELTA of screen points
        // at the current zoomScale.
        const double MIN_POINT_DELTA = 5.0;
        double minPointDelta = MIN_POINT_DELTA / zoomScale;
        double c2 = POW2(minPointDelta);
        
        MKMapPoint lastPoint = points[0];
        for (NSUInteger i = 1; i < pointCount - 1; i++)
        {
            MKMapPoint point = points[i];
            double a2b2 = POW2(point.x - lastPoint.x) + POW2(point.y - lastPoint.y);
            if (a2b2 >= c2) {
                if (LineBetweenPointsIntersectsRect(point, lastPoint, mapRect))
                {
                    if (needsMove)
                    {
                        CGPoint lastCGPoint = [self pointForMapPoint:lastPoint];
                        CGPathMoveToPoint(path, NULL, lastCGPoint.x, lastCGPoint.y);
                    }
                    CGPoint cgPoint = [self pointForMapPoint:point];
                    CGPathAddLineToPoint(path, NULL, cgPoint.x, cgPoint.y);
                    needsMove = NO;
                }
                else
                {
                    // discontinuity, lift the pen
                    needsMove = YES;
                }
                lastPoint = point;
            }
        }
        
        // If the last line segment intersects the mapRect at all, add it unconditionally 
        MKMapPoint point = points[pointCount - 1];
        if (LineBetweenPointsIntersectsRect(point, lastPoint, mapRect))
        {
            if (needsMove)
            {
                CGPoint lastCGPoint = [self pointForMapPoint:lastPoint];
                CGPathMoveToPoint(path, NULL, lastCGPoint.x, lastCGPoint.y);
            }
            CGPoint cgPoint = [self pointForMapPoint:point];
            CGPathAddLineToPoint(path, NULL, cgPoint.x, cgPoint.y);
        }
    }
    
    return path;
}

@end
