/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller that shows a photo and its metadata.
 */

#import "AAPLPhotoViewController.h"
#import "AAPLPhoto.h"
#import "AAPLOverlayView.h"
#import "AAPLRatingControl.h"

@interface AAPLPhotoViewController ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) AAPLOverlayView *overlayView;
@property (strong, nonatomic) AAPLRatingControl *ratingControl;

@end

@implementation AAPLPhotoViewController

- (void)loadView
{
    self.view = [[UIView alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView = imageView;
    [self.view addSubview:imageView];
    
    AAPLRatingControl *ratingControl = [[AAPLRatingControl alloc] init];
    ratingControl.translatesAutoresizingMaskIntoConstraints = NO;
    [ratingControl addTarget:self action:@selector(changeRating:) forControlEvents:UIControlEventValueChanged];
    self.ratingControl = ratingControl;
    [self.view addSubview:ratingControl];
    
    AAPLOverlayView *overlayView = [[AAPLOverlayView alloc] init];
    overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    self.overlayView = overlayView;
    [self.view addSubview:overlayView];
    
    [self updatePhoto];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(imageView, ratingControl, overlayView);
    NSMutableArray *constraints = [NSMutableArray array];
    
    NSArray *imageViewHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[imageView]|" options:0 metrics:nil views:views];
    [constraints addObjectsFromArray:imageViewHConstraints];
    
    NSArray *imageViewVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|" options:0 metrics:nil views:views];
    [constraints addObjectsFromArray:imageViewVConstraints];
    
    NSArray *ratingControlConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[ratingControl]-20-|" options:0 metrics:nil views:views];
    [constraints addObjectsFromArray:ratingControlConstraints];
    
    NSArray *overlayViewConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[overlayView]-20-|" options:0 metrics:nil views:views];
    [constraints addObjectsFromArray:overlayViewConstraints];
    
    NSArray *controlsConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[overlayView]-[ratingControl]-20-|" options:0 metrics:nil views:views];
    [constraints addObjectsFromArray:controlsConstraints];
    
    [NSLayoutConstraint activateConstraints:constraints];
    
    constraints = [NSMutableArray array];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(>=20)-[ratingControl]" options:0 metrics:nil views:views]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(>=20)-[overlayView]" options:0 metrics:nil views:views]];
    // We want these constraints to be able to be broken if our interface is resized to be small enough that these margins don't fit.
    for (NSLayoutConstraint *constraint in constraints) {
        constraint.priority = UILayoutPriorityRequired - 1;
    }
    [NSLayoutConstraint activateConstraints:constraints];
}

// Action for a change in value from the AAPLRatingControl (the user choose a different rating for the photo).
- (void)changeRating:(AAPLRatingControl *)sender
{
    self.photo.rating = sender.rating;
}

// Updates the image view and meta data views with the data from the current photo.
- (void)updatePhoto
{
    self.imageView.image = self.photo.image;
    self.overlayView.text = self.photo.comment;
    self.ratingControl.rating = self.photo.rating;
}

// Custom implementation of the setter for the photo property. Updates the imageView and meta data views.
- (void)setPhoto:(AAPLPhoto *)photo
{
    if (_photo != photo) {
        _photo = photo;
        [self updatePhoto];
    }
}

// This method is originally declared in the AAPLPhotoContents category on UIViewController.
- (AAPLPhoto *)aapl_containedPhoto
{
    return self.photo;
}

@end
