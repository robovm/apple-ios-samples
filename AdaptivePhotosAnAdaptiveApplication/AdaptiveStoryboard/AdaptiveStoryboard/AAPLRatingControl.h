/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A control that allows viewing and editing a rating.
 */

@import UIKit;

extern NSInteger const AAPLRatingControlMinimumRating;
extern NSInteger const AAPLRatingControlMaximumRating;

@interface AAPLRatingControl : UIControl

@property (nonatomic) NSInteger rating;

@end
