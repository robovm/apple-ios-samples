/*
     File: QuartzCurves.m
 Abstract: Demonstrates using Quartz to draw ellipses & arcs (QuartzEllipseArcView) and bezier & quadratic curves (QuartzBezierView).
  Version: 3.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
*/
#import "QuartzCurves.h"

@implementation QuartzEllipseArcView

-(void)drawInContext:(CGContextRef)context
{
	// Drawing with a white stroke color
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	// And draw with a blue fill color
	CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1.0);
	// Draw them with a 2.0 stroke width so they are a bit more visible.
	CGContextSetLineWidth(context, 2.0);
	
	// Add an ellipse circumscribed in the given rect to the current path, then stroke it
	CGContextAddEllipseInRect(context, CGRectMake(30.0, 30.0, 60.0, 60.0));
	CGContextStrokePath(context);
	
	// Stroke ellipse convenience that is equivalent to AddEllipseInRect(); StrokePath();
	CGContextStrokeEllipseInRect(context, CGRectMake(30.0, 120.0, 60.0, 60.0));
	
	// Fill rect convenience equivalent to AddEllipseInRect(); FillPath();
	CGContextFillEllipseInRect(context, CGRectMake(30.0, 210.0, 60.0, 60.0));
	
	// Stroke 2 seperate arcs
	CGContextAddArc(context, 150.0, 60.0, 30.0, 0.0, M_PI/2.0, false);
	CGContextStrokePath(context);
	CGContextAddArc(context, 150.0, 60.0, 30.0, 3.0*M_PI/2.0, M_PI, true);
	CGContextStrokePath(context);

	// Stroke 2 arcs together going opposite directions.
	CGContextAddArc(context, 150.0, 150.0, 30.0, 0.0, M_PI/2.0, false);
	CGContextAddArc(context, 150.0, 150.0, 30.0, 3.0*M_PI/2.0, M_PI, true);
	CGContextStrokePath(context);

	// Stroke 2 arcs together going the same direction..
	CGContextAddArc(context, 150.0, 240.0, 30.0, 0.0, M_PI/2.0, false);
	CGContextAddArc(context, 150.0, 240.0, 30.0, M_PI, 3.0*M_PI/2.0, false);
	CGContextStrokePath(context);
	
	// Stroke an arc using AddArcToPoint
	CGPoint p[3] =
	{
		CGPointMake(210.0, 30.0),
		CGPointMake(210.0, 60.0),
		CGPointMake(240.0, 60.0),
	};
	CGContextMoveToPoint(context, p[0].x, p[0].y);
	CGContextAddArcToPoint(context, p[1].x, p[1].y, p[2].x, p[2].y, 30.0);
	CGContextStrokePath(context);
	
	// Show the two segments that are used to determine the tangent lines to draw the arc.
	CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
	CGContextAddLines(context, p, sizeof(p)/sizeof(p[0]));
	CGContextStrokePath(context);
	
	// As a bonus, we'll combine arcs to create a round rectangle!
	
	// Drawing with a white stroke color
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);

	// If you were making this as a routine, you would probably accept a rectangle
	// that defines its bounds, and a radius reflecting the "rounded-ness" of the rectangle.
	CGRect rrect = CGRectMake(210.0, 90.0, 60.0, 60.0);
	CGFloat radius = 10.0;
	// NOTE: At this point you may want to verify that your radius is no more than half
	// the width and height of your rectangle, as this technique degenerates for those cases.
	
	// In order to draw a rounded rectangle, we will take advantage of the fact that
	// CGContextAddArcToPoint will draw straight lines past the start and end of the arc
	// in order to create the path from the current position and the destination position.
	
	// In order to create the 4 arcs correctly, we need to know the min, mid and max positions
	// on the x and y lengths of the given rectangle.
	CGFloat minx = CGRectGetMinX(rrect), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect);
	CGFloat miny = CGRectGetMinY(rrect), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect);
	
	// Next, we will go around the rectangle in the order given by the figure below.
	//       minx    midx    maxx
	// miny    2       3       4
	// midy   1 9              5
	// maxy    8       7       6
	// Which gives us a coincident start and end point, which is incidental to this technique, but still doesn't
	// form a closed path, so we still need to close the path to connect the ends correctly.
	// Thus we start by moving to point 1, then adding arcs through each pair of points that follows.
	// You could use a similar tecgnique to create any shape with rounded corners.
	
	// Start at 1
	CGContextMoveToPoint(context, minx, midy);
	// Add an arc through 2 to 3
	CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
	// Add an arc through 4 to 5
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
	// Add an arc through 6 to 7
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
	// Add an arc through 8 to 9
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
	// Close the path
	CGContextClosePath(context);
	// Fill & stroke the path
	CGContextDrawPath(context, kCGPathFillStroke);
}

@end


#pragma mark - QuartzBezierView

@implementation QuartzBezierView

-(void)drawInContext:(CGContextRef)context
{
	// Drawing with a white stroke color
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	// Draw them with a 2.0 stroke width so they are a bit more visible.
	CGContextSetLineWidth(context, 2.0);
	
	// Draw a bezier curve with end points s,e and control points cp1,cp2
	CGPoint s = CGPointMake(30.0, 120.0);
	CGPoint e = CGPointMake(300.0, 120.0);
	CGPoint cp1 = CGPointMake(120.0, 30.0);
	CGPoint cp2 = CGPointMake(210.0, 210.0);
	CGContextMoveToPoint(context, s.x, s.y);
	CGContextAddCurveToPoint(context, cp1.x, cp1.y, cp2.x, cp2.y, e.x, e.y);
	CGContextStrokePath(context);
	
	// Show the control points.
	CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
	CGContextMoveToPoint(context, s.x, s.y);
	CGContextAddLineToPoint(context, cp1.x, cp1.y);
	CGContextMoveToPoint(context, e.x, e.y);
	CGContextAddLineToPoint(context, cp2.x, cp2.y);
	CGContextStrokePath(context);
	
	// Draw a quad curve with end points s,e and control point cp1
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	s = CGPointMake(30.0, 300.0);
	e = CGPointMake(270.0, 300.0);
	cp1 = CGPointMake(150.0, 180.0);
	CGContextMoveToPoint(context, s.x, s.y);
	CGContextAddQuadCurveToPoint(context, cp1.x, cp1.y, e.x, e.y);
	CGContextStrokePath(context);

	// Show the control point.
	CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
	CGContextMoveToPoint(context, s.x, s.y);
	CGContextAddLineToPoint(context, cp1.x, cp1.y);
	CGContextStrokePath(context);
}


@end