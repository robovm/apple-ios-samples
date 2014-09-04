/*
    File: GraphView.m
Abstract: A custom view for plotting history of x, y, and z magnetic values.
 Version: 1.3

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

Copyright (C) 2014 Apple Inc. All Rights Reserved.

*/

#import "GraphView.h"

@interface GraphView ()

@property (assign) NSUInteger nextIndex;

@end


#pragma mark -

@implementation GraphView

- (void)updateHistoryWithX:(CLHeadingComponentValue)x y:(CLHeadingComponentValue)y z:(CLHeadingComponentValue)z {

	// Add to history.
	history[self.nextIndex][0] = x;
	history[self.nextIndex][1] = y;
	history[self.nextIndex][2] = z;

	// Advance the index counter.
    _nextIndex = (self.nextIndex + 1) % 150;
    
    // Mark itself as needing to be redrawn.
	[self setNeedsDisplay];
}

- (void)drawGraphInContext:(CGContextRef)context withBounds:(CGRect)bounds {
    CGFloat value, temp;

    // Save any previous graphics state settings before setting the color and line width for the current draw.
    CGContextSaveGState(context);
	CGContextSetLineWidth(context, 1.0);

	// Draw the intermediate lines
	CGContextSetGrayStrokeColor(context, 0.6, 1.0);
	CGContextBeginPath(context);
	for (value = -5 + 1.0; value <= 5 - 1.0; value += 1.0) {
	
		if (value == 0.0) {
			continue;
		}
		temp = 0.5 + roundf(bounds.origin.y + bounds.size.height / 2 + value / (2 * 5) * bounds.size.height);
		CGContextMoveToPoint(context, bounds.origin.x, temp);
		CGContextAddLineToPoint(context, bounds.origin.x + bounds.size.width, temp);
	}
	CGContextStrokePath(context);
	
	// Draw the center line
	CGContextSetGrayStrokeColor(context, 0.25, 1.0);
	CGContextBeginPath(context);
	temp = 0.5 + roundf(bounds.origin.y + bounds.size.height / 2);
	CGContextMoveToPoint(context, bounds.origin.x, temp);
	CGContextAddLineToPoint(context, bounds.origin.x + bounds.size.width, temp);
	CGContextStrokePath(context);

    // Restore previous graphics state.
    CGContextRestoreGState(context);
}

- (void)drawHistory:(NSUInteger)axis fromIndex:(NSUInteger)index inContext:(CGContextRef)context bounds:(CGRect)bounds {
    CGFloat value;
	    
	CGContextBeginPath(context);
    for (NSUInteger counter = 0; counter < 150; ++counter) {
        // UIView referential has the Y axis going down, so we need to draw upside-down.
        value = history[(index + counter) % 150][axis] / -128; 
        if (counter > 0) {
            CGContextAddLineToPoint(context, bounds.origin.x + (float)counter / (float)(150 - 1) * bounds.size.width, bounds.origin.y + bounds.size.height / 2 + value * bounds.size.height / 2);
        } else {
            CGContextMoveToPoint(context, bounds.origin.x + (float)counter / (float)(150 - 1) * bounds.size.width, bounds.origin.y + bounds.size.height / 2 + value * bounds.size.height / 2);
        }
    }
    // Save any previous graphics state settings before setting the color and line width for the current draw.
    CGContextSaveGState(context);
    CGContextSetRGBStrokeColor(context, (axis == 0 ? 1.0 : 0.0), (axis == 1 ? 1.0 : 0.0), (axis == 2 ? 1.0 : 0.0), 1.0);
	CGContextSetLineWidth(context, 2.0);
    CGContextStrokePath(context);
    // Restore previous graphics state.
    CGContextRestoreGState(context);
}

- (void)drawRect:(CGRect)clip {
    NSUInteger index = self.nextIndex;
    
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect bounds = CGRectMake(0, 0, [self bounds].size.width, [self bounds].size.height);
	
	// create the graph
	[self drawGraphInContext:context withBounds:bounds];
	
    // plot x,y,z with anti-aliasing turned off
    CGContextSetAllowsAntialiasing(context, false);
    for (NSUInteger i = 0; i < 3; ++i) {
		[self drawHistory:i fromIndex:index inContext:context bounds:bounds];
    }
    CGContextSetAllowsAntialiasing(context, true);
}

@end
