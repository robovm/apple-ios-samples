/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view that shows a textual overlay whose margins change with its vertical size class.
 */

#import "AAPLOverlayView.h"

@interface AAPLOverlayView ()

@property (strong, nonatomic) UILabel *label;

@end

@implementation AAPLOverlayView

// This initializer will be called if the control is created programatically.
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self aapl_overlayViewCommonInit];
    }
    return self;
}


// This initializer will be called if the control is loaded from a storyboard.
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self aapl_overlayViewCommonInit];
    }
    return self;
}

// Initialization code common to instances created programmatically as well as instances unarchived from a storyboard.
- (void)aapl_overlayViewCommonInit
{
    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
    backgroundView.contentView.backgroundColor = [UIColor colorWithWhite:0.7 alpha:0.3];
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:backgroundView];
    NSDictionary *views = NSDictionaryOfVariableBindings(backgroundView);
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[backgroundView]|" options:0 metrics:nil views:views]];
    [NSLayoutConstraint activateConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[backgroundView]|" options:0 metrics:nil views:views]];
    
    _label = [[UILabel alloc] init];
    _label.translatesAutoresizingMaskIntoConstraints = NO;
    _label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [self addSubview:_label];
    NSArray *constraints = @[
        [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
        [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0],
    ];
    [NSLayoutConstraint activateConstraints:constraints];
    
    // Listening for changes to the user's preferred text size and updating the relevant views is necessary to fully support Dynamic Type in your view or control.  The user may adjust their preferred text style while your application is suspended.  Upon returning to the foreground, your application will receive a UIContentSizeCategoryDidChangeNotification should a change to the user's preferred text size have occurred.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentSizeCategoryDidChange:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    // Retrieve the new font corresponding to the UIFontTextStyleBody text
    // style and invalidate our intrinsic content size.
    self.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [self.label intrinsicContentSize];
    
    // Add a horizontal margin whose size depends on our horizontal size class.
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        size.width += 8.0;
    } else {
        size.width += 40.0;
    }
    
    // Add a vertical margin whose size depends on our vertical size class.
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        size.height += 8.0;
    } else {
        size.height += 40.0;
    }
    
    return size;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if ((self.traitCollection.verticalSizeClass != previousTraitCollection.verticalSizeClass)
        || (self.traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass)) {
        // If our size class has changed, then our intrinsic content size will need to be updated.
        [self invalidateIntrinsicContentSize];
    }
}

// Custom implementations of the getter and setter for the comment propety. Changes to this property are forwarded to the _label and the intrinsic content size is invalidated.
- (NSString *)text
{
    return self.label.text;
}

- (void)setText:(NSString *)text
{
    self.label.text = text;
    [self invalidateIntrinsicContentSize];
}

@end
