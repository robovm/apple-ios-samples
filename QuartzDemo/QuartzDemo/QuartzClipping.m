/*
     File: QuartzClipping.m
 Abstract: Demonstrates using Quartz for clipping (QuartzClippingView) and masking (QuartzMaskingView).
  Version: 3.0
 
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

#import "QuartzClipping.h"

@implementation QuartzClippingView
{
	CGImageRef _image;
}


-(CGImageRef)image
{
	if (_image == NULL)
	{
		NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"Ship.png" ofType:nil];
		UIImage *img = [UIImage imageWithContentsOfFile:imagePath];
		_image = CGImageRetain(img.CGImage);
	}
	return _image;
}


-(void)addStarToContext:(CGContextRef)context at:(CGPoint)center radius:(CGFloat)radius angle:(CGFloat)angle
{
	CGFloat x = radius * sinf(angle * M_PI / 5.0) + center.x;
	CGFloat y = radius * cosf(angle * M_PI / 5.0) + center.y;
	CGContextMoveToPoint(context, x, y);
	for(int i = 1; i < 5; ++i)
	{
		CGFloat x = radius * sinf((i * 4.0 * M_PI + angle) / 5.0) + center.x;
		CGFloat y = radius * cosf((i * 4.0 * M_PI + angle) / 5.0) + center.y;
		CGContextAddLineToPoint(context, x, y);
	}
	// And close the subpath.
	CGContextClosePath(context);
}

-(void)drawInContext:(CGContextRef)context
{
	// NOTE
	// So that the images in this demo appear right-side-up, we flip the context
	// In doing so we need to specify all of our Y positions relative to the height of the view.
	// The value we subtract from the height is the Y coordinate for the *bottom* of the image.
	CGFloat height = self.bounds.size.height;
	CGContextTranslateCTM(context, 0.0, height);
	CGContextScaleCTM(context, 1.0, -1.0);

	CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);

	// We'll draw the original image for comparision
	CGContextDrawImage(context, CGRectMake(10.0, height - 100.0, 90.0, 90.0), self.image);

	// First we'll use clipping rectangles to remove the body of the ship.
	// We use CGContextClipToRects() to clip to a set of rectangles.

	CGContextSaveGState(context);
	// For this operation we extract the 35 pixel strip on each side of the source image.
	CGRect clips[] =
	{
		CGRectMake(110.0, height - 100.0, 35.0, 90.0),
		CGRectMake(165.0, height - 100.0, 35.0, 90.0),
	};
	// While convinient, this is just the equivalent of adding each rectangle to the current path,
	// then calling CGContextClip().
	CGContextClipToRects(context, clips, sizeof(clips) / sizeof(clips[0]));
	CGContextDrawImage(context, CGRectMake(110.0, height - 100.0, 90.0, 90.0), self.image);
	CGContextRestoreGState(context);

	// You can also clip to aribitrary shapes, which can be useful for special effects.
	// In this case we are going to clip to a star.
	// We will actually clip the image twice, using the different clipping modes.
	[self addStarToContext:context at:CGPointMake(55.0, height - 150.0) radius:45.0 angle:0.0];
	CGContextSaveGState(context);

	// Clip to the current path using the non-zero winding number rule.
	CGContextClip(context);

	// To make the area we draw to a bit more obvious, we'll the image over a red rectangle.
	CGContextFillRect(context, CGRectMake(10.0, height - 190.0, 90.0, 90.0));

	// And finally draw the image
	CGContextDrawImage(context, CGRectMake(10.0, height - 190.0, 90.0, 90.0), self.image);
	CGContextRestoreGState(context);

	[self addStarToContext:context at:CGPointMake(155.0, height - 150.0) radius:45.0 angle:0.0];
	CGContextSaveGState(context);

	// Clip to the current path using the even-odd rule.
	CGContextEOClip(context);

	// To make the area we draw to a bit more obvious, we'll the image over a red rectangle.
	CGContextFillRect(context, CGRectMake(110.0, height - 190.0, 90.0, 90.0));

	// And finally draw the image
	CGContextDrawImage(context, CGRectMake(110.0, height - 190.0, 90.0, 90.0), self.image);
	CGContextRestoreGState(context);

	// Finally making the path slightly more complex by enscribing it in a rectangle changes what is clipped
	// For EO clipping mode this will invert the clip (for non-zero winding this is less predictable).
	[self addStarToContext:context at:CGPointMake(255.0, height - 150.0) radius:45.0 angle:0.0];
	CGContextAddRect(context, CGRectMake(210., height - 190., 90., 90.));
	CGContextSaveGState(context);

	// Clip to the current path using the even-odd rule.
	CGContextEOClip(context);

	// To make the area we draw to a bit more obvious, we'll the image over a red rectangle.
	CGContextFillRect(context, CGRectMake(210.0, height - 190.0, 90.0, 90.0));

	// And finally draw the image
	CGContextDrawImage(context, CGRectMake(210.0, height - 190.0, 90.0, 90.0), self.image);
	CGContextRestoreGState(context);
}


-(void)dealloc
{
	CGImageRelease(_image);
}


@end



#pragma mark - QuartzMaskingView


@implementation QuartzMaskingView
{
	CGImageRef _maskingImage;
	CGImageRef _alphaImage;
}


-(void)createImages
{
    // Load the alpha image, which is just the same Ship.png image used in the clipping demo
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"Ship.png" ofType:nil];
    UIImage *img = [UIImage imageWithContentsOfFile:imagePath];
    _alphaImage = CGImageRetain(img.CGImage);
    
    // To show the difference with an image mask, we take the above image and process it to extract
    // the alpha channel as a mask.
    // Allocate data
    NSMutableData *data = [NSMutableData dataWithLength:90 * 90 * 1];
    // Create a bitmap context
    CGContextRef context = CGBitmapContextCreate([data mutableBytes], 90, 90, 8, 90, NULL, (CGBitmapInfo)kCGImageAlphaOnly);
    // Set the blend mode to copy to avoid any alteration of the source data
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    // Draw the image to extract the alpha channel
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, 90.0, 90.0), _alphaImage);
    // Now the alpha channel has been copied into our NSData object above, so discard the context and lets make an image mask.
    CGContextRelease(context);
    // Create a data provider for our data object (NSMutableData is tollfree bridged to CFMutableDataRef, which is compatible with CFDataRef)
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFMutableDataRef)data);
    // Create our new mask image with the same size as the original image
    _maskingImage = CGImageMaskCreate(90, 90, 8, 8, 90, dataProvider, NULL, YES);
    // And release the provider.
    CGDataProviderRelease(dataProvider);
}


-(void)drawInContext:(CGContextRef)context
{
	// NOTE
	// So that the images in this demo appear right-side-up, we flip the context
	// In doing so we need to specify all of our Y positions relative to the height of the view.
	// The value we subtract from the height is the Y coordinate for the *bottom* of the image.
	CGFloat height = self.bounds.size.height;
	CGContextTranslateCTM(context, 0.0, height);
	CGContextScaleCTM(context, 1.0, -1.0);

	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);

	// Quartz also allows you to mask to an image or image mask, the primary difference being
	// how the image data is interpreted. Note that you can use any image
	// When you use a regular image, the alpha channel is interpreted as the alpha values to use,
	// that is a 0.0 alpha indicates no pass and a 1.0 alpha indicates full pass.
	CGContextSaveGState(context);
	CGContextClipToMask(context, CGRectMake(10.0, height - 100.0, 90.0, 90.0), self.alphaImage);
	// Because we're clipping, we aren't going to be particularly careful with our rect.
	CGContextFillRect(context, self.bounds);
	CGContextRestoreGState(context);

	CGContextSaveGState(context);
	// You can also use the clip rect given to scale the mask image
	CGContextClipToMask(context, CGRectMake(110.0, height - 190.0, 180.0, 180.0), self.alphaImage);
	// As above, not being careful with bounds since we are clipping.
	CGContextFillRect(context, self.bounds);
	CGContextRestoreGState(context);

	// Alternatively when you use a mask image the mask data is used much like an inverse alpha channel,
	// that is 0.0 indicates full pas and 1.0 indicates no pass.
	CGContextSaveGState(context);
	CGContextClipToMask(context, CGRectMake(10.0, height - 300.0, 90.0, 90.0), self.maskingImage);
	// Because we're clipping, we aren't going to be particularly careful with our rect.
	CGContextFillRect(context, self.bounds);
	CGContextRestoreGState(context);

	CGContextSaveGState(context);
	// You can also use the clip rect given to scale the mask image
	CGContextClipToMask(context, CGRectMake(110.0, height - 390.0, 180.0, 180.0), self.maskingImage);
	// As above, not being careful with bounds since we are clipping.
	CGContextFillRect(context, self.bounds);
	CGContextRestoreGState(context);
}


- (CGImageRef)maskingImage
{
    if (_maskingImage == NULL)
    {
        [self createImages];
    }

    return _maskingImage;
}


- (CGImageRef)alphaImage
{
    if (_alphaImage == NULL)
    {
        [self createImages];
    }

    return _alphaImage;
}


-(void)dealloc
{
	CGImageRelease(_maskingImage);
	CGImageRelease(_alphaImage);
}


@end
