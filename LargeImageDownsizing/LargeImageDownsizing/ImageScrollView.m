/*
     File: ImageScrollView.m 
 Abstract: This scroll view allows the user to inspect the resulting image's levels of detail. 
  Version: 1.1 
  
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

#import "ImageScrollView.h"
#import "TiledImageView.h"
#import <QuartzCore/QuartzCore.h>

@implementation ImageScrollView;

@synthesize image, backTiledView;

- (void)dealloc {
    [frontTiledView release];
    self.backTiledView = nil;
	[backgroundImageView release];
    [image release];
    //--
    [super dealloc];
}
-(id)initWithFrame:(CGRect)frame image:(UIImage*)img {
    if((self = [super initWithFrame:frame])) {		
		// Set up the UIScrollView
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
		self.maximumZoomScale = 5.0f;
		self.minimumZoomScale = 0.25f;
		self.backgroundColor = [UIColor colorWithRed:0.4f green:0.2f blue:0.2f alpha:1.0f];
		// determine the size of the image
        self.image = img;
        CGRect imageRect = CGRectMake(0.0f,0.0f,CGImageGetWidth(image.CGImage),CGImageGetHeight(image.CGImage));
        imageScale = self.frame.size.width/imageRect.size.width;
        minimumScale = imageScale * 0.75f;
        NSLog(@"imageScale: %f",imageScale);
        imageRect.size = CGSizeMake(imageRect.size.width*imageScale, imageRect.size.height*imageScale);
        // Create a low res image representation of the image to display before the TiledImageView
        // renders its content.
        UIGraphicsBeginImageContext(imageRect.size);		
        CGContextRef context = UIGraphicsGetCurrentContext();		
        CGContextSaveGState(context);
        CGContextDrawImage(context, imageRect, image.CGImage);
        CGContextRestoreGState(context);		
        UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();		
        UIGraphicsEndImageContext();		
        backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
        backgroundImageView.frame = imageRect;
        backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:backgroundImageView];
        [self sendSubviewToBack:backgroundImageView];
        // Create the TiledImageView based on the size of the image and scale it to fit the view.
        frontTiledView = [[TiledImageView alloc] initWithFrame:imageRect image:image scale:imageScale];
        [self addSubview:frontTiledView];
        [frontTiledView release];
    }
    return self;
}

#pragma mark -
#pragma mark Override layoutSubviews to center content

// We use layoutSubviews to center the image in the view
- (void)layoutSubviews {
    [super layoutSubviews];
    // center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = frontTiledView.frame;
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    frontTiledView.frame = frameToCenter;
	backgroundImageView.frame = frameToCenter;
	// to handle the interaction between CATiledLayer and high resolution screens, we need to manually set the
	// tiling view's contentScaleFactor to 1.0. (If we omitted this, it would be 2.0 on high resolution screens,
	// which would cause the CATiledLayer to ask us for tiles of the wrong scales.)
	frontTiledView.contentScaleFactor = 1.0;
}
#pragma mark -
#pragma mark UIScrollView delegate methods
// A UIScrollView delegate callback, called when the user starts zooming. 
// We return our current TiledImageView.
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return frontTiledView;
}
// A UIScrollView delegate callback, called when the user stops zooming.  When the user stops zooming
// we create a new TiledImageView based on the new zoom level and draw it on top of the old TiledImageView.
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
	// set the new scale factor for the TiledImageView
	imageScale *=scale;
    if( imageScale < minimumScale ) imageScale = minimumScale;
    CGRect imageRect = CGRectMake(0.0f,0.0f,CGImageGetWidth(image.CGImage) * imageScale,CGImageGetHeight(image.CGImage) * imageScale);
    // Create a new TiledImageView based on new frame and scaling.
	frontTiledView = [[TiledImageView alloc] initWithFrame:imageRect image:image scale:imageScale];	
	[self addSubview:frontTiledView];
    [frontTiledView release];
}

// A UIScrollView delegate callback, called when the user begins zooming.  When the user begins zooming
// we remove the old TiledImageView and set the current TiledImageView to be the old view so we can create a
// a new TiledImageView when the zooming ends.
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
	// Remove back tiled view.
	[backTiledView removeFromSuperview];
	// Set the current TiledImageView to be the old view.
	self.backTiledView = frontTiledView;
}

@end
