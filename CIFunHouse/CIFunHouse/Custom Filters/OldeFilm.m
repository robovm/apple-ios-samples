/*
     File: OldeFilm.m
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


@interface OldeFilm : CIFilter
{
    CIImage *inputImage;
    NSNumber *inputSpeed;
}
@property (retain, nonatomic) CIImage *inputImage;
@property (copy, nonatomic)   NSNumber *inputSpeed;
@end


@implementation OldeFilm

@synthesize inputImage;
@synthesize inputSpeed;

+ (NSDictionary *)customAttributes
{
    return @{
             kCIAttributeFilterDisplayName :
                 @"Olde Film",
             
             kCIAttributeFilterCategories :
                 @[kCICategoryColorEffect, kCICategoryVideo, kCICategoryInterlaced, kCICategoryNonSquarePixels, kCICategoryStillImage],
             
             @"inputSpeed" :
                 @{
                     kCIAttributeMin       :  @0.0,
                     kCIAttributeSliderMin :  @0.0,
                     kCIAttributeSliderMax : @10.0,
                     kCIAttributeDefault   :  @1.0,
                     kCIAttributeType      : kCIAttributeTypeScalar
                     }
             };
}

- (void)setDefaults
{
    self.inputSpeed = @1.0;
}

- (CIImage *)outputImage
{
    CIImage *sepiaImage = [CIFilter filterWithName:@"CISepiaTone" keysAndValues:@"inputIntensity", @1.0, kCIInputImageKey, inputImage, nil].outputImage;

    CIImage *randomImage = [CIFilter filterWithName:@"CIRandomGenerator"].outputImage;
    
    static CFAbsoluteTime startTime;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        startTime = CFAbsoluteTimeGetCurrent();
    });
    
    CGSize size = [inputImage extent].size;
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    BOOL moveInY = NO;
    
    switch ( orientation) {
        case UIDeviceOrientationUnknown:
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationPortraitUpsideDown: // this should be different ... 
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            moveInY = NO;
            break;
            
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            moveInY = YES;
            break;
            
        default:
            moveInY = NO;
            break;
    }
    
    CGFloat amount = -fmodf((CFAbsoluteTimeGetCurrent() - startTime) * 500.0 * [inputSpeed floatValue], MAX(size.width,size.height));
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(amount, amount);
    
    CIImage *specksRandomImage = [[randomImage imageByApplyingTransform:transform] imageByCroppingToRect:[inputImage extent]];
    
    CGFloat fineAmount = 0.01;
    
    CIImage *whiteSpecksImage = [CIFilter filterWithName:@"CIColorMatrix" keysAndValues:kCIInputImageKey, specksRandomImage,
                                  @"inputRVector", [CIVector vectorWithX:0.0 Y:1.0 Z:0.0 W:0.0],
                                  @"inputGVector", [CIVector vectorWithX:0.0 Y:1.0 Z:0.0 W:0.0],
                                  @"inputBVector", [CIVector vectorWithX:0.0 Y:1.0 Z:0.0 W:0.0],
                                  @"inputAVector", [CIVector vectorWithX:0.0 Y:fineAmount Z:0.0 W:0.0],
                                  @"inputBiasVector", [CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:0.0],
                                  nil].outputImage;
        
    CIImage *sepiaPlusWhiteSpecksImage = [CIFilter filterWithName:@"CISourceOverCompositing" keysAndValues:
                                           kCIInputImageKey, whiteSpecksImage,
                                           kCIInputBackgroundImageKey, sepiaImage,
                                           nil].outputImage;
    
    // only translate in "y" direction with respect to current position of device
    transform = moveInY ? CGAffineTransformTranslate(transform, -amount, 0.0) : CGAffineTransformTranslate(transform, 0.0, -amount);
    
    CIImage *darkScratchesRandomImage = moveInY ?
        [randomImage imageByApplyingTransform:CGAffineTransformScale(transform, 1.5, 25.0)] :
        [randomImage imageByApplyingTransform:CGAffineTransformScale(transform, 25.0, 1.5)];
    
    CGFloat threshold = 3.659f;
    
    CIImage *darkScratchesImage = [CIFilter filterWithName:@"CIColorMatrix" keysAndValues:kCIInputImageKey, darkScratchesRandomImage,
                                    @"inputRVector", [CIVector vectorWithX:threshold Y:0.0 Z:0.0 W:0.0],
                                    @"inputGVector", [CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:0.0],
                                    @"inputBVector", [CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:0.0],
                                    @"inputAVector", [CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:0.0],
                                    @"inputBiasVector", [CIVector vectorWithX:0.0 Y:1.0 Z:1.0 W:1.0],
                                    nil].outputImage;
    
    darkScratchesImage = [CIFilter filterWithName:@"CIMinimumComponent" keysAndValues:kCIInputImageKey, darkScratchesImage, nil].outputImage;
    
    // should be using sepia + white specks image here.
    CIImage *outputImage = [CIFilter filterWithName:@"CIMultiplyCompositing" keysAndValues:
                             kCIInputImageKey, sepiaPlusWhiteSpecksImage,
                             @"inputBackgroundImage", darkScratchesImage,
                             nil].outputImage;
    
    return outputImage;
}

@end
