/*
    File: compactgrid.c
Abstract: 
This is a standalone command line program to be run on Mac OS X that performs preprocessing to compact
a USGS tab separated earthquake hazard grid file into a smaller binary format that is faster to load
on a mobile device.

See http://earthquake.usgs.gov/hazards/products/conterminous/2008/data/.

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

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <libkern/OSByteOrder.h>

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr, "Usage %s gridfile.tab gridfile.bin\n", argv[0]);
        exit(1);
    }
    
    char *inpath = argv[1];
    char *outpath = argv[2];
    
    // read in the whole file first in order to establish the bounds of the grid.
    
    FILE *in = fopen(inpath, "r");
    
    size_t gridCount = 1000;
    int read = 0;
    float *grid = malloc(sizeof(float) * gridCount);
    
    double lastLat = -500;
    double lastLon = -500;
    float gridSize = -1;
    int32_t gridWidth = -1;
    double originLat = 0;
    double originLon = 0;
    
    char line[50];
    
    while (fgets(line, sizeof(line), in)) {
        double lon, lat;
        float value;
        if (3 != sscanf(line, "%lf %lf %f", &lon, &lat, &value)) {
            fprintf(stderr, "unparseable line: %s", line);
            exit(2);
        }
        
        if (lastLat < -200 && lastLon < -200) {
            // first value, set the origin
            originLat = lat;
            originLon = lon;
        } else if (gridSize == -1) {
            // second value, set the grid size
            gridSize = fabs(lon - lastLon);
        } else if (lat != lastLat && gridWidth < 0) {
            // end of first row, set the gridWidth
            gridWidth = read;
        }
        
        if (read == gridCount) {
            gridCount *= 2;
            grid = realloc(grid, sizeof(float) * gridCount);
        }
                
        grid[read] = value;
        
        lastLon = lon;
        lastLat = lat;
        
        read++;
    }
    
    int32_t gridHeight = read / gridWidth;
    
    fclose(in);
    
    // write out the binary version of the file
    // [4 bytes] - int32 little endian - grid origin latitudeE6
    // [4 bytes] - int32 little endian - grid origin longitudeE6
    // [4 bytes] - int32 little endian - grid step sizeE6
    // [4 bytes] - int32 little endian - grid width
    // [4 bytes] - int32 little endian - grid height
    // [N bytes] - list of width*height int16 little endian grid data as E4 fixed point
    
#define E6 (1000000.0)
#define E4 (10000.0)
    
    FILE *out = fopen(outpath, "wb");
        
    int32_t latE6 = OSSwapHostToLittleInt32(originLat * E6);
    int32_t lonE6 = OSSwapHostToLittleInt32(originLon * E6);
    int32_t gridSizeE6 = OSSwapHostToLittleInt32(gridSize * E6);
    int32_t widthSwapped = OSSwapHostToLittleInt32(gridWidth);
    int32_t heightSwapped = OSSwapHostToLittleInt32(gridHeight);
    
    fwrite(&latE6, sizeof(int32_t), 1, out);
    fwrite(&lonE6, sizeof(int32_t), 1, out);
    fwrite(&gridSizeE6, sizeof(int32_t), 1, out);
    fwrite(&widthSwapped, sizeof(int32_t), 1, out);
    fwrite(&heightSwapped, sizeof(int32_t), 1, out);
    
    int i;
    for (i = 0; i < read; i++) {
        int16_t valueSwapped = OSSwapHostToLittleInt16(grid[i] * E4);
        fwrite(&valueSwapped, sizeof(int16_t), 1, out);
    }
    
    fclose(out);
    
    return 0;
}

