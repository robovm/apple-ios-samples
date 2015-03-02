/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The profile card view.
  
 */

#import "AAPLCardView.h"
#import "AAPLStyleUtilities.h"

static const CGFloat AAPLCardPhotoWidth = 80.0;
static const CGFloat AAPLCardBorderWidth = 5.0;
static const CGFloat AAPLCardHorizontalPadding = 20.0;
static const CGFloat AAPLCardVerticalPadding = 20.0;
static const CGFloat AAPLCardInterItemHorizontalSpacing = 30.0;
static const CGFloat AAPLCardInterItemVerticalSpacing = 10.0;
static const CGFloat AAPLCardTitleValueSpacing = 0.0;

@interface AAPLCardView ()

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIImageView *photo;
@property (nonatomic) UILabel *ageTitleLabel;
@property (nonatomic) UILabel *ageValueLabel;
@property (nonatomic) UILabel *hobbiesTitleLabel;
@property (nonatomic) UILabel *hobbiesValueLabel;
@property (nonatomic) UILabel *elevatorPitchTitleLabel;
@property (nonatomic) UILabel *elevatorPitchValueLabel;
@property (nonatomic) NSLayoutConstraint *photoAspectRatioConstraint;

@end

@implementation AAPLCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [AAPLStyleUtilities cardBorderColor];
        
        self.backgroundView = [[UIView alloc] init];
        self.backgroundView.backgroundColor = [AAPLStyleUtilities cardBackgroundColor];
        self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.backgroundView];
        
        [self addProfileViews];
        [self addAllConstraints];
    }
    return self;
}

- (void)addProfileViews {
    self.photo = [[UIImageView alloc] init];
    self.photo.isAccessibilityElement = YES;
    self.photo.accessibilityLabel = NSLocalizedString(@"Profile photo", @"Accessibility label for profile photo");
    self.photo.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.photo];
    
    self.ageTitleLabel = [AAPLStyleUtilities standardLabel];
    self.ageTitleLabel.text = NSLocalizedString(@"Age", @"Age of the user");
    [self addSubview:self.ageTitleLabel];
    
    self.ageValueLabel = [AAPLStyleUtilities detailLabel];
    [self addSubview:self.ageValueLabel];
    
    self.hobbiesTitleLabel = [AAPLStyleUtilities standardLabel];
    self.hobbiesTitleLabel.text = NSLocalizedString(@"Hobbies", @"The user's hobbies");
    [self addSubview:self.hobbiesTitleLabel];
    
    self.hobbiesValueLabel = [AAPLStyleUtilities detailLabel];
    [self addSubview:self.hobbiesValueLabel];
    
    self.elevatorPitchTitleLabel = [AAPLStyleUtilities standardLabel];
    self.elevatorPitchTitleLabel.text = NSLocalizedString(@"Elevator Pitch", @"The user's elevator pitch for finding a partner");
    [self addSubview:self.elevatorPitchTitleLabel];
    
    self.elevatorPitchValueLabel = [AAPLStyleUtilities detailLabel];
    [self addSubview:self.elevatorPitchValueLabel];
    
    self.accessibilityElements = @[self.photo, self.ageTitleLabel, self.ageValueLabel, self.hobbiesTitleLabel, self.hobbiesValueLabel, self.elevatorPitchTitleLabel, self.elevatorPitchValueLabel];
}

- (void)addAllConstraints {
    NSMutableArray *constraints = [NSMutableArray array];
    
    // Fill the card with the background view (leaving a border around it)
    [constraints addObjectsFromArray:
     @[
       [NSLayoutConstraint constraintWithItem:self.backgroundView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:AAPLCardBorderWidth],
       [NSLayoutConstraint constraintWithItem:self.backgroundView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:AAPLCardBorderWidth],
       [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.backgroundView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:AAPLCardBorderWidth],
       [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.backgroundView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:AAPLCardBorderWidth]
       ]];
    
    // Position the photo
    // The constant for the aspect ratio constraint will be updated once a photo is set
    self.photoAspectRatioConstraint = [NSLayoutConstraint constraintWithItem:self.photo attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:0.0];
    [constraints addObjectsFromArray:
     @[
       [NSLayoutConstraint constraintWithItem:self.photo attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:AAPLCardHorizontalPadding],
       [NSLayoutConstraint constraintWithItem:self.photo attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:AAPLCardVerticalPadding],
       [NSLayoutConstraint constraintWithItem:self.photo attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:AAPLCardPhotoWidth],
       [NSLayoutConstraint constraintWithItem:self.photo attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-AAPLCardVerticalPadding],
       self.photoAspectRatioConstraint
       ]];
    
    // Position the age to the right of the photo, with some spacing
    [constraints addObjectsFromArray:
     @[
       [NSLayoutConstraint constraintWithItem:self.ageTitleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.photo attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:AAPLCardInterItemHorizontalSpacing],
       [NSLayoutConstraint constraintWithItem:self.ageTitleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.photo attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:self.ageValueLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.ageTitleLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:AAPLCardTitleValueSpacing],
       [NSLayoutConstraint constraintWithItem:self.ageValueLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.ageTitleLabel attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]
       ]];
    
    // Position the hobbies to the right of the age
    [constraints addObjectsFromArray:
     @[
       [NSLayoutConstraint constraintWithItem:self.hobbiesTitleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.ageTitleLabel attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:AAPLCardInterItemHorizontalSpacing],
       [NSLayoutConstraint constraintWithItem:self.hobbiesTitleLabel attribute:NSLayoutAttributeFirstBaseline relatedBy:NSLayoutRelationEqual toItem:self.ageTitleLabel attribute:NSLayoutAttributeFirstBaseline multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:self.hobbiesValueLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.ageValueLabel attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:AAPLCardInterItemHorizontalSpacing],
       [NSLayoutConstraint constraintWithItem:self.hobbiesValueLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.hobbiesTitleLabel attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:self.hobbiesValueLabel attribute:NSLayoutAttributeFirstBaseline relatedBy:NSLayoutRelationEqual toItem:self.ageValueLabel attribute:NSLayoutAttributeFirstBaseline multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:self.hobbiesTitleLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-AAPLCardHorizontalPadding],
       [NSLayoutConstraint constraintWithItem:self.hobbiesValueLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-AAPLCardHorizontalPadding]
       ]];
    
    // Position the elevator pitch below the age and the hobbies
    [constraints addObjectsFromArray:
     @[
       [NSLayoutConstraint constraintWithItem:self.elevatorPitchTitleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.ageTitleLabel attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:self.elevatorPitchTitleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.ageValueLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:AAPLCardInterItemVerticalSpacing],
       [NSLayoutConstraint constraintWithItem:self.elevatorPitchTitleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.hobbiesValueLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:AAPLCardInterItemVerticalSpacing],
       [NSLayoutConstraint constraintWithItem:self.elevatorPitchTitleLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-AAPLCardHorizontalPadding],
       [NSLayoutConstraint constraintWithItem:self.elevatorPitchValueLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.elevatorPitchTitleLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:AAPLCardTitleValueSpacing],
       [NSLayoutConstraint constraintWithItem:self.elevatorPitchValueLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.elevatorPitchTitleLabel attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:self.elevatorPitchValueLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-AAPLCardHorizontalPadding],
       [NSLayoutConstraint constraintWithItem:self.elevatorPitchValueLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-AAPLCardVerticalPadding]
       ]];
    
    [self addConstraints:constraints];
}

- (void)updateWithPerson:(AAPLPerson *)person {
    self.photo.image = person.photo;
    [self updatePhotoConstraint];
    self.ageValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(person.age) numberStyle:NSNumberFormatterDecimalStyle];
    self.hobbiesValueLabel.text = person.hobbies;
    self.elevatorPitchValueLabel.text = person.elevatorPitch;
}

- (void)updatePhotoConstraint {
    self.photoAspectRatioConstraint.constant = (self.photo.image.size.height / self.photo.image.size.width) * AAPLCardPhotoWidth;
}

@end
