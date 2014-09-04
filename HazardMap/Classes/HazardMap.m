/*
     File: HazardMap.m 
 Abstract: MKOverlay model object representing a USGS earthquake hazard map.
 See http://earthquake.usgs.gov/hazards/products/conterminous/2008/data/. 
 This class demonstrates how to project latitude and longitude coordinates representing the corners
 of a square into an MKMapRect. 
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

#import "HazardMap.h"


@implementation HazardMap
 
- (BOOL)parseGridFile:(NSString *)path
{
    free(grid);
    grid = NULL;
    
    FILE *f = fopen([path UTF8String], "r");
    if (!f) {
        perror("Couldn't open grid file");
        return NO;
    }
    
    // [4 bytes] - int32 little endian - grid origin latitudeE6
    // [4 bytes] - int32 little endian - grid origin longitudeE6
    // [4 bytes] - int32 little endian - grid step sizeE6
    // [4 bytes] - int32 little endian - grid width
    // [4 bytes] - int32 little endian - grid height
    // [N bytes] - list of width*height int16 little endian grid data as E4 fixed point
    
#define E6 (1000000.0)
#define E4 (10000.0)
    
    int32_t latE6, lonE6, gridSizeE6, widthSwapped, heightSwapped;
    
    fread(&latE6, sizeof(int32_t), 1, f);
    fread(&lonE6, sizeof(int32_t), 1, f);
    fread(&gridSizeE6, sizeof(int32_t), 1, f);
    fread(&widthSwapped, sizeof(int32_t), 1, f);
    fread(&heightSwapped, sizeof(int32_t), 1, f);
    
    origin.latitude = (CLLocationDegrees)((int32_t)OSSwapLittleToHostInt32(latE6)) / E6;
    origin.longitude = (CLLocationDegrees)((int32_t)OSSwapLittleToHostInt32(lonE6)) / E6;
    gridSize = (CLLocationDegrees)(OSSwapLittleToHostInt32(gridSizeE6)) / E6;
    gridWidth = OSSwapLittleToHostInt32(widthSwapped);
    gridHeight = OSSwapLittleToHostInt32(heightSwapped);
    
    size_t toRead = gridWidth * gridHeight;
    grid = malloc(sizeof(float) * toRead);
    
    int i;
    for (i = 0; i < toRead; i++) {
        int16_t valueE4;
        fread(&valueE4, sizeof(int16_t), 1, f);
        float value = (float)((int16_t)OSSwapLittleToHostInt16(valueE4)) / E4;
        grid[i] = value;
    }
    
#undef E6
#undef E4
    
    fclose(f);
    
    NSLog(@"Read %ld records from %@", toRead, path);
    
    return YES;
}

- (id)initWithHazardMapFile:(NSString *)path
{
    if (self = [super init]) {
        if (![self parseGridFile:path]) {
            NSLog(@"Couldn't parse file at path: %@", path);
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    free(grid);
}

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(origin.latitude - (gridHeight * gridSize / 2.0),
                                      origin.longitude - (gridWidth * gridSize / 2.0));                                      
}

- (MKMapRect)boundingMapRect
{
    // Compute the boundingMapRect given the origin, the gridSize and the grid width and height
    
    MKMapPoint upperLeft = MKMapPointForCoordinate(origin);
    
    CLLocationCoordinate2D lowerRightCoord = 
        CLLocationCoordinate2DMake(origin.latitude - (gridSize * gridHeight),
                                   origin.longitude + (gridSize * gridWidth));
                                   
    MKMapPoint lowerRight = MKMapPointForCoordinate(lowerRightCoord);
    
    double width = lowerRight.x - upperLeft.x;
    double height = lowerRight.y - upperLeft.y;

    MKMapRect bounds = MKMapRectMake(upperLeft.x, upperLeft.y, width, height);
    return bounds;
}

- (void)hazardsInMapRect:(MKMapRect)rect
                 atScale:(MKZoomScale)scale
                  values:(float **)valuesOut
              boundaries:(MKMapRect **)boundariesOut
                   count:(int *)count
{
    CLLocationCoordinate2D rectOrigin = MKCoordinateForMapPoint(rect.origin);
    CLLocationCoordinate2D rectMax = MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMaxX(rect), MKMapRectGetMaxY(rect)));

    // Don't want any returned grid square to be drawn smaller than 2pt.  
    // When the map is zoomed way out at world level, apply a reduction to
    // the grid and just do nearest neighbor sampling to find the a value
    double approximatePtsPerSquare = scale * (MKMapSizeWorld.width / (180.0 / gridSize));
    int gridReduction = MAX(1, (int)(4.0 / approximatePtsPerSquare));
    
    // Find the bounding indices (left, right, top, bottom) into the grid array
    int left = (rectOrigin.longitude - origin.longitude) / gridSize;
    left = MAX(left, 0);
    left = MIN(left, gridWidth - 1);
    
    int right = (rectMax.longitude - origin.longitude) / gridSize;
    right = MAX(right, 0);
    right = MIN(right, gridWidth - 1);
    
    int top = (origin.latitude - rectOrigin.latitude) / gridSize;
    top = MAX(top, 0);
    top = MIN(top, gridHeight - 1);
    
    int bottom = (origin.latitude - rectMax.latitude) / gridSize;
    bottom = MAX(bottom, 0);
    bottom = MIN(bottom, gridHeight - 1);
    
    int width = 1 + ((right - left) / gridReduction);
    int height = 1 + ((bottom - top) / gridReduction);
    
    *count = (width) * (height);
    MKMapRect *boundaries = malloc(sizeof(MKMapRect) * *count);
    float *values = malloc(sizeof(float) * *count);
    
    // Loop through the grid by the gridReduction factor, sampling values along the way
    int x, y, read = 0;
    for (y = top; y <= bottom; y += gridReduction) {
        for (x = left; x <= right; x += gridReduction) {
            // Convert an upper-left, lower-right latitude and longitude to an MKMapRect
            CLLocationCoordinate2D valueOrigin = 
                CLLocationCoordinate2DMake(origin.latitude - (y * gridSize),
                                           origin.longitude + (x * gridSize));
            CLLocationCoordinate2D valueLowerRight = 
                CLLocationCoordinate2DMake(valueOrigin.latitude - (gridSize * gridReduction),
                                           valueOrigin.longitude + (gridSize * gridReduction));
            
            MKMapPoint upperLeft = MKMapPointForCoordinate(valueOrigin);
            MKMapPoint lowerRight = MKMapPointForCoordinate(valueLowerRight);
            
            boundaries[read] = MKMapRectMake(upperLeft.x,
                                             upperLeft.y,
                                             lowerRight.x - upperLeft.x,
                                             lowerRight.y - upperLeft.y);
            
            // Read the grid value into the values array
            values[read] = *(grid + (gridWidth * y) + x);
            
            read++;
        }
    }
    
    *boundariesOut = boundaries;
    *valuesOut = values;
}

@end
