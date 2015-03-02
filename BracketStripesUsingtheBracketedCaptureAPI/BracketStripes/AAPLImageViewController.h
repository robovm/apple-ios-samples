/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
         Photo view controller
     
 */


@class AAPLImageViewController;

@protocol AAPLImageViewDelegate

- (void)imageViewControllerDidFinish:(AAPLImageViewController *)controller;

@end


@interface AAPLImageViewController : UIViewController

@property (nonatomic, weak) id<AAPLImageViewDelegate> delegate;

// Designated initializer
- (instancetype)initWithImage:(UIImage *)image;

@end
