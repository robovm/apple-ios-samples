/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The view controller responsible for showing the actual CKRecord photo.
 */

#import "APLPhotoViewController.h"

@interface APLPhotoViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic) CGFloat lastZoomScale;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintBottom;

@end


#pragma mark -

@implementation APLPhotoViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.imageView.image = self.photo;
    self.scrollView.delegate = self;
    [self updateZoom];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self updateConstraints];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}


#pragma mark - Updating

- (void)updateConstraints
{
    CGFloat imageWidth = self.imageView.image.size.width;
    CGFloat imageHeight = self.imageView.image.size.height;
    
    CGFloat viewWidth = self.view.bounds.size.width;
    CGFloat viewHeight = self.view.bounds.size.height;
    
    // center the photo if it is smaller than screen
    CGFloat hPadding = (viewWidth - self.scrollView.zoomScale * imageWidth) / 2;
    if (hPadding < 0)
    {
        hPadding = 0;
    }
    CGFloat vPadding = (viewHeight - self.scrollView.zoomScale * imageHeight) / 2;
    if (vPadding < 0)
    {
        vPadding = 0;
    }
    
    self.constraintLeft.constant = self.constraintRight.constant = hPadding;
    self.constraintTop.constant = self.constraintBottom.constant = vPadding;
    
    [self.view layoutIfNeeded];
}

- (void)updateZoom
{
    CGFloat minZoom = MIN(self.view.bounds.size.width / self.imageView.image.size.width,
                        self.view.bounds.size.height / self.imageView.image.size.height);
    if (minZoom > 1)
    {
        minZoom = 1;
    }
    
    self.scrollView.minimumZoomScale = minZoom;
    
    // this will call "scrollViewDidZoom" if zoom did not change
    if (minZoom == self.lastZoomScale)
    {
        minZoom += 0.000001;
    }
    
    self.lastZoomScale = self.scrollView.zoomScale = minZoom;
}

@end
