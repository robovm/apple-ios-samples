/*
     File: QuartzLines.m
 Abstract: Demonstrates Quartz line drawing facilities (QuartzLineView), including dash patterns (QuartzDashView), stroke width, line cap and line join (QuartzCapJoinWidthView).
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

#import "QuartzLines.h"

@implementation QuartzLineView

-(void)drawInContext:(CGContextRef)context
{
	// Drawing lines with a white stroke color
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	// Draw them with a 2.0 stroke width so they are a bit more visible.
	CGContextSetLineWidth(context, 2.0);
	
	// Draw a single line from left to right
	CGContextMoveToPoint(context, 10.0, 30.0);
	CGContextAddLineToPoint(context, 310.0, 30.0);
	CGContextStrokePath(context);
	
	// Draw a connected sequence of line segments
	CGPoint addLines[] =
	{
		CGPointMake(10.0, 90.0),
		CGPointMake(70.0, 60.0),
		CGPointMake(130.0, 90.0),
		CGPointMake(190.0, 60.0),
		CGPointMake(250.0, 90.0),
		CGPointMake(310.0, 60.0),
	};
	// Bulk call to add lines to the current path.
	// Equivalent to MoveToPoint(points[0]); for(i=1; i<count; ++i) AddLineToPoint(points[i]);
	CGContextAddLines(context, addLines, sizeof(addLines)/sizeof(addLines[0]));
	CGContextStrokePath(context);
	
	// Draw a series of line segments. Each pair of points is a segment
	CGPoint strokeSegments[] =
	{
		CGPointMake(10.0, 150.0),
		CGPointMake(70.0, 120.0),
		CGPointMake(130.0, 150.0),
		CGPointMake(190.0, 120.0),
		CGPointMake(250.0, 150.0),
		CGPointMake(310.0, 120.0),
	};
	// Bulk call to stroke a sequence of line segments.
	// Equivalent to for(i=0; i<count; i+=2) { MoveToPoint(point[i]); AddLineToPoint(point[i+1]); StrokePath(); }
	CGContextStrokeLineSegments(context, strokeSegments, sizeof(strokeSegments)/sizeof(strokeSegments[0]));
}

@end


#pragma mark -

@implementation QuartzCapJoinWidthView


-(void)drawInContext:(CGContextRef)context
{
	// Drawing lines with a white stroke color
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	
	// Preserve the current drawing state
	CGContextSaveGState(context);
	
	// Setup the horizontal line to demostrate caps
	CGContextMoveToPoint(context, 40.0, 30.0);
	CGContextAddLineToPoint(context, 280.0, 30.0);
    
	// Set the line width & cap for the cap demo
	CGContextSetLineWidth(context, self.width);
	CGContextSetLineCap(context, self.cap);
	CGContextStrokePath(context);
	
	// Restore the previous drawing state, and save it again.
	CGContextRestoreGState(context);
	CGContextSaveGState(context);
	
	// Setup the angled line to demonstrate joins
	CGContextMoveToPoint(context, 40.0, 190.0);
	CGContextAddLineToPoint(context, 160.0, 70.0);
	CGContextAddLineToPoint(context, 280.0, 190.0);
    
	// Set the line width & join for the join demo
	CGContextSetLineWidth(context, self.width);
	CGContextSetLineJoin(context, self.join);
	CGContextStrokePath(context);
    
	// Restore the previous drawing state.
	CGContextRestoreGState(context);
    
	// If the stroke width is large enough, display the path that generated these lines
	if (self.width >= 4.0) // arbitrarily only show when the line is at least twice as wide as our target stroke
	{
		CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
		CGContextMoveToPoint(context, 40.0, 30.0);
		CGContextAddLineToPoint(context, 280.0, 30.0);
		CGContextMoveToPoint(context, 40.0, 190.0);
		CGContextAddLineToPoint(context, 160.0, 70.0);
		CGContextAddLineToPoint(context, 280.0, 190.0);
		CGContextSetLineWidth(context, 2.0);
		CGContextStrokePath(context);
	}
}

-(void)setCap:(CGLineCap)c
{
	if(c != _cap)
	{
		_cap = c;
		[self setNeedsDisplay];
	}
}

-(void)setJoin:(CGLineJoin)j
{
	if(j != _join)
	{
		_join = j;
		[self setNeedsDisplay];
	}
}

-(void)setWidth:(CGFloat)w
{
	if(w != _width)
	{
		_width = w;
		[self setNeedsDisplay];
	}
}

@end



#pragma mark -

@implementation QuartzDashView
{
	CGFloat dashPattern[10];
	size_t dashCount;
}


-(void)setDashPhase:(CGFloat)phase
{
	if (phase != _dashPhase)
	{
		_dashPhase = phase;
		[self setNeedsDisplay];
	}
}


-(void)setDashPattern:(CGFloat *)pattern count:(size_t)count
{
	if ((count != dashCount) || (memcmp(dashPattern, pattern, sizeof(CGFloat) * count) != 0))
	{
		memcpy(dashPattern, pattern, sizeof(CGFloat) * count);
		dashCount = count;
		[self setNeedsDisplay];
	}
}


-(void)drawInContext:(CGContextRef)context
{
	// Drawing lines with a white stroke color
	CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
	
	// Each dash entry is a run-length in the current coordinate system
	// The concept is first you determine how many points in the current system you need to fill.
	// Then you start consuming that many pixels in the dash pattern for each element of the pattern.
	// So for example, if you have a dash pattern of {10, 10}, then you will draw 10 points, then skip 10 points, and repeat.
	// As another example if your dash pattern is {10, 20, 30}, then you draw 10 points, skip 20 points, draw 30 points,
	// skip 10 points, draw 20 points, skip 30 points, and repeat.
	// The dash phase factors into this by stating how many points into the dash pattern to skip.
	// So given a dash pattern of {10, 10} with a phase of 5, you would draw 5 points (since phase plus 5 yields 10 points),
	// then skip 10, draw 10, skip 10, draw 10, etc.
	
	CGContextSetLineDash(context, self.dashPhase, dashPattern, dashCount);
	
	// Draw a horizontal line, vertical line, rectangle and circle for comparison
	CGContextMoveToPoint(context, 10.0, 20.0);
	CGContextAddLineToPoint(context, 310.0, 20.0);
	CGContextMoveToPoint(context, 160.0, 30.0);
	CGContextAddLineToPoint(context, 160.0, 130.0);
	CGContextAddRect(context, CGRectMake(10.0, 30.0, 100.0, 100.0));
	CGContextAddEllipseInRect(context, CGRectMake(210.0, 30.0, 100.0, 100.0));
	// And width 2.0 so they are a bit more visible
	CGContextSetLineWidth(context, 2.0);
	CGContextStrokePath(context);
}

@end

