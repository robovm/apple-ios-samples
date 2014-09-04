/*
     File: PixellatedPeople.m
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


@interface PixellatedPeople : CIFilter
{
    CIImage *inputImage;
    NSNumber *inputScale;
}
@property (retain, nonatomic) CIImage *inputImage;
@property (copy, nonatomic)   NSNumber *inputScale;
@end


@implementation PixellatedPeople

@synthesize inputImage;
@synthesize inputScale;

+ (NSDictionary *)customAttributes
{
    return @{
             kCIAttributeFilterDisplayName :
                 @"Pixellated People",
             
             kCIAttributeFilterCategories :
                 @[kCICategoryDistortionEffect, kCICategoryVideo, kCICategoryInterlaced, kCICategoryNonSquarePixels, kCICategoryStillImage],
             
             @"inputScale" :
                 @{
                     kCIAttributeMin       : @0.1,
                     kCIAttributeSliderMin : @0.1,
                     kCIAttributeSliderMax : @10.0,
                     kCIAttributeDefault   : @10.0,
                     kCIAttributeIdentity  : @1.0,
                     kCIAttributeType      : kCIAttributeTypeDistance
                     }
             };
}

- (void)setDefaults
{
    self.inputScale = @10.0;
}

- (CIImage *)outputImage
{
    static CIDetector *detector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
        
        detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:options];
    });
    
    NSArray *faceArray = [detector featuresInImage:inputImage];
    
    if ( ! faceArray || [faceArray count] <= 0 )
        return inputImage; // no faces found.

    CIImage *maskImage = nil;
    
    for ( CIFeature *f in faceArray )
    {
        CIVector *center = [CIVector vectorWithX:f.bounds.origin.x + f.bounds.size.width/2.0f
                                               Y:f.bounds.origin.y + f.bounds.size.height/2.0f];
        
        CGFloat radius = MIN ( f.bounds.size.width, f.bounds.size.height ) / 1.5;
        
        CIImage *circleImage = [CIFilter filterWithName:@"CIRadialGradient" keysAndValues:
                                 @"inputRadius0", [NSNumber numberWithFloat:radius],
                                 @"inputRadius1", [NSNumber numberWithFloat:radius+1.0f],
                                 @"inputColor0", [CIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0],
                                 @"inputColor1", [CIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.0],
                                 @"inputCenter", center,
                                 nil].outputImage;
        
        if ( nil == maskImage )
            maskImage = circleImage;
        else
            maskImage = [CIFilter filterWithName:@"CISourceOverCompositing" keysAndValues:
                          kCIInputImageKey, circleImage, kCIInputBackgroundImageKey, maskImage,
                          nil].outputImage;
    }
    
    CGRect r = [inputImage extent];
    CGFloat xCenter = r.origin.x + r.size.width / 2.0;
    CGFloat yCenter = r.origin.y + r.size.height / 2.0;
    
    CGFloat scale = (MAX(r.size.width,r.size.height) / 60.0) * [inputScale floatValue];
    
    CIImage *pixellatedImage = [CIFilter filterWithName:@"CIPixellate" keysAndValues:
                                 kCIInputImageKey, inputImage,
                                 @"inputScale", [NSNumber numberWithFloat:scale],
                                 @"inputCenter", [CIVector vectorWithX:xCenter Y:yCenter],
                                 nil].outputImage;
        
    CIImage *result = [CIFilter filterWithName:@"CIBlendWithMask" keysAndValues:
                        kCIInputImageKey, pixellatedImage,
                        @"inputMaskImage", maskImage,
                        kCIInputBackgroundImageKey, inputImage,
                        nil].outputImage;
    
    return result;
}

@end
