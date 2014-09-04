/*
    File:       QImageScrollView.m

    Contains:   A simplified image view scroller.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "QImageScrollView.h"

#import "Logging.h"

#include <sys/sysctl.h>

@interface QImageScrollView () <UIScrollViewDelegate>

@property (nonatomic, retain, readwrite) UIImageView *  imageView;

@end

@implementation QImageScrollView

static BOOL LimitImageSize(void)
    // Returns YES if the hardware we're running on is not capable of handling 
    // large images.  For more information about this, see the comments where 
    // _limitImageSize is used, later in this file.
{
    BOOL    result;
    int     err;
    char    value[32];
    size_t  valueLen;

    result = NO;
    
    // Note that sysctlbyname will fail if value is too small.  That's fine by 
    // us.  The model numbers we're specifically looking will all fit.  Anything 
    // with a longer name should be more capable, and hence not need a limited size.

    valueLen = sizeof(value);
    err = sysctlbyname("hw.machine", value, &valueLen, NULL, 0);
    if (err == 0) {
        result = 
           (strcmp(value, "iPhone1,1") == 0)        // iPhone
        || (strcmp(value, "iPhone1,2") == 0)        // iPhone 3G
        || (strcmp(value, "iPod1,1"  ) == 0)        // iPod touch
        || (strcmp(value, "iPod2,1"  ) == 0)        // iPod touch (second generation)
        || (strcmp(value, "iPod2,2"  ) == 0)        // iPod touch (second generation)
        ;
    }
    return result;
}

- (void)initCommon
    // Common initialisation called by both -initWithFrame: and -initWithCoder:.
{
    // If the delegate isn't already wired up courtesy of the NIB, wire it up 
    // ourselves.
    
    if (self.delegate == nil) {
        self.delegate = self;
    }

    // Determine if we need to limit the image size.  For more information about this, 
    // see  the comments where _limitImageSize is used, later in this file.
    
    self->_limitImageSize = LimitImageSize();
    
    [[QLog log] logWithFormat:@"image scroll limit size %s", self->_limitImageSize ? "limited" : "unlimited"];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self initCommon];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self != nil) {
        [self initCommon];
    }
    return self;
}

- (void)dealloc
{
    [self->_image release];
    [self->_imageView release];
    [super dealloc];
}

#pragma mark * Overrides

- (void)layoutSubviews 
    // We override -layoutSubviews so that, if the image is smaller than the scroll view, 
    // it ends up centred within the scroll view (rather than stuck at the top left).
{
    CGRect      imageViewFrame;
    CGSize      boundsSize;
    
    [super layoutSubviews];
    
    if (self.imageView != nil) {
        boundsSize     = self.bounds.size;

        // get the frame
        
        imageViewFrame = self.imageView.frame;
        
        // if it's smaller than the scroll view, centre it horizontally

        if (imageViewFrame.size.width < boundsSize.width) {
            imageViewFrame.origin.x = (boundsSize.width - imageViewFrame.size.width) / 2.0f;
        } else {
            imageViewFrame.origin.x = 0.0f;
        }
        
        // if it's smaller than the scroll view, centre it vertically

        if (imageViewFrame.size.height < boundsSize.height) {
            imageViewFrame.origin.y = (boundsSize.height - imageViewFrame.size.height) / 2.0f;
        } else {
            imageViewFrame.origin.y = 0.0f;
        }
        
        // set it back
        
        self.imageView.frame = imageViewFrame;
    }
}

#pragma mark * Scroll view delegate callbacks

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    assert(scrollView == self);
    #pragma unused(scrollView)
    return self.imageView;
}

#pragma mark * Properties

@synthesize image     = _image;
@synthesize imageView = _imageView;

- (void)setImage:(UIImage *)newValue
{
    if (newValue != self->_image) {

        // If we had a previous image view, clean it up.
        
        if (self.imageView != nil) {
            [self.imageView removeFromSuperview];
            self.imageView = nil;
        }
        
        // Reset our zooming back to the default before doing further calculations.
        
        self.zoomScale        = 1.0;
        self.minimumZoomScale = 1.0;
        assert(self.maximumZoomScale == 1.0f);
        
        // Complete the setter.
        
        [self->_image release];
        self->_image = [newValue retain];
        
        // If there is a new image, make an image view for it.
        
        if (newValue != nil) {
            CGSize      boundsSize;
            CGSize      imageSize;
            CGFloat     widthScale;
            CGFloat     heightScale;

            // If we're on old school hardware and the image is bigger than 1000 pixels in either 
            // dimension, resize it.  This has a number of benefits:
            //
            // o it limits the amount of memory we consume
            // o it gives us acceptable drag-to-scroll performance
            // o it avoids a bug in iOS 3.x that causes images of certain widths to render as garbage
            //
            // Note that resizing the image down locks up the UI for a second or two.  This isn't 
            // so bad because there's a "Loading…" on screen and the lock up isn't too 
            // long.  In a real application, I'd probably do this via an NSOperation.
            // 
            // Actually, in a real application I'd probably use some sort of tiling mechanism to 
            // solve this problem properly.  However, this is just sample code remember, and 
            // networking sample code at that.  So this is as good as it's going to get here.
            
            if (self->_limitImageSize) {
                CGRect      smallerImageFrame;

                smallerImageFrame = CGRectZero;
                smallerImageFrame.size = newValue.size;
                
                if ( (smallerImageFrame.size.width > 1000.0f) || (smallerImageFrame.size.height > 1000.0f) ) {
                    if (smallerImageFrame.size.height > smallerImageFrame.size.width) {
                        // tall image
                        smallerImageFrame.size.width  = smallerImageFrame.size.width / smallerImageFrame.size.height * 1000.0f;
                        smallerImageFrame.size.height = 1000.0f;
                    } else {
                        // wide image
                        smallerImageFrame.size.height = smallerImageFrame.size.height / smallerImageFrame.size.width * 1000.0f;
                        smallerImageFrame.size.width  = 1000.0f;
                    }
                    
                    UIGraphicsBeginImageContext(smallerImageFrame.size);
                    [newValue drawInRect:smallerImageFrame];
                    newValue = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }
            }
            
            boundsSize = self.bounds.size;
            imageSize  = [newValue size];
            
            // Set up the image view.
            
            self.imageView = [[[UIImageView alloc] initWithImage:newValue] autorelease];
            [self addSubview:self.imageView];
            
            // Calculate the width and height zoom scales, and then use the 
            // lesser one at minimum zoom scale.
            
            widthScale  = boundsSize.width  / imageSize.width;
            heightScale = boundsSize.height / imageSize.height;
            
            self.contentSize = imageSize;
            if (widthScale < heightScale) {
                self.minimumZoomScale = widthScale;
            } else {
                self.minimumZoomScale = heightScale;
            }
            assert(self.maximumZoomScale == 1.0f);

            // And set the current zoom scale to be the minimum (that is, we can see 
            // the entire image).

            self.zoomScale = self.minimumZoomScale;
        }
    }
}

@end
