/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  AAPLPhotoCollectionViewCell implementation.
  
 */

#import "AAPLPhotoCollectionViewCell.h"

@implementation AAPLPhotoCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        _imageView = [[UIImageView alloc] init];
        [[self imageView] setContentMode:UIViewContentModeScaleAspectFill];
        
        [[self contentView] addSubview:[self imageView]];
        [[self contentView] setClipsToBounds:YES];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [[self imageView] setFrame:[[self contentView] bounds]];
}

- (void)setImage:(UIImage *)image
{
    [[self imageView] setImage:image];
}

- (UIImage *)image
{
    return [[self imageView] image];
}

@end
