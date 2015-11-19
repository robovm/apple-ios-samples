/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Contains the `Line` and `LinePoint` types used to represent and draw lines derived from touches.
*/

import UIKit

class Line: NSObject {
    // MARK: Properties
    
    // The live line.
    var points = [LinePoint]()
    
    // Use the estimation index of the touch to track points awaiting updates.
    var pointsWaitingForUpdatesByEstimationIndex = [NSNumber: LinePoint]()

    // Points already drawn into 'frozen' representation of this line.
    var committedPoints = [LinePoint]()
    
    var isComplete: Bool {
        return pointsWaitingForUpdatesByEstimationIndex.count == 0
    }
    
    func updateWithTouch(touch: UITouch) -> (Bool, CGRect) {
        if  let estimationUpdateIndex = touch.estimationUpdateIndex,
            let point = pointsWaitingForUpdatesByEstimationIndex[estimationUpdateIndex] {
            var rect = updateRectForExistingPoint(point)
            let didUpdate = point.updateWithTouch(touch)
            if didUpdate {
                rect.unionInPlace(updateRectForExistingPoint(point))
            }
            if point.estimatedPropertiesExpectingUpdates == [] {
                pointsWaitingForUpdatesByEstimationIndex.removeValueForKey(estimationUpdateIndex)
            }
            return (didUpdate,rect)
        }
        return (false, CGRect.null)
    }
    
    // MARK: Interface
    
    func addPointOfType(pointType: LinePoint.PointType, forTouch touch: UITouch) -> CGRect {
        let previousPoint = points.last
        let previousSequenceNumber = previousPoint?.sequenceNumber ?? -1
        let point = LinePoint(touch: touch, sequenceNumber: previousSequenceNumber + 1, pointType:pointType)
        
        if let estimationIndex = point.estimationUpdateIndex {
            if !point.estimatedPropertiesExpectingUpdates.isEmpty {
                pointsWaitingForUpdatesByEstimationIndex[estimationIndex] = point
            }
        }
        
        points.append(point)
        
        let updateRect = updateRectForLinePoint(point, previousPoint: previousPoint)
        
        return updateRect
    }
    
    func removePointsWithType(type: LinePoint.PointType) -> CGRect {
        var updateRect = CGRect.null
        var priorPoint: LinePoint?
        
        points = points.filter { point in
            let keepPoint = !point.pointType.contains(type)
            
            if !keepPoint {
                var rect = self.updateRectForLinePoint(point)
                
                if let priorPoint = priorPoint {
                    rect.unionInPlace(updateRectForLinePoint(priorPoint))
                }
                
                updateRect.unionInPlace(rect)
            }
            
            priorPoint = point
            
            return keepPoint
        }
        
        return updateRect
    }
    
    func cancel() -> CGRect {
        // Process each point in the line and accumulate the `CGRect` containing all the points.
        let updateRect = points.reduce(CGRect.null) { accumulated, point in
            // Update the type set to include `.Cancelled`.
            point.pointType.unionInPlace(.Cancelled)
            
            /*
                Union the `CGRect` for this point with accumulated `CGRect` and return it. The result is
                supplied to the next invocation of the closure.
            */
            return accumulated.union(updateRectForLinePoint(point))
        }
        
        return updateRect
    }
    
    // MARK: Drawing
    
    func drawInContext(context: CGContext, isDebuggingEnabled: Bool, usePreciseLocation: Bool) {
        var maybePriorPoint: LinePoint?
        
        for point in points {
            guard let priorPoint = maybePriorPoint else {
                maybePriorPoint = point
                continue
            }
            
            // This color will used by default for `.Standard` touches.
            var color = UIColor.blackColor()
            
            let pointType = point.pointType
            if isDebuggingEnabled {
                if pointType.contains(.Cancelled) {
                    color = UIColor.redColor()
                }
                else if pointType.contains(.NeedsUpdate) {
                    color = UIColor.orangeColor()
                }
                else if pointType.contains(.Finger) {
                    color = UIColor.purpleColor()
                }
                else if pointType.contains(.Coalesced) {
                    color = UIColor.greenColor()
                }
                else if pointType.contains(.Predicted) {
                    color = UIColor.blueColor()
                }
            } else {
                if pointType.contains(.Cancelled) {
                    color = UIColor.clearColor()
                }
                else if pointType.contains(.Finger) {
                    color = UIColor.purpleColor()
                }
                if pointType.contains(.Predicted) && !pointType.contains(.Cancelled) {
                    color = color.colorWithAlphaComponent(0.5)
                }
            }
            
            let location = usePreciseLocation ? point.preciseLocation : point.location
            let priorLocation = usePreciseLocation ? priorPoint.preciseLocation : priorPoint.location
            
            CGContextSetStrokeColorWithColor(context, color.CGColor)
            
            CGContextBeginPath(context)
            
            CGContextMoveToPoint(context, priorLocation.x, priorLocation.y)
            CGContextAddLineToPoint(context, location.x, location.y)
            
            CGContextSetLineWidth(context, point.magnitude)
            CGContextStrokePath(context)
            
            // Draw azimuith and elevation on all non-coalesced points when debugging.
            if isDebuggingEnabled && !pointType.contains(.Coalesced) && !pointType.contains(.Predicted) && !pointType.contains(.Finger) {
                CGContextBeginPath(context)
                CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
                CGContextSetLineWidth(context, 0.5);
                CGContextMoveToPoint(context, location.x, location.y)
                var targetPoint = CGPoint(x:0.5 + 10.0 * cos(point.altitudeAngle), y:0.0)
                targetPoint = CGPointApplyAffineTransform(targetPoint, CGAffineTransformMakeRotation(point.azimuthAngle))
                targetPoint.x += location.x
                targetPoint.y += location.y
                CGContextAddLineToPoint(context, targetPoint.x, targetPoint.y)
                CGContextStrokePath(context)
            }
            
            maybePriorPoint = point
        }
    }
    
    func drawFixedPointsInContext(context: CGContext, isDebuggingEnabled: Bool, usePreciseLocation: Bool, commitAll: Bool = false) {
        let allPoints = points
        var committing = [LinePoint]()
        
        if commitAll {
            committing = allPoints
            points.removeAll()
        }
        else {
            for (index, point) in allPoints.enumerate() {
                // Only points whose type does not include `.NeedsUpdate` or `.Predicted` and are not last or prior to last point can be committed.
                guard point.pointType.intersect([.NeedsUpdate, .Predicted]).isEmpty && index < allPoints.count - 2 else {
                    committing.append(points.first!)
                    break
                }
                
                guard index > 0 else { continue }
                
                // First time to this point should be index 1 if there is a line segment that can be committed.
                let removed = points.removeFirst()
                committing.append(removed)
            }
        }
        // If only one point could be committed, no further action is required. Otherwise, draw the `committedLine`.
        guard committing.count > 1 else { return }
        
        let committedLine = Line()
        committedLine.points = committing
        committedLine.drawInContext(context, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocation)
        
        
        if committedPoints.count > 0 {
            // Remove what was the last point committed point; it is also the first point being committed now.
            committedPoints.removeLast()
        }
        
        // Store the points being committed for redrawing later in a different style if needed.
        committedPoints.appendContentsOf(committing)
    }
    
    func drawCommitedPointsInContext(context: CGContext, isDebuggingEnabled: Bool, usePreciseLocation: Bool) {
        let committedLine = Line()
        committedLine.points = committedPoints
        committedLine.drawInContext(context, isDebuggingEnabled: isDebuggingEnabled, usePreciseLocation: usePreciseLocation)
    }
    
    // MARK: Convenience
    
    func updateRectForLinePoint(point: LinePoint) -> CGRect {
        var rect = CGRect(origin: point.location, size: CGSize.zero)
        
        // The negative magnitude ensures an outset rectangle.
        let magnitude = -3 * point.magnitude - 2
        rect.insetInPlace(dx: magnitude, dy: magnitude)
        
        return rect
    }

    func updateRectForLinePoint(point: LinePoint, previousPoint optionalPreviousPoint: LinePoint? = nil) -> CGRect {
        var rect = CGRect(origin: point.location, size: CGSize.zero)
        
        var pointMagnitude = point.magnitude

        if let previousPoint = optionalPreviousPoint {
            pointMagnitude = max(pointMagnitude, previousPoint.magnitude)
            rect = CGRectUnion(rect, CGRect(origin:previousPoint.location, size: CGSize.zero))
        }
        
        // The negative magnitude ensures an outset rectangle.
        let magnitude = -3.0 * pointMagnitude - 2.0
        rect.insetInPlace(dx: magnitude, dy: magnitude)
        
        return rect
    }
    
    func updateRectForExistingPoint(point: LinePoint) -> CGRect {
        var rect = updateRectForLinePoint(point)
        
        let arrayIndex = point.sequenceNumber - points.first!.sequenceNumber
        
        if arrayIndex > 0 {
            rect = CGRectUnion(rect,updateRectForLinePoint(point, previousPoint: points[arrayIndex-1]))
        }
        if arrayIndex + 1 < points.count {
            rect = CGRectUnion(rect,updateRectForLinePoint(point, previousPoint: points[arrayIndex+1]))
        }
        return rect
    }

}


class LinePoint: NSObject  {
    // MARK: Types
    
    struct PointType: OptionSetType {
        // MARK: Properties
        
        let rawValue: Int
        
        // MARK: Options
        
        static var Standard: PointType    { return self.init(rawValue: 0) }
        static var Coalesced: PointType   { return self.init(rawValue: 1 << 0) }
        static var Predicted: PointType   { return self.init(rawValue: 1 << 1) }
        static var NeedsUpdate: PointType { return self.init(rawValue: 1 << 2) }
        static var Updated: PointType     { return self.init(rawValue: 1 << 3) }
        static var Cancelled: PointType   { return self.init(rawValue: 1 << 4) }
        static var Finger: PointType      { return self.init(rawValue: 1 << 5) }
    }
    
    // MARK: Properties
    
    var sequenceNumber: Int
    let timestamp: NSTimeInterval
    var force: CGFloat
    var location: CGPoint
    var preciseLocation: CGPoint
    var estimatedPropertiesExpectingUpdates: UITouchProperties
    var estimatedProperties: UITouchProperties
    let type: UITouchType
    var altitudeAngle: CGFloat
    var azimuthAngle: CGFloat
    let estimationUpdateIndex: NSNumber?
    
    var pointType: PointType
    
    var magnitude: CGFloat {
        return max(force, 0.025)
    }
    
    // MARK: Initialization
    
    init(touch: UITouch, sequenceNumber: Int, pointType: PointType) {
        self.sequenceNumber = sequenceNumber
        self.type = touch.type
        self.pointType = pointType
        
        timestamp = touch.timestamp
        let view = touch.view
        location = touch.locationInView(view)
        preciseLocation = touch.preciseLocationInView(view)
        azimuthAngle = touch.azimuthAngleInView(view)
        estimatedProperties = touch.estimatedProperties
        estimatedPropertiesExpectingUpdates = touch.estimatedPropertiesExpectingUpdates
        altitudeAngle = touch.altitudeAngle
        force = (type == .Stylus || touch.force > 0) ? touch.force : 1.0
        
        if !estimatedPropertiesExpectingUpdates.isEmpty {
            self.pointType.unionInPlace(.NeedsUpdate)
        }
        
        estimationUpdateIndex = touch.estimationUpdateIndex
    }
    
    func updateWithTouch(touch: UITouch) -> Bool {
        guard let estimationUpdateIndex = touch.estimationUpdateIndex
            where estimationUpdateIndex == estimationUpdateIndex else { return false }
        
        // An array of the touch properties that may be of interest.
        let touchProperties: [UITouchProperties] = [.Altitude, .Azimuth, .Force, .Location]
        
        // Iterate through possible properties.
        for expectedProperty in touchProperties {
            // If an update to this property is not expected, continue to the next property.
            guard !estimatedPropertiesExpectingUpdates.contains(expectedProperty) else { continue }
            
            // Update the value of the point with the value from the touch's property.
            switch expectedProperty {
                case UITouchProperties.Force:
                    force = touch.force
                case UITouchProperties.Azimuth:
                    azimuthAngle = touch.azimuthAngleInView(touch.view)
                case UITouchProperties.Altitude:
                    altitudeAngle = touch.altitudeAngle
                case UITouchProperties.Location:
                    location = touch.locationInView(touch.view)
                    preciseLocation = touch.preciseLocationInView(touch.view)
                default:
                    ()
            }

            if !touch.estimatedProperties.contains(expectedProperty) {
                // Flag that this point now has a 'final' value for this property.
                estimatedProperties.subtractInPlace(expectedProperty)
            }
            
            if !touch.estimatedPropertiesExpectingUpdates.contains(expectedProperty) {
                // Flag that this point is no longer expecting updates for this property.
                estimatedPropertiesExpectingUpdates.subtractInPlace(expectedProperty)
                
                if estimatedPropertiesExpectingUpdates.isEmpty {
                    // Flag that this point has been updated and no longer needs updates.
                    pointType.subtractInPlace(.NeedsUpdate)
                    pointType.unionInPlace(.Updated)
                }
            }
        }
        
        return true
    }
}
