/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
         Photo view controller
     
 */

#import "AAPLImageViewController.h"
#import "AAPLZoomImageView.h"


@implementation AAPLImageViewController {

    UIImage *_image;
    AAPLZoomImageView *_imageView;
}


- (instancetype)initWithImage:(UIImage *)image
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {

        _image = image;
    }
    return self;
}


- (void)loadView
{
    [super loadView];

    _imageView = [[AAPLZoomImageView alloc] init];
    _imageView.image = _image;
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view = _imageView;

    UIColor *iosBlueColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    self.navigationController.navigationBar.tintColor = iosBlueColor;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_done:)];
}


- (void)_done:(id)sender
{
    [_delegate imageViewControllerDidFinish:self];
}

@end
