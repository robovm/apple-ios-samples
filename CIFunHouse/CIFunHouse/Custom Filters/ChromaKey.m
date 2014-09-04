/*
     File: ChromaKey.m
 Abstract: 
  Version: 1.0
 
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

#if TARGET_OS_IPHONE
#import <CoreImage/CoreImage.h>
#else
#import <QuartzCore/QuartzCore.h>
#endif

@interface ChromaKey : CIFilter
{
    CIImage *inputImage;
    CIImage *inputBackgroundImage;
    NSNumber *inputCubeDimension;
    NSNumber *inputCenterAngle;
    NSNumber *inputAngleWidth;
}
@property (retain, nonatomic) CIImage *inputImage;
@property (retain, nonatomic) CIImage *inputBackgroundImage;
@property (copy, nonatomic) NSNumber *inputCubeDimension;
@property (copy, nonatomic) NSNumber *inputCenterAngle;
@property (copy, nonatomic) NSNumber *inputAngleWidth;
@end


@interface ColorAccent : CIFilter
{
    CIImage *inputImage;
    NSNumber *inputCubeDimension;
    NSNumber *inputCenterAngle;
    NSNumber *inputAngleWidth;
}
@property (retain, nonatomic) CIImage *inputImage;
@property (copy, nonatomic) NSNumber *inputCubeDimension;
@property (copy, nonatomic) NSNumber *inputCenterAngle;
@property (copy, nonatomic) NSNumber *inputAngleWidth;
@end


static const unsigned int minCubeSize = 2;
static const unsigned int maxCubeSize = 64;
static const unsigned int defaultCubeSize = 32;


typedef enum cubeOperation {
    cubeMakeTransparent = 0,
    cubeMakeGrayscale // this is "color accent" mode
} cubeOperation;

    
static void rgbToHSV(const float *rgb,float *hsv)
{
    float minV = MIN(rgb[0], MIN(rgb[1], rgb[2]));
    float maxV = MAX(rgb[0], MAX(rgb[1], rgb[2]));
    
    float chroma = maxV - minV;
    
    hsv[0] = hsv[1] = 0.0;
    hsv[2] = maxV;
    
    if ( maxV != 0.0 )
        hsv[1] = chroma / maxV;
    
    if ( hsv[1] != 0.0 )
    {
        if ( rgb[0] == maxV )
            hsv[0] = (rgb[1] - rgb[2])/chroma;
        else if ( rgb[1] == maxV )
            hsv[0] = 2.0 + (rgb[2] - rgb[0])/chroma;
        else
            hsv[0] = 4.0 + (rgb[0] - rgb[1])/chroma;
        
        hsv[0] /= 6.0;
        if ( hsv[0] < 0.0 )
            hsv[0] += 1.0;
    }
}


static
BOOL buildCubeData(NSMutableData *cubeData, unsigned int cubeSize, float centerAngle,float angleWidth,enum cubeOperation op)
{
    // input angles are in radians but let's make this function work with degrees instead
    centerAngle *= 180.0 / M_PI;
    angleWidth *= 180.0 / M_PI;
    
    uint8_t *c = (uint8_t *)[cubeData mutableBytes];
    float *cFloat = (float *)c;
    
    BOOL useFloat = FALSE;
    
    size_t baseMultiplier = cubeSize * cubeSize * cubeSize * 4;
    
    if ( [cubeData length] == (baseMultiplier * sizeof(uint8_t)) )
        useFloat = FALSE;
    else if ( [cubeData length] == (baseMultiplier * sizeof(float)) )
        useFloat = TRUE;
    else
        return FALSE;
    
    for(int z = 0; z < cubeSize; z++) {
        float blueValue = ((double)z)/(cubeSize-1);
        for(int y = 0; y < cubeSize; y++) {
            float greenValue = ((double)y)/(cubeSize-1);
            for(int x = 0; x < cubeSize; x++) {
                float redValue = ((double)x)/(cubeSize-1);
                
                float hsv[3] = { 0.0, 0.0, 0.0 };
                float rgb[3] = { redValue, greenValue, blueValue };
                
                rgbToHSV(rgb, hsv);
                
                // should have decent HSV values now. (H goes from [0 .. 1])
                // we should have the test for what colors we render as transparent
                // based on some set of hue angles; this not a chroma threshold.
                
                double hueValue = hsv[0] * 360.0;
                
                float alphaValue = 1.0;
                
                float delta = fmodf(hueValue - centerAngle, 360.0);

                delta = delta < 0.0 ? delta + 360.0 : delta;
                
                BOOL shouldProcessPixels = delta < (angleWidth / 2.0);
                
                switch ( op ) {
                    case cubeMakeTransparent:
                        if ( shouldProcessPixels )
                            alphaValue = 0.0;
                        break;
                        
                    case cubeMakeGrayscale:
                        if ( ! shouldProcessPixels ) // convert from RGB to luminance value
                            rgb[0] = rgb[1] = rgb[2] = 0.299f * rgb[0] + 0.587f * rgb[1] + 0.114f * rgb[2];
                        
                        break;
                        
                    default:
                        // no-op
                        break;
                }
                
                // RGBA channel order.
                
                if ( useFloat ) {
                    *cFloat++ = rgb[0] * alphaValue;
                    *cFloat++ = rgb[1] * alphaValue;
                    *cFloat++ = rgb[2] * alphaValue;
                    *cFloat++ = alphaValue;
                } else {
                    *c++ = (uint8_t) (255.0 * rgb[0] * 1); //alphaValue);
                    *c++ = (uint8_t) (255.0 * rgb[1] * 1); // alphaValue);
                    *c++ = (uint8_t) (255.0 * rgb[2] * 1); //alphaValue);
                    *c++ = (uint8_t) (255.0 * alphaValue);
                }
            }
        }
    }
    
    return TRUE;
}

static
NSDictionary *customAttrs(cubeOperation op)
{
    CGFloat centerAngle = 0.0;
    CGFloat angleWidth = 0.0;
    NSString *displayName = @"";
    
    switch ( op ) {
        case cubeMakeTransparent:
            centerAngle = 120.0;
            angleWidth = 100.0;
            displayName = @"Chroma Key";
            break;
            
        case cubeMakeGrayscale:
            centerAngle = 0.0;
            angleWidth = 60.0;
            displayName = @"Color Accent";
            break;
            
        default:
            break;
    }
    
    return @{
             kCIAttributeFilterDisplayName : displayName,
             
             kCIAttributeFilterCategories :
                 @[kCICategoryColorEffect, kCICategoryVideo, kCICategoryInterlaced, kCICategoryNonSquarePixels, kCICategoryStillImage],
            
             @"inputCubeDimension" :
                 @{
                     kCIAttributeMin       : @2.0,
                     kCIAttributeSliderMin : @2.0,
                     kCIAttributeSliderMax : @64.0,
                     kCIAttributeMax       : @64.0,
                     kCIAttributeDefault   : @(defaultCubeSize),
                     kCIAttributeType      : kCIAttributeTypeDistance
                     },
             
             @"inputCenterAngle" :
                 @{
                     kCIAttributeSliderMin : @(-M_PI),
                     kCIAttributeSliderMax : @(M_PI),
                     kCIAttributeDefault   : @(centerAngle * M_PI / 180.0),
                     kCIAttributeType      : kCIAttributeTypeAngle
                     },
             
             @"inputAngleWidth" :
                 @{
                     kCIAttributeMin       : @0.0,
                     kCIAttributeSliderMin : @0.0,
                     kCIAttributeSliderMax : @(2.0*M_PI),
                     kCIAttributeMax       : @(2.0*M_PI),
                     kCIAttributeDefault   : @(angleWidth * M_PI / 180.0),
                     kCIAttributeType      : kCIAttributeTypeAngle
                     },
            };
}


@implementation ChromaKey

@synthesize inputImage, inputBackgroundImage;
@synthesize inputCubeDimension, inputCenterAngle, inputAngleWidth;

+ (NSDictionary *)customAttributes
{
    return customAttrs(cubeMakeTransparent);
}

- (void)setDefaults
{
    const double centerAngle = 120.0;
    const double angleWidth = 100.0;
    self.inputCubeDimension = @(defaultCubeSize);
    self.inputCenterAngle = @(centerAngle * M_PI / 180.0);
    self.inputAngleWidth = @(angleWidth * M_PI / 180.0);
}

- (CIImage *)outputImage
{
    if ( inputCubeDimension.intValue <= 0 || nil == inputBackgroundImage || [inputAngleWidth floatValue] == 0.0 )
        return inputImage;
    
    CIFilter *colorCube = [CIFilter filterWithName:@"CIColorCube"];
    
    const unsigned int cubeSize = MAX(MIN(inputCubeDimension.intValue, maxCubeSize), minCubeSize);
    size_t baseMultiplier = cubeSize * cubeSize * cubeSize * 4;
    
    // you can use either uint8 data or float data by just setting this variable
    BOOL useFloat = FALSE;    
    NSMutableData *cubeData = [NSMutableData dataWithLength:baseMultiplier * (useFloat ? sizeof(float) : sizeof(uint8_t))];
    
    if ( ! cubeData )
        return inputImage;
    
    if ( ! buildCubeData(cubeData, cubeSize, [inputCenterAngle floatValue], [inputAngleWidth floatValue], cubeMakeTransparent) )
        return inputImage;
    
    // don't just use inputCubeSize directly because it is a float and we want to use an int.
    [colorCube setValue:[NSNumber numberWithInt:cubeSize] forKey:@"inputCubeDimension"];
    [colorCube setValue:cubeData forKey:@"inputCubeData"];
    [colorCube setValue:inputImage forKey:kCIInputImageKey];

    CIImage *coloredKeyedImage = [colorCube valueForKey:kCIOutputImageKey];
    
    [colorCube setValue:nil forKey:@"inputCubeData"];
    [colorCube setValue:nil forKey:kCIInputImageKey];
    
    CIFilter *sourceOver = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [sourceOver setValue:coloredKeyedImage forKey:kCIInputImageKey];
    [sourceOver setValue:inputBackgroundImage forKey:kCIInputBackgroundImageKey];
    
    CIImage *outputImage = [sourceOver valueForKey:kCIOutputImageKey];
    
    [sourceOver setValue:nil forKey:kCIInputImageKey];
    [sourceOver setValue:nil forKey:kCIInputBackgroundImageKey];
    
    return outputImage;
}

@end

@implementation ColorAccent

@synthesize inputImage;
@synthesize inputCubeDimension, inputCenterAngle, inputAngleWidth;

+ (NSDictionary *)customAttributes
{
    return customAttrs(cubeMakeGrayscale);
}

- (void)setDefaults
{
    const double centerAngle = 0.0;
    const double angleWidth = 60.0;
    self.inputCubeDimension = @(defaultCubeSize);
    self.inputCenterAngle = @(centerAngle * M_PI / 180.0);
    self.inputAngleWidth = @(angleWidth * M_PI / 180.0);
}

- (CIImage *)outputImage
{
    if ( inputCubeDimension.intValue <= 0 || [inputAngleWidth floatValue] == 0.0)
        return inputImage;
    
    CIFilter *colorCube = [CIFilter filterWithName:@"CIColorCube"];
    
    const unsigned int cubeSize = MAX(MIN(inputCubeDimension.intValue, maxCubeSize), minCubeSize);
 
    size_t baseMultiplier = cubeSize * cubeSize * cubeSize * 4;

    // you can use either uint8 data or float data by just setting this variable
    BOOL useFloat = FALSE;    
    NSMutableData *cubeData = [NSMutableData dataWithLength:baseMultiplier * (useFloat ? sizeof(float) : sizeof(uint8_t))];
    
    if ( ! cubeData )
        return inputImage;
    
    if ( ! buildCubeData(cubeData, cubeSize, [inputCenterAngle floatValue], [inputAngleWidth floatValue], cubeMakeGrayscale) )
        return inputImage;
    
    // don't just use inputCubeSize directly because it is a float and we want to use an int.
    [colorCube setValue:[NSNumber numberWithInt:cubeSize] forKey:@"inputCubeDimension"];
    [colorCube setValue:cubeData forKey:@"inputCubeData"];
    [colorCube setValue:inputImage forKey:kCIInputImageKey];
    
    CIImage *outputImage = [colorCube valueForKey:kCIOutputImageKey];
    
    [colorCube setValue:nil forKey:@"inputCubeData"];
    [colorCube setValue:nil forKey:kCIInputImageKey];
    
    return outputImage;
}

@end
