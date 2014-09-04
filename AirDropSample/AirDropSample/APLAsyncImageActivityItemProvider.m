/*
 
     File: APLAsyncImageActivityItemProvider.m
 Abstract: Subclass of UIActivityItemProvider that downloads a file asynchronously after the user has chosen their sharing option.
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

#import "APLAsyncImageActivityItemProvider.h"
#import "UIImage+Resize.h"

@interface APLAsyncImageActivityItemProvider()

@property (strong, atomic) UIImage *image; //Use atomic to make sure access is synchronized.

@end

@implementation APLAsyncImageActivityItemProvider


- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return [[UIImage alloc] init];
}

/****************************************************
 item
 
 The item method runs on a secondary thread using an NSOperationQueue (UIActivityItemProvider subclasses NSOperation).
 The implementation of this method loads an image from the app's bundle and applies two filters to it.
 
 ******************************************************/
- (id)item
{
    //Notify the delegate on the main thread that the processing is beginning.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate imageActivityItemProviderPreprocessingDidBegin:self];
    });
    
    //Load image.
    UIImage *image = [UIImage imageNamed:@"Flower.png"];
    
    //Start progress.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate imageActivityItemProvider:self preprocessingProgressDidUpdate:0.2];
    });
    
    //Create Core Image context.
    CIContext *context = [CIContext contextWithOptions:nil];
    
    //Scale image for context.
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize imageSize = CGSizeMake([context inputImageMaximumSize].width/scale/1.5, [context inputImageMaximumSize].height/scale/1.5);
    image = [UIImage imageWithImage:image scaledToFitToSize:imageSize];
    
    //Update progress after scaling.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate imageActivityItemProvider:self preprocessingProgressDidUpdate:0.5];
    });
    
    
    //Add sepia filter.
    CIImage *sepiaImage = [CIImage imageWithCGImage:[image CGImage]];
    CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"];
    [filter setValue:sepiaImage forKey:kCIInputImageKey];
    CIImage *sepiaResult = [filter valueForKey:kCIOutputImageKey];
    
    //First filter complete.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate imageActivityItemProvider:self preprocessingProgressDidUpdate:0.7];
    });
    
    //Add gloom filter.
    CIFilter *gloom = [CIFilter filterWithName:@"CIGloom"];
    [gloom setValue:sepiaResult forKey:kCIInputImageKey];
    [gloom setValue: [NSNumber numberWithFloat: 1.75] forKey: @"inputIntensity"];
    CIImage *gloomResult = [gloom valueForKey:kCIOutputImageKey];
    
    //Second filter complete.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate imageActivityItemProvider:self preprocessingProgressDidUpdate:0.9];
    });
    
    //Create CGImage with filters applied.
    CGImageRef cgImage = [context createCGImage:gloomResult fromRect:[gloomResult extent]];
    
    //Progress completed.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate imageActivityItemProvider:self preprocessingProgressDidUpdate:1.0];
    });
    
    //Notify the delegate on the main thread that the processing has finished.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate imageActivityItemProviderPreprocessingDidEnd:self];
    });
    
    UIImage *newImage = [UIImage imageWithCGImage:cgImage];
    CFRelease(cgImage);
    
    self.image = newImage;
    return newImage;

}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(NSString *)activityType suggestedSize:(CGSize)size
{
    //The filtered image is the image to display on the other side.
    return [UIImage imageWithImage:self.image scaledToFillToSize:size];
}

@end
