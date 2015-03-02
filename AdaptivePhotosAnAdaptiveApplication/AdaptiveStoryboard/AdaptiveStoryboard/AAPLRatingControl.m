/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A control that allows viewing and editing a rating.
 */

#import "AAPLRatingControl.h"

NSInteger const AAPLRatingControlMinimumRating = 0;
NSInteger const AAPLRatingControlMaximumRating = 4;

@interface AAPLRatingControl ()

@property (strong, nonatomic) UIVisualEffectView *backgroundView;
@property (copy, nonatomic) NSArray *imageViews;

@end

@implementation AAPLRatingControl

// NOTE: Unlike AAPLOverlayView, this control does not implement -intrinsicContentSize. Instead, this control configures its auto layout constraints such that the size of the star images that compose it can be used by the layout engine to derive the desired content size of this control. Since UIImageView will automatically load the correct UIImage asset for the current trait collection, we receive automatic adaptivity support for free just by including the images for both the compact and regular size classes.

// This initializer will be called if the control is created programatically.
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self aapl_ratingControlCommonInit];
    }
    return self;
}

// This initializer will be called if the control is loaded from a storyboard.
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self aapl_ratingControlCommonInit];
    }
    return self;
}

// Initialization code common to instances created programmatically as well as instances unarchived from a storyboard.
- (void)aapl_ratingControlCommonInit
{
    _rating = AAPLRatingControlMinimumRating;
    
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    _backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
    _backgroundView.contentView.backgroundColor = [UIColor colorWithWhite:0.7 alpha:0.3];
    [self addSubview:_backgroundView];
    
    // Create image views for each of the sections that make up the control.
    NSMutableArray *imageViews = [NSMutableArray array];
    for (NSInteger rating = AAPLRatingControlMinimumRating; rating <= AAPLRatingControlMaximumRating; rating++) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.userInteractionEnabled = YES;
        
        // Set up our image view's images.
        [imageView setImage:[UIImage imageNamed:@"ratingInactive"]];
        [imageView setHighlightedImage:[UIImage imageNamed:@"ratingActive"]];
        
        [imageView setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"%d stars", @"%d stars"), rating + 1]];
        [self addSubview:imageView];
        [imageViews addObject:imageView];
    }
    _imageViews = [imageViews copy];
    [self updateImageViews];
    
    // Setup constraints.
    _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *views = @{@"backgroundView" : _backgroundView};
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[backgroundView]|" options:0 metrics:nil views:views]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundView]|" options:0 metrics:nil views:views]];
    
    UIImageView *lastImageView = nil;
    for (UIImageView *imageView in _imageViews) {
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSDictionary *currentImageViews = (lastImageView ? NSDictionaryOfVariableBindings(imageView, lastImageView) : NSDictionaryOfVariableBindings(imageView));
        NSMutableArray *constraints = [NSMutableArray array];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[imageView]-4-|" options:0 metrics:nil views:currentImageViews]];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
        if (lastImageView) {
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"[lastImageView][imageView(==lastImageView)]" options:0 metrics:nil views:currentImageViews]];
        } else {
            [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-4-[imageView]" options:0 metrics:nil views:currentImageViews]];
        }
        
        [NSLayoutConstraint activateConstraints:constraints];
        lastImageView = imageView;
    }
    NSDictionary *currentImageViews = NSDictionaryOfVariableBindings(lastImageView);
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[lastImageView]-4-|" options:0 metrics:nil views:currentImageViews]];
}

- (void)updateImageViews
{
    [self.imageViews enumerateObjectsUsingBlock:^(UIImageView *imageView, NSUInteger imageViewIndex, BOOL *stop) {
        imageView.highlighted = (imageViewIndex + AAPLRatingControlMinimumRating <= self.rating);
    }];
}

// Custom implementation of the setter for the rating property. Updates the image views to reflect the new value.
- (void)setRating:(NSInteger)value
{
    if (_rating != value) {
        _rating = value;
        [self updateImageViews];
    }
}

#pragma mark - Touches

- (void)updateRatingWithTouches:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint position = [touch locationInView:self];
    UIView *touchedView = [self hitTest:position withEvent:event];
    
    if ([self.imageViews containsObject:touchedView]) {
        self.rating = AAPLRatingControlMinimumRating + [self.imageViews indexOfObject:touchedView];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

// If you override one of the touch event callbacks, you should override all of them.
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self updateRatingWithTouches:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self updateRatingWithTouches:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // There's no need to handle -touchesEnded:withEvent: for this control.
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // There's no need to handle -touchesCancelled:withEvent: for this control.
}

#pragma mark - Accessibility

// This control is not an accessibility element but the individual images that compose it are.
- (BOOL)isAccessibilityElement
{
    return NO;
}

@end
