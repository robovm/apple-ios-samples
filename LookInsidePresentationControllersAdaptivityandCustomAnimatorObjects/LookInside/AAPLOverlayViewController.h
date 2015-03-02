/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  AAPLOverlayViewController header.
  
 */

@import UIKit;
#import "AAPLPhotoCollectionViewCell.h"

@interface AAPLOverlayVibrantLabel : UILabel
@end

@interface AAPLOverlayViewController : UIViewController
{
    AAPLPhotoCollectionViewCell* _photoView;
}

@property (nonatomic) UIVisualEffectView *backgroundView;
@property (nonatomic) UIVisualEffectView *foregroundContentView;

@property (nonatomic) UIScrollView *foregroundContentScrollView;

@property (nonatomic) UIBlurEffect *blurEffect;
@property (nonatomic) UIImageView *imageView;

@property (nonatomic) AAPLOverlayVibrantLabel *hueLabel;
@property (nonatomic) UISlider *hueSlider;

@property (nonatomic) AAPLOverlayVibrantLabel *saturationLabel;
@property (nonatomic) UISlider *saturationSlider;

@property (nonatomic) AAPLOverlayVibrantLabel *brightnessLabel;
@property (nonatomic) UISlider *brightnessSlider;

@property (nonatomic) UIButton *saveButton;
@property (nonatomic) AAPLPhotoCollectionViewCell *photoView;

@end
