/*
     File: AssetViewController.m 
 Abstract: n/a 
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
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
*/

#import "ApplicationConstants.h"
#import "AssetViewController.h"
#import "FavoriteAssets.h"

#import <ImageIO/ImageIO.h>

#define ZOOM_VIEW_TAG 100
#define ZOOM_STEP 1.5

@interface AssetViewController()
- (void)updateFavoriteButtonState;
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center;
- (UIImage *)fullSizeImageForAssetRepresentation:(ALAssetRepresentation *)assetRepresentation;
@end

@implementation AssetViewController

@synthesize metadataViewController;
@synthesize asset;
@synthesize favoriteAssets;

- (void)viewDidLoad {
    
    [imageScrollView setBackgroundColor:[UIColor blackColor]];
    [imageScrollView setDelegate:self];
    [imageScrollView setBouncesZoom:YES];
    imageScrollView.showsVerticalScrollIndicator = NO;
    imageScrollView.showsHorizontalScrollIndicator = NO;
    
    ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
    
    UIImage *fullSizeImage = [self fullSizeImageForAssetRepresentation:assetRepresentation];
    
    // add touch-sensitive image view to the scroll view
    TapDetectingImageView *imageView = [[TapDetectingImageView alloc] initWithImage:fullSizeImage];
    [imageView setDelegate:self];
    [imageView setTag:ZOOM_VIEW_TAG];
    [imageScrollView setContentSize:[imageView frame].size];
    [imageScrollView addSubview:imageView];
    [imageView release];
    
    // calculate minimum scale to perfectly fit image width, and begin at that scale
    float minimumScale = [imageScrollView frame].size.width  / [imageView frame].size.width;
    [imageScrollView setMinimumZoomScale:minimumScale];
    
    [self updateFavoriteButtonState];
    
    self.title = @"Full Resolution Image";
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return [(UIScrollView *)self.view viewWithTag:ZOOM_VIEW_TAG];
}


#pragma mark -
#pragma mark TapDetectingImageViewDelegate methods

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotSingleTapAtPoint:(CGPoint)tapPoint {
    // single tap does nothing for now
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint {
    // double tap zooms in
    float newScale = [imageScrollView zoomScale] * ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
    [imageScrollView zoomToRect:zoomRect animated:YES];
}

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint {
    // two-finger tap zooms out
    float newScale = [imageScrollView zoomScale] / ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
    [imageScrollView zoomToRect:zoomRect animated:YES];
}


#pragma mark -
#pragma mark Utility methods

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // the zoom rect is in the content view's coordinates. 
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = [imageScrollView frame].size.height / scale;
    zoomRect.size.width  = [imageScrollView frame].size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

- (UIImage *)fullSizeImageForAssetRepresentation:(ALAssetRepresentation *)assetRepresentation {
    
    UIImage *result = nil;
    NSData *data = nil;
    
    uint8_t *buffer = (uint8_t *)malloc(sizeof(uint8_t)*[assetRepresentation size]);
    if (buffer != NULL) {
        NSError *error = nil;
        NSUInteger bytesRead = [assetRepresentation getBytes:buffer fromOffset:0 length:[assetRepresentation size] error:&error];        
        data = [NSData dataWithBytes:buffer length:bytesRead];
        
        free(buffer);
    }
    
    if ([data length]) {
        CGImageSourceRef sourceRef = CGImageSourceCreateWithData((CFDataRef)data, nil);
        
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        
        [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceCreateThumbnailFromImageIfAbsent];
        
        CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0, (CFDictionaryRef)options);
        
        if (imageRef) {
            result = [UIImage imageWithCGImage:imageRef scale:[assetRepresentation scale] orientation:[assetRepresentation orientation]];
            CGImageRelease(imageRef);
        }
        
        if (sourceRef) CFRelease(sourceRef);
    }
    
    return result;
}

#pragma mark -
#pragma mark Favorite Status

- (void)toggleFavoriteStatus:(id)sender {
    NSURL *assetURL = [[self.asset defaultRepresentation] url];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kToggleFavoriteStatusNotification object:nil userInfo:[NSDictionary dictionaryWithObject:assetURL forKey:kToggleFavoriteStatusNotificationAssetURLKey]];
    
    [self updateFavoriteButtonState];
}

- (void)updateFavoriteButtonState {
    static UIImage *notFavorite = nil;
    static UIImage *favorite    = nil;
    if (!notFavorite) {
        notFavorite  = [UIImage imageNamed:@"grey-star.png"];
    }
    if (!favorite) {
        favorite = [UIImage imageNamed:@"gold-star.png"];
    }

    
    if ([self.favoriteAssets isFavorite:asset]) {
        [setAsFavoriteButton setImage:favorite forState:UIControlStateNormal];
    } else {
        [setAsFavoriteButton setImage:notFavorite forState:UIControlStateNormal];
    }
    [setAsFavoriteButton setNeedsDisplay];
}


#pragma mark -
#pragma mark Metadata View Controller

- (void)displayAssetMetadata:(id)sender {
    
    metadataViewController = [[MetadataViewController alloc] initWithNibName:@"MetadataViewController" bundle:nil];
    metadataViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    metadataViewController.delegate = self;
    metadataViewController.asset = asset;
    
    [self presentViewController:metadataViewController animated:YES completion:nil];
}

- (void)dismissMetadataViewController {
    
    metadataViewController.delegate = nil;
    [[self navigationController] dismissViewControllerAnimated:YES completion:nil];
    [metadataViewController release];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    self.asset = nil;
    self.favoriteAssets = nil;
    
    [super dealloc];
}

@end
