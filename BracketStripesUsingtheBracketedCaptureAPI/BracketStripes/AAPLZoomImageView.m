/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
         Zoomable image view
     
 */

#import "AAPLZoomImageView.h"


@implementation AAPLZoomImageView {

    BOOL _needsSizing;

    // UI
    UIScrollView *_scrollView;
    UIImageView *_imageView;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        self.backgroundColor = [UIColor whiteColor];

        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.delegate = self;
        [self addSubview:_scrollView];

        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [_scrollView addSubview:_imageView];
    }
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];

    _scrollView.frame = self.bounds;

    if (_needsSizing) {
        [self _performSizing];
    }
}


- (void)setImage:(UIImage *)image
{
    _imageView.image = image;

    if (image) {
        [_imageView sizeToFit];

        _needsSizing = YES;
        [self setNeedsLayout];
    }
}


- (void)_performSizing
{
    _scrollView.zoomScale =
    _scrollView.minimumZoomScale =
    _scrollView.maximumZoomScale =
        1.0;

    UIImage *image = _imageView.image;

    _scrollView.contentSize = image.size;

    if (image) {

        // Aspect fit
        const CGFloat aspect = image.size.width / image.size.height;

        if (aspect*self.bounds.size.height > self.bounds.size.width) {
            // Width constrains us
            _scrollView.zoomScale =
            _scrollView.minimumZoomScale =
                self.bounds.size.width / image.size.width;
        }
        else {
            // Height constrains us
            _scrollView.zoomScale =
            _scrollView.minimumZoomScale =
            self.bounds.size.height / image.size.height;
        }
    }

    [self _centerImageInScrollView];

    _needsSizing = NO;
}


- (void)_centerImageInScrollView
{
    const CGSize boundsSize = _scrollView.bounds.size;
    CGRect frameToCenter = _imageView.frame;

    // Center horizontally
    if (frameToCenter.size.width < boundsSize.width) {

        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2.0;
    }
    else {

        frameToCenter.origin.x = 0.0;
    }

    // Center vertically
    if (frameToCenter.size.height < boundsSize.height) {

        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2.0;
    }
    else {

        frameToCenter.origin.y = 0.0;
    }

    _imageView.frame = frameToCenter;
}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageView;
}


- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self _centerImageInScrollView];
}

@end
