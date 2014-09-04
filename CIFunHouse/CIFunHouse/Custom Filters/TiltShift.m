/*
     File: TiltShift.m
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


@interface TiltShift : CIFilter
{
    CIImage *inputImage;
    NSNumber *inputRadius;
}
@property (retain, nonatomic) CIImage *inputImage;
@property (copy, nonatomic)   NSNumber *inputRadius;
@end


@implementation TiltShift

@synthesize inputImage;
@synthesize inputRadius;

+ (NSDictionary *)customAttributes
{
    return @{
             kCIAttributeFilterDisplayName :
                 @"Tilt Shift",
             
             kCIAttributeFilterCategories :
                 @[kCICategoryBlur, kCICategoryVideo, kCICategoryInterlaced, kCICategoryNonSquarePixels, kCICategoryStillImage],
             
             @"inputRadius" :
                 @{
                     kCIAttributeMin       :  @0.0,
                     kCIAttributeSliderMin :  @0.0,
                     kCIAttributeSliderMax : @30.0,
                     kCIAttributeDefault   : @10.0,
                     kCIAttributeIdentity  :  @0.0,
                     kCIAttributeType      : kCIAttributeTypeScalar
                     }
             };
}

- (void)setDefaults
{
    self.inputRadius = @10.0;
}

- (CIImage *)outputImage
{
    if ( [inputRadius floatValue] < 0.16f ) // if radius is too small to have any effect just return input image
        return inputImage;
    
    CIImage *blurredImage = [[[CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:@"inputRadius", inputRadius, kCIInputImageKey, inputImage, nil] valueForKey:kCIOutputImageKey] imageByCroppingToRect:[inputImage extent]];

    CGFloat h = [inputImage extent].size.height;
    
    CIColor *opaqueGreen      = [CIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    CIColor *transparentGreen = [CIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.0];
    
    CIImage *gradient0 = [[CIFilter filterWithName:@"CILinearGradient" keysAndValues:
                           @"inputPoint0", [CIVector vectorWithX:0.0 Y:h*0.75],
                           @"inputPoint1", [CIVector vectorWithX:0.0 Y:h*0.50],
                           @"inputColor0", opaqueGreen,
                           @"inputColor1", transparentGreen, nil] valueForKey:kCIOutputImageKey];

    CIImage *gradient1 = [[CIFilter filterWithName:@"CILinearGradient" keysAndValues:
                           @"inputPoint0", [CIVector vectorWithX:0.0 Y:h*0.25],
                           @"inputPoint1", [CIVector vectorWithX:0.0 Y:h*0.50],
                           @"inputColor0", opaqueGreen,
                           @"inputColor1", transparentGreen, nil] valueForKey:kCIOutputImageKey];
    
    CIImage *maskImage = [[CIFilter filterWithName:@"CIAdditionCompositing" keysAndValues:
                          kCIInputImageKey, gradient0, kCIInputBackgroundImageKey, gradient1,
                          nil] valueForKey:kCIOutputImageKey];

    return [[CIFilter filterWithName:@"CIBlendWithMask" keysAndValues:
             kCIInputImageKey, blurredImage,
             @"inputMaskImage", maskImage,
             @"inputBackgroundImage", inputImage, nil]
            valueForKey:kCIOutputImageKey];
}

@end
