
/*
     File: APLGraphView.m
 Abstract: Displays a graph of output. This class uses Core Animation techniques to avoid needing to render the entire graph every update.
 
 The APLGraphView needs to be able to update the scene quickly in order to track the data at a fast enough frame rate. There is too much content to draw the entire graph every frame and sustain a high framerate. This class therefore uses CALayers to cache previously drawn content and arranges them carefully to create an illusion that we are redrawing the entire graph every frame.
 
  Version: 1.0.1
 
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "APLGraphView.h"

#pragma mark - Quartz Helpers

// Functions used to draw all content.

CGColorRef CreateDeviceGrayColor(CGFloat w, CGFloat a)
{
    CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();
    CGFloat comps[] = {w, a};
    CGColorRef color = CGColorCreate(gray, comps);
    CGColorSpaceRelease(gray);
    return color;
}

CGColorRef CreateDeviceRGBColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a)
{
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    CGFloat comps[] = {r, g, b, a};
    CGColorRef color = CGColorCreate(rgb, comps);
    CGColorSpaceRelease(rgb);
    return color;
}

CGColorRef graphBackgroundColor()
{
    static CGColorRef c = NULL;
    if (c == NULL)
    {
        c = CreateDeviceGrayColor(0.6, 1.0);
    }
    return c;
}

CGColorRef graphLineColor()
{
    static CGColorRef c = NULL;
    if (c == NULL)
    {
        c = CreateDeviceGrayColor(0.5, 1.0);
    }
    return c;
}

CGColorRef graphXColor()
{
    static CGColorRef c = NULL;
    if (c == NULL)
    {
        c = CreateDeviceRGBColor(1.0, 0.0, 0.0, 1.0);
    }
    return c;
}

CGColorRef graphYColor()
{
    static CGColorRef c = NULL;
    if (c == NULL)
    {
        c = CreateDeviceRGBColor(0.0, 1.0, 0.0, 1.0);
    }
    return c;
}

CGColorRef graphZColor()
{
    static CGColorRef c = NULL;
    if (c == NULL)
    {
        c = CreateDeviceRGBColor(0.0, 0.0, 1.0, 1.0);
    }
    return c;
}

void DrawGridlines(CGContextRef context, CGFloat x, CGFloat width)
{
    for (CGFloat y = -48.5; y <= 48.5; y += 16.0)
    {
        CGContextMoveToPoint(context, x, y);
        CGContextAddLineToPoint(context, x + width, y);
    }
    CGContextSetStrokeColorWithColor(context, graphLineColor());
    CGContextStrokePath(context);
}



#pragma mark - GraphViewSegment

/*
 The GraphViewSegment manages up to 32 values and a CALayer that it updates with the segment of the graph that those values represent.
 */

@interface APLGraphViewSegment : NSObject


// Returns true if adding this value fills the segment, which is necessary for properly updating the segments.
-(BOOL)addX:(double)x y:(double)y z:(double)z;

/*
 When this object gets recycled (when it falls off the end of the graph) -reset is sent to clear values and prepare for reuse.
*/
-(void)reset;

// Returns true if this segment has consumed 32 values.
-(BOOL)isFull;

// Returns true if the layer for this segment is visible in the given rect.
-(BOOL)isVisibleInRect:(CGRect)r;

// The layer that this segment is drawing into.
@property(nonatomic, readonly) CALayer *layer;

@end


@implementation APLGraphViewSegment
{
    // Need 33 values to fill 32 pixel width.
    double xhistory[33];
    double yhistory[33];
    double zhistory[33];
    int index;
}


-(id)init
{
    self = [super init];
    if (self != nil)
    {
        _layer = [[CALayer alloc] init];
        /*
         The layer will call our -drawLayer:inContext: method to provide content and our -actionForLayer:forKey: for implicit animations.
         */
        _layer.delegate = self;
        /*
         This sets our coordinate system such that it has an origin of 0.0,-56 and a size of 32,112.
         This would need to be changed if you change either the number of pixel values that a segment represented, or if you changed the size of the graph view.
         */
        _layer.bounds = CGRectMake(0.0, -56.0, 32.0, 112.0);
        /*
         Disable blending as this layer consists of non-transperant content. Unlike UIView, a CALayer defaults to opaque=NO
         */
        _layer.opaque = YES;
        /*
         Index represents how many slots are left to be filled in the graph, which is also +1 compared to the array index that a new entry will be added.
         */
        index = 33;
    }
    return self;
}


-(void)reset
{
    // Clear out our components and reset the index to 33 to start filling values again.
    memset(xhistory, 0, sizeof(xhistory));
    memset(yhistory, 0, sizeof(yhistory));
    memset(zhistory, 0, sizeof(zhistory));
    index = 33;
    // Inform Core Animation that this layer needs to be redrawn.
    [self.layer setNeedsDisplay];
}


-(BOOL)isFull
{
    // The segment is full if there is no more space in the history.
    return index == 0;
}


-(BOOL)isVisibleInRect:(CGRect)r
{
    // Check if there is an intersection between the layer's frame and the given rect.
    return CGRectIntersectsRect(r, self.layer.frame);
}


-(BOOL)addX:(double)x y:(double)y z:(double)z
{
    // If this segment is not full, add a new value to the history.
    if (index > 0)
    {
        // First decrement, both to get to a zero-based index and to flag one fewer position left.
        --index;
        xhistory[index] = x;
        yhistory[index] = y;
        zhistory[index] = z;
        // And inform Core Animation to redraw the layer.
        [self.layer setNeedsDisplay];
    }
    // And return if we are now full or not (really just avoids needing to call isFull after adding a value).
    return index == 0;
}


-(void)drawLayer:(CALayer*)l inContext:(CGContextRef)context
{
    // Fill in the background.
    CGContextSetFillColorWithColor(context, graphBackgroundColor());
    CGContextFillRect(context, self.layer.bounds);

    // Draw the grid lines.
    DrawGridlines(context, 0.0, 32.0);

    // Draw the graph.
    CGPoint lines[64];
    int i;

    // X
    for (i = 0; i < 32; ++i)
    {
        lines[i*2].x = i;
        lines[i*2].y = -xhistory[i] * 16.0;
        lines[i*2+1].x = i + 1;
        lines[i*2+1].y = -xhistory[i+1] * 16.0;
    }
    CGContextSetStrokeColorWithColor(context, graphXColor());
    CGContextStrokeLineSegments(context, lines, 64);

    // Y
    for (i = 0; i < 32; ++i)
    {
        lines[i*2].y = -yhistory[i] * 16.0;
        lines[i*2+1].y = -yhistory[i+1] * 16.0;
    }
    CGContextSetStrokeColorWithColor(context, graphYColor());
    CGContextStrokeLineSegments(context, lines, 64);

    // Z
    for (i = 0; i < 32; ++i)
    {
        lines[i*2].y = -zhistory[i] * 16.0;
        lines[i*2+1].y = -zhistory[i+1] * 16.0;
    }
    CGContextSetStrokeColorWithColor(context, graphZColor());
    CGContextStrokeLineSegments(context, lines, 64);
}


-(id)actionForLayer:(CALayer *)layer forKey :(NSString *)key
{
    // We disable all actions for the layer, so no content cross fades, no implicit animation on moves, etc.
    return [NSNull null];
}


// The accessibilityValue of this segment should be the x,y,z values last added.
- (NSString *)accessibilityValue
{
    return [NSString stringWithFormat:NSLocalizedString(@"graphSegmentFormat", @"Format string for accessibility text for last x, y, z values added"), xhistory[index], yhistory[index], zhistory[index]];
}

@end



#pragma mark - GraphTextView

/*
 We use a separate view to draw the text for the graph so that we can layer the segment layers below it which gives the illusion that the numbers are draw over the graph, and hides the fact that the graph drawing for each segment is incomplete until the segment is filled.
 */

@interface APLGraphTextView : UIView

@end


@implementation APLGraphTextView

-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Fill in the background.
    CGContextSetFillColorWithColor(context, graphBackgroundColor());
    CGContextFillRect(context, self.bounds);

    CGContextTranslateCTM(context, 0.0, 56.0);

    // Draw the grid lines.
    DrawGridlines(context, 26.0, 6.0);

    // Draw the text.
    UIFont *systemFont = [UIFont systemFontOfSize:12.0];
    [[UIColor whiteColor] set];
    [@"+3.0" drawInRect:CGRectMake(2.0, -56.0, 24.0, 16.0) withFont:systemFont lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentRight];
    [@"+2.0" drawInRect:CGRectMake(2.0, -40.0, 24.0, 16.0) withFont:systemFont lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentRight];
    [@"+1.0" drawInRect:CGRectMake(2.0, -24.0, 24.0, 16.0) withFont:systemFont lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentRight];
    [@" 0.0" drawInRect:CGRectMake(2.0,  -8.0, 24.0, 16.0) withFont:systemFont lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentRight];
    [@"-1.0" drawInRect:CGRectMake(2.0,   8.0, 24.0, 16.0) withFont:systemFont lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentRight];
    [@"-2.0" drawInRect:CGRectMake(2.0,  24.0, 24.0, 16.0) withFont:systemFont lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentRight];
    [@"-3.0" drawInRect:CGRectMake(2.0,  40.0, 24.0, 16.0) withFont:systemFont lineBreakMode:NSLineBreakByWordWrapping alignment:NSTextAlignmentRight];
}

@end



#pragma mark - APLGraphView

/*
 GraphView handles the public interface as well as arranging the subviews and sublayers to produce the intended effect.
*/

@interface APLGraphView()

// Internal accessors
@property (nonatomic) NSMutableArray *segments;
@property (nonatomic, weak) APLGraphViewSegment *current;
@property (nonatomic, weak) APLGraphTextView *textView;

@end



@implementation APLGraphView

// Designated initializer.
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        [self commonInit];
    }
    return self;
}


// Designated initializer.
-(id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    if (self != nil)
    {
        [self commonInit];
    }
    return self;
}


-(void)commonInit
{
    // Create a mutable array to store segments, which is required by -addSegment.
    _segments = [[NSMutableArray alloc] init];
    
    /*
     Create the text view and add it as a subview. We keep a weak reference to that view afterwards for laying out the segment layers.
     */
    APLGraphTextView *text = [[APLGraphTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 32.0, 112.0)];
    [self addSubview:text];
    _textView = text;
    
    /*
     Create a new current segment, which is required by -addX:y:z and other methods.
     This is also a weak reference (we assume that the 'segments' array will keep the strong reference).
     */
    _current = [self addSegment];
}


-(void)addX:(double)x y:(double)y z:(double)z
{
    // First, add the new value to the current segment.
    if ([self.current addX:x y:y z:z])
    {
        /*
         If after doing that we've filled up the current segment, then we need to determine the next current segment.
         */
        [self recycleSegment];
        // To keep the graph looking continuous, add the value to the new segment as well.
        [self.current addX:x y:y z:z];
    }
    /*
     After adding a new data point, advance the x-position of all the segment layers by 1 to create the illusion that the graph is advancing.
    */
    for (APLGraphViewSegment *segment in self.segments)
    {
        CGPoint position = segment.layer.position;
        position.x += 1.0;
        segment.layer.position = position;
    }
}

/*
 kSegmentInitialPosition defines the initial position of a segment that is meant to be displayed on the left side of the graph.
 This positioning is meant so that a few entries must be added to the segment's history before it becomes visible to the user. This value could be tweaked a little bit with varying results, but the X coordinate should never be larger than 16 (the center of the text view) or the zero values in the segment's history will be exposed to the user.
 */
#define kSegmentInitialPosition CGPointMake(14.0, 56.0);


/*
 Creates a new segment, adds it to 'segments', and returns a weak reference to that segment. Typically a graph will have around a dozen segments, but this depends on the width of the graph view and segments.
 */
-(APLGraphViewSegment*)addSegment
{
    // Create a new segment and add it to the segments array.
    APLGraphViewSegment * segment = [[APLGraphViewSegment alloc] init];
    
    /*
     Add the new segment at the front of the array because -recycleSegment expects the oldest segment to be at the end of the array. As long as we always insert the youngest segment at the front this will be true.
     */
    [self.segments insertObject:segment atIndex:0];

    /* Ensure that newly added segment layers are placed after the text view's layer so that the text view always renders above the segment layer.
     */
    [self.layer insertSublayer:segment.layer below:self.textView.layer];
    
    // Position the segment properly (see the comment for kSegmentInitialPosition).
    segment.layer.position = kSegmentInitialPosition;

    return segment;
}


// Recycles a segment from 'segments' into 'current'.
-(void)recycleSegment
{
    /*
     Start with the last object in the segments array, because it should either be visible onscreen (which indicates that we need more segments) or pushed offscreen (which makes it eligible for recycling).
     */
    APLGraphViewSegment * last = [self.segments lastObject];
    if ([last isVisibleInRect:self.layer.bounds])
    {
        // The last segment is still visible, so create a new segment, which is now the current segment.
        self.current = [self addSegment];
    }
    else
    {
        // The last segment is no longer visible, so reset it in preperation for being recycled.
        [last reset];
        // Position the segment properly (see the comment for kSegmentInitialPosition).
        last.layer.position = kSegmentInitialPosition;
        /*
         Move the segment from the last position in the array to the first position in the array because it is now the youngest segment,
         */
        [self.segments insertObject:last atIndex:0];
        [self.segments removeLastObject];
        // and make it the current segment.
        self.current = last;
    }
}


/*
 The graph view itself exists only to draw the background and gridlines. All other content is drawn either into the GraphTextView or into a layer managed by a GraphViewSegment.
 */
-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Fill in the background.
    CGContextSetFillColorWithColor(context, graphBackgroundColor());
    CGContextFillRect(context, self.bounds);

    // Draw the grid lines.
    CGFloat width = self.bounds.size.width;
    CGContextTranslateCTM(context, 0.0, 56.0);
    DrawGridlines(context, 0.0, width);
}


// Return an up-to-date value for the graph.
- (NSString *)accessibilityValue
{
    if (self.segments.count == 0)
    {
        return nil;
    }

    // Let the GraphViewSegment handle its own accessibilityValue.
    APLGraphViewSegment *graphViewSegment = [self.segments objectAtIndex:0];
    return [graphViewSegment accessibilityValue];
}


@end

