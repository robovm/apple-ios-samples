/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller that uses a photo as a background image.
  
 */

#import "AAPLPhotoBackgroundViewController.h"

@interface AAPLPhotoBackgroundViewController ()

@property (nonatomic, strong) UIImageView *backgroundView;

@end

@implementation AAPLPhotoBackgroundViewController

- (void)loadView {
    UIView *containerView = [[UIView alloc] init];
    containerView.clipsToBounds = YES;
    
    self.backgroundView = [[UIImageView alloc] initWithImage:self.backgroundImage];
    [containerView addSubview:self.backgroundView];
    
    self.view = containerView;
}

- (void)viewWillLayoutSubviews {
    CGRect bounds = self.view.bounds;
    CGSize imageSize = self.backgroundView.image.size;
    CGFloat imageAspectRatio = imageSize.width / imageSize.height;
    CGFloat viewAspectRatio = CGRectGetWidth(bounds) / CGRectGetHeight(bounds);
    if (viewAspectRatio > imageAspectRatio) {
        // Let the background run off the top and bottom of the screen, so it fills the width
        CGSize scaledSize = CGSizeMake(CGRectGetWidth(bounds), CGRectGetWidth(bounds) / imageAspectRatio);
        self.backgroundView.frame = CGRectMake(0.0, (CGRectGetHeight(bounds) - scaledSize.height) / 2.0, scaledSize.width, scaledSize.height);
    } else {
        // Let the background run off the left and right of the screen, so it fills the height
        CGSize scaledSize = CGSizeMake(imageAspectRatio * CGRectGetHeight(bounds), CGRectGetHeight(bounds));
        self.backgroundView.frame = CGRectMake((CGRectGetWidth(bounds) - scaledSize.width) / 2.0, 0.0, scaledSize.width, scaledSize.height);
    }
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    if (_backgroundImage != backgroundImage) {
        _backgroundImage = backgroundImage;
        self.backgroundView.image = backgroundImage;
    }
}

@end
