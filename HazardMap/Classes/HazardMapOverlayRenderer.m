/*
     File: HazardMapOverlayRenderer.m
 Abstract: MKOverlayRenderer subclass that renders a USGS earthquake hazard map represented by the
 HazardMap class.  This class demonstrates how to convert points represented as MKMapRects into
 the local coordinate system and then fill those rectangles to visualize earthquake hazards across
 the continental United States.
  Version: 1.2
 
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

#import "HazardMapOverlayRenderer.h"
#import "HazardMap.h"

#define NUM_COLORS 14

@interface HazardMapOverlayRenderer ()
{
    CGColorRef *colors;
}
@end

#pragma mark -

@implementation HazardMapOverlayRenderer

// Create a table of possible colors to draw a grid cell with
- (void)initColors
{
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    colors = malloc(sizeof(CGColorRef) * NUM_COLORS);
    int i = 0;
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ .588, .294, .78, 1 }); // 1.00
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ .784, .471, .82, 1 }); // 0.77
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ 1, 0, 0, 1 }); // 0.59
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ 1, .392, 0, 1 }); // 0.46
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ 1, .392, 0, 1 }); // 0.35
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ 1, .784, 0, 1 }); // 0.27
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ 1, 1, .5, 1 }); // 0.21
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ .745, .941, .467, 1 }); // 0.16
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ .122, 1, .31, 1 }); // 0.12
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ .588, 1, .941, 1 }); // 0.10
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ .784, 1, 1, 1 }); // 0.08
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ .843, 1, 1, 1 }); // 0.06
    colors[i++] = CGColorCreate(rgb, (CGFloat[]){ .902, 1, 1, 1 }); // 0.04
    colors[i] = CGColorCreate(rgb, (CGFloat[]){ .784, .784, .784, 1 }); // 0.03
    CGColorSpaceRelease(rgb);
}

// Look up a color in the table of colors for a peak ground acceleration
- (CGColorRef)colorForAcceleration:(CGFloat)value
{
    if (value > 0.77) return colors[0];
    if (value > 0.59) return colors[1];
    if (value > 0.46) return colors[2];
    if (value > 0.35) return colors[3];
    if (value > 0.27) return colors[4];
    if (value > 0.21) return colors[5];
    if (value > 0.16) return colors[6];
    if (value > 0.12) return colors[7];
    if (value > 0.10) return colors[8];
    if (value > 0.08) return colors[9];
    if (value > 0.06) return colors[10];
    if (value > 0.04) return colors[11];
    if (value > 0.03) return colors[12];
    if (value > 0.02) return colors[13];
    return NULL;
}

- (id)initWithOverlay:(id <MKOverlay>)overlay
{
    if (self = [super initWithOverlay:overlay])
    {
        [self initColors];
    }
    return self;
}

- (void)dealloc
{
    int i;
    for (i = 0; i < NUM_COLORS; i++)
    {
        CGColorRelease(colors[i]);
    }
    free(colors);
}

- (void)drawMapRect:(MKMapRect)mapRect
          zoomScale:(MKZoomScale)zoomScale
          inContext:(CGContextRef)ctx
{
    HazardMap *hazards = (HazardMap *)self.overlay;
    
    float *values = NULL;
    MKMapRect *boundaries = NULL;
    int count = 0;
    
    // Fetch the grid values out of the model for this mapRect and zoomScale.
    [hazards hazardsInMapRect:mapRect
                      atScale:zoomScale
                       values:&values
                   boundaries:&boundaries
                        count:&count];
    
    CGContextSetAlpha(ctx, 0.5);
    
    // For each grid value that is colorable, color in its corresponding
    // boundary MKMapRect with the appropriate color.
    int i;
    for (i = 0; i < count; i++)
    {
        float value = values[i];
        MKMapRect boundary = boundaries[i];
        
        CGColorRef color = [self colorForAcceleration:value];
        if (color) {
            CGContextSetFillColorWithColor(ctx, color);
            
            // Convert the MKMapRect (absolute points on the map proportional to screen points) to
            // a CGRect (points relative to the origin of this view) that can be drawn.
            CGRect boundaryCGRect = [self rectForMapRect:boundary];
            
            CGContextFillRect(ctx, boundaryCGRect);
        }
    }
    
    free(values);
    free(boundaries);
}

@end
