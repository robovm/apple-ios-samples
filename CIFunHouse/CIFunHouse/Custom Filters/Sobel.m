/*
     File: Sobel.m
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


@interface SobelEdgeH : CIFilter
{
    CIImage *inputImage;
    NSNumber *inputGain;
}
@property (retain, nonatomic) CIImage *inputImage;
@property (copy, nonatomic)   NSNumber *inputGain;
@end


@interface SobelEdgeV : CIFilter
{
    CIImage *inputImage;
    NSNumber *inputGain;
}
@property (retain, nonatomic) CIImage *inputImage;
@property (copy, nonatomic)   NSNumber *inputGain;
@end


@implementation SobelEdgeH

@synthesize inputImage;
@synthesize inputGain;

+ (NSDictionary *)customAttributes
{
    return @{
             kCIAttributeFilterDisplayName : @"Sobel Edge Horizontal",
             kCIAttributeFilterCategories :  @[kCICategoryGradient, kCICategoryVideo, kCICategoryInterlaced, kCICategoryStillImage],
             @"inputGain" :
                 @{
                     kCIAttributeSliderMin : @-1.0,
                     kCIAttributeSliderMax :  @1.0,
                     kCIAttributeDefault   :  @1.0,
                     kCIAttributeType      : kCIAttributeTypeScalar
                     }
             };
}

- (void)setDefaults
{
    self.inputGain = @1.0;
}

- (CIImage *)outputImage
{
    if (inputImage == nil)
        return nil;
    
    double g = inputGain.doubleValue;
    
    const CGFloat weights[] = { 1*g, 0, -1*g,
                                2*g, 0, -2*g,
                                1*g, 0, -1*g};
    CIImage* result = nil;
    
    // The sobel convoloution will produce an image that is 0.5,0.5,0.5,0.5 whereever the image is flat
    // On edges the image will contain values that deviate from that based on the strength and
    // direction of the edge
    
    result = [CIFilter filterWithName:@"CIConvolution3X3" keysAndValues:
                                    @"inputImage", inputImage,
                                    @"inputWeights", [CIVector vectorWithValues:weights count:9],
                                    @"inputBias", @0.5,
                                    nil].outputImage;
    
    // Add filters to mage the image look pretty for display purposes.
    // We want the display image to be 0,0,0,1 where the image is flat
    // and closer to 1,1,1,1 based on the strength of the edge
    
    result = [CIFilter filterWithName:@"CISourceOverCompositing" keysAndValues:
              @"inputImage", result,
              @"inputBackgroundImage", [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0 alpha:1]],
              nil].outputImage;
    
    
    result = [CIFilter filterWithName:@"CIColorPolynomial" keysAndValues:
                                        @"inputImage", result,
                                        @"inputRedCoefficients", [CIVector vectorWithX:1.0 Y:-4.0 Z:4.0 W:0.0],
                                        @"inputGreenCoefficients", [CIVector vectorWithX:1.0 Y:-4.0 Z:4.0 W:0.0],
                                        @"inputBlueCoefficients", [CIVector vectorWithX:1.0 Y:-4.0 Z:4.0 W:0.0],
                                    nil].outputImage;

    return result;
}

@end


@implementation SobelEdgeV

@synthesize inputImage;
@synthesize inputGain;

+ (NSDictionary *)customAttributes
{
    return @{
             kCIAttributeFilterDisplayName : @"Sobel Edge Vertical",
             kCIAttributeFilterCategories :  @[kCICategoryGradient, kCICategoryVideo, kCICategoryInterlaced, kCICategoryStillImage],
             @"inputGain" :
                 @{
                     kCIAttributeSliderMin : @-1.0,
                     kCIAttributeSliderMax :  @1.0,
                     kCIAttributeDefault   :  @1.0,
                     kCIAttributeType      : kCIAttributeTypeScalar
                     }
             };
}

- (void)setDefaults
{
    self.inputGain = @1.0;
}

- (CIImage *)outputImage
{
    if (inputImage == nil)
        return nil;
    
    double g = inputGain.doubleValue;
    
    const CGFloat weights[] = {-1*g,-2*g,-1*g,
                                  0,   0,   0,
                                1*g, 2*g, 1*g};
    
    CIImage* result = nil;
    
    // The sobel convoloution will produce an image that is 0.5,0.5,0.5,0.5 whereever the image is flat
    // On edges the image will contain values that deviate from that based on the strength and
    // direction of the edge
    
    result = [CIFilter filterWithName:@"CIConvolution3X3" keysAndValues:
              @"inputImage", inputImage,
              @"inputWeights", [CIVector vectorWithValues:weights count:9],
              @"inputBias", @0.5,
              nil].outputImage;
    
    // Add filters to mage the image look pretty for display purposes.
    // We want the display image to be 0,0,0,1 where the image is flat
    // and closer to 1,1,1,1 based on the strength of the edge
    
    result = [CIFilter filterWithName:@"CISourceOverCompositing" keysAndValues:
              @"inputImage", result,
              @"inputBackgroundImage", [CIImage imageWithColor:[CIColor colorWithRed:0 green:0 blue:0 alpha:1]],
              nil].outputImage;
    
    
    result = [CIFilter filterWithName:@"CIColorPolynomial" keysAndValues:
              @"inputImage", result,
              @"inputRedCoefficients", [CIVector vectorWithX:1.0 Y:-4.0 Z:4.0 W:0.0],
              @"inputGreenCoefficients", [CIVector vectorWithX:1.0 Y:-4.0 Z:4.0 W:0.0],
              @"inputBlueCoefficients", [CIVector vectorWithX:1.0 Y:-4.0 Z:4.0 W:0.0],
              nil].outputImage;
    
    return result;
}

@end
