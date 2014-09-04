/*
     File: DistortionsDemo.m
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


@interface DistortionDemo : CIFilter
{
    CIImage *inputImage;
}
@property (retain, nonatomic) CIImage *inputImage;
@end


@implementation DistortionDemo

@synthesize inputImage;

+ (NSDictionary *)customAttributes
{
    return @{
             kCIAttributeFilterDisplayName : @"Distortion Demo",
             kCIAttributeFilterCategories :  @[kCICategoryDistortionEffect, kCICategoryVideo, kCICategoryInterlaced, kCICategoryStillImage]
             };
}

- (CIImage *)outputImage
{
    if (inputImage == nil)
        return nil;
    
    NSArray* filterNames = @[ @"CIHoleDistortion",
                              @"CIBumpDistortion",
                              @"CIVortexDistortion",
                              @"CITwirlDistortion",
                              @"CICircleSplashDistortion"];
    
    const double twoPi = M_PI * 2.0;
    CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
    time = fmod(time, filterNames.count * twoPi);
    
    CGRect extent = inputImage.extent;
    
    double cx = extent.origin.x + extent.size.width / 2.0;
    double cy = extent.origin.y + extent.size.height / 2.0;
    cx += cos(time) * extent.size.width * 0.3;
    cy += sin(time) * extent.size.height * 0.3;
    
    double minDim = MIN(extent.size.width, extent.size.height);
    
    double r = (cos(2.0 * time) + 1.20) * minDim * 0.15;
    
    CIVector* center = [CIVector vectorWithX:cx Y:cy];
    
    int whichFilter = (int)floor(time / twoPi);
    
    CIFilter* f = [CIFilter filterWithName:filterNames[whichFilter] keysAndValues:
                   @"inputImage", inputImage,
                   @"inputCenter", center,
                   @"inputRadius", @(r), nil];

    return f.outputImage;
}

@end
