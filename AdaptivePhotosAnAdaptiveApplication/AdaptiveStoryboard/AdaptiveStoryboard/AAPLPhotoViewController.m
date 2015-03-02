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

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet AAPLOverlayView *overlayView;
@property (strong, nonatomic) IBOutlet AAPLRatingControl *ratingControl;

@end

@implementation AAPLPhotoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updatePhoto];
}

// Action for a change in value from the AAPLRatingControl (the user choose a different rating for the photo).
- (IBAction)changeRating:(AAPLRatingControl *)sender
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
