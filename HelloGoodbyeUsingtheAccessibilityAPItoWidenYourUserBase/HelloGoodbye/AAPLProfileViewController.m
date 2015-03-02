/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The profile view controller in the application.  Allows users to view, edit, and preview their profile.
  
 */

#import "AAPLProfileViewController.h"
#import "AAPLStyleUtilities.h"
#import "AAPLCardView.h"
#import "AAPLPerson.h"
#import "AAPLAgeSlider.h"
#import "AAPLPreviewLabel.h"

static const CGFloat AAPLLabelControlMinimumSpacing = 20.0;
static const CGFloat AAPLMinimumVerticalSpacingBetweenRows = 20.0;
static const CGFloat AAPLPreviewTabMinimumWidth = 80.0;
static const CGFloat AAPLPreviewTabHeight = 30.0;
static const CGFloat AAPLPreviewTabCornerRadius = 10.0;
static const CGFloat AAPLPreviewTabHorizontalPadding = 30.0;
static const NSTimeInterval AAPLCardRevealAnimationDuration = 0.3;

@interface AAPLProfileViewController () <UITextFieldDelegate, AAPLPreviewLabelDelegate>

@property (nonatomic) AAPLPerson *person;
@property (nonatomic) UILabel *ageValueLabel;
@property (nonatomic) UITextField *hobbiesField;
@property (nonatomic) UITextField *elevatorPitchField;
@property (nonatomic) UIImageView *previewTab;
@property (nonatomic) AAPLCardView *cardView;
@property (nonatomic) NSLayoutConstraint *cardRevealConstraint;
@property (nonatomic) BOOL cardWasRevealedBeforePan;

@end

@implementation AAPLProfileViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Profile", @"Title of the profile page");
        self.backgroundImage = [UIImage imageNamed:@"girl-bg"];
        
        // Create the model.  If we had a backing service, this model would pull data from the user's account settings.
        self.person = [[AAPLPerson alloc] init];
        self.person.photo = [UIImage imageNamed:@"girl"];
        self.person.age = 37;
        self.person.hobbies = @"Music, swing dance, wine";
        self.person.elevatorPitch = @"I can keep a steady beat.";
    }
    return self;
}

#pragma mark - Views and Constraints

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *containerView = self.view;
    NSMutableArray *constraints = [NSMutableArray array];
    
    UIView *overlayView = [self addOverlayViewToView:containerView constraints:constraints];
    NSArray *ageControls = [self addAgeControlsToView:overlayView constraints:constraints];
    self.hobbiesField = [self addTextFieldWithName:NSLocalizedString(@"Hobbies", @"The user's hobbies") text:self.person.hobbies toView:overlayView previousRowItems:ageControls constraints:constraints];
    self.elevatorPitchField = [self addTextFieldWithName:NSLocalizedString(@"Elevator Pitch", @"The user's elevator pitch for finding a partner") text:self.person.elevatorPitch toView:overlayView previousRowItems:@[self.hobbiesField] constraints:constraints];
    
    [self addCardAndPreviewTab:constraints];
    
    [containerView addConstraints:constraints];
}

- (UIView *)addOverlayViewToView:(UIView *)containerView constraints:(NSMutableArray *)constraints {
    UIView *overlayView = [[UIView alloc] init];
    overlayView.backgroundColor = [AAPLStyleUtilities overlayColor];
    overlayView.layer.cornerRadius = [AAPLStyleUtilities overlayCornerRadius];
    overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:overlayView];
    
    // Cover the view controller with the overlay, leaving a margin on all sides
    CGFloat margin = [AAPLStyleUtilities overlayMargin];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:[self topLayoutGuide] attribute:NSLayoutAttributeBottom multiplier:1.0 constant:margin]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:[self bottomLayoutGuide] attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-margin]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:margin]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-margin]];
    return overlayView;
}

- (void)updateAgeValueLabelFromSlider:(AAPLAgeSlider *)ageSlider {
    self.ageValueLabel.text = [NSNumberFormatter localizedStringFromNumber:@(ageSlider.value) numberStyle:NSNumberFormatterDecimalStyle];
}

- (UILabel *)addAgeValueLabelToView:(UIView *)overlayView {
    UILabel *ageValueLabel = [AAPLStyleUtilities standardLabel];
    ageValueLabel.isAccessibilityElement = NO;
    [overlayView addSubview:ageValueLabel];
    return ageValueLabel;
}

- (NSArray *)addAgeControlsToView:(UIView *)overlayView constraints:(NSMutableArray *)constraints {
    UILabel *ageTitleLabel = [AAPLStyleUtilities standardLabel];
    ageTitleLabel.text = NSLocalizedString(@"Your age", @"The user's age");
    [overlayView addSubview:ageTitleLabel];
    
    AAPLAgeSlider *ageSlider = [[AAPLAgeSlider alloc] init];
    ageSlider.value = self.person.age;
    [ageSlider addTarget:self action:@selector(didUpdateAge:) forControlEvents:UIControlEventValueChanged];
    ageSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [overlayView addSubview:ageSlider];
    
    // Display the current age next to the slider
    self.ageValueLabel = [self addAgeValueLabelToView:overlayView];
    [self updateAgeValueLabelFromSlider:ageSlider];
    
    // Position the age title and value side by side, within the overlay view
    [constraints addObject:[NSLayoutConstraint constraintWithItem:ageTitleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:overlayView attribute:NSLayoutAttributeTop multiplier:1.0 constant:[AAPLStyleUtilities contentVerticalMargin]]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:ageTitleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:overlayView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:[AAPLStyleUtilities contentHorizontalMargin]]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:ageSlider attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:ageTitleLabel attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:AAPLLabelControlMinimumSpacing]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:ageSlider attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:ageTitleLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.ageValueLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:ageSlider attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:AAPLLabelControlMinimumSpacing]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.ageValueLabel attribute:NSLayoutAttributeFirstBaseline relatedBy:NSLayoutRelationEqual toItem:ageTitleLabel attribute:NSLayoutAttributeFirstBaseline multiplier:1.0 constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.ageValueLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:overlayView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-1 * [AAPLStyleUtilities contentHorizontalMargin]]];
    
    return @[ageTitleLabel, ageSlider, self.ageValueLabel];
}

- (UITextField *)addTextFieldWithName:(NSString *)name text:(NSString *)text toView:(UIView *)overlayView previousRowItems:(NSArray *)previousRowItems constraints:(NSMutableArray *)constraints {
    UILabel *titleLabel = [AAPLStyleUtilities standardLabel];
    titleLabel.text = name;
    [overlayView addSubview:titleLabel];
    
    UITextField *valueField = [[UITextField alloc] init];
    valueField.delegate = self;
    valueField.font = [AAPLStyleUtilities standardFont];
    valueField.textColor = [AAPLStyleUtilities detailOnOverlayColor];
    valueField.text = text;
    valueField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Type here...", @"Placeholder for profile text fields") attributes:@{NSForegroundColorAttributeName: [AAPLStyleUtilities detailOnOverlayPlaceholderColor]}];
    valueField.translatesAutoresizingMaskIntoConstraints = NO;
    [overlayView addSubview:valueField];
    
    // Ensure sufficient spacing from the row above this one
    for (UIView *previousRowItem in previousRowItems) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:previousRowItem attribute:NSLayoutAttributeBottom multiplier:1.0 constant:AAPLMinimumVerticalSpacingBetweenRows]];
    }
    
    // Place the title directly above the value
    [constraints addObject:[NSLayoutConstraint constraintWithItem:valueField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:titleLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    
    // Position the title and value within the overlay view
    [constraints addObject:[NSLayoutConstraint constraintWithItem:titleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:overlayView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:[AAPLStyleUtilities contentHorizontalMargin]]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:valueField attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:titleLabel attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:valueField attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:overlayView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-1 * [AAPLStyleUtilities contentHorizontalMargin]]];
    
    return valueField;
}

- (UIImage *)previewTabBackgroundImage {
    // The preview tab should be flat on the bottom, and have rounded corners on top.
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(AAPLPreviewTabMinimumWidth, AAPLPreviewTabHeight), NO, [[UIScreen mainScreen] scale]);
    UIBezierPath *roundedTopCornersRect = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.0, 0.0, AAPLPreviewTabMinimumWidth, AAPLPreviewTabHeight) byRoundingCorners:(UIRectCorner)(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(AAPLPreviewTabCornerRadius, AAPLPreviewTabCornerRadius)];
    [[AAPLStyleUtilities foregroundColor] set];
    [roundedTopCornersRect fill];
    UIImage *previewTabBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    previewTabBackgroundImage = [previewTabBackgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, AAPLPreviewTabCornerRadius, 0.0, AAPLPreviewTabCornerRadius)];
    UIGraphicsEndImageContext();
    return previewTabBackgroundImage;
}

- (UIImageView *)addPreviewTab {
    UIImage *previewTabBackgroundImage = [self previewTabBackgroundImage];
    UIImageView *previewTab = [[UIImageView alloc] initWithImage:previewTabBackgroundImage];
    previewTab.userInteractionEnabled = YES;
    [self.view addSubview:previewTab];
    
    UIPanGestureRecognizer *revealGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didSlidePreviewTab:)];
    [previewTab addGestureRecognizer:revealGestureRecognizer];
    return previewTab;
}

- (AAPLPreviewLabel *)addPreviewLabel {
    AAPLPreviewLabel *previewLabel = [[AAPLPreviewLabel alloc] init];
    previewLabel.delegate = self;
    [self.view addSubview:previewLabel];
    return previewLabel;
}

- (AAPLCardView *)addCardView {
    AAPLCardView *cardView = [[AAPLCardView alloc] init];
    [cardView updateWithPerson:self.person];
    self.cardView = cardView;
    [self.view addSubview:cardView];
    return cardView;
}

- (void)addCardAndPreviewTab:(NSMutableArray *)constraints {
    self.previewTab = [self addPreviewTab];
    self.previewTab.translatesAutoresizingMaskIntoConstraints = NO;
    
    AAPLPreviewLabel *previewLabel = [self addPreviewLabel];
    previewLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    AAPLCardView *cardView = [self addCardView];
    cardView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Pin the tab to the bottom center of the screen
    self.cardRevealConstraint = [NSLayoutConstraint constraintWithItem:self.previewTab attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [constraints addObject:self.cardRevealConstraint];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.previewTab attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    
    // Center the preview label within the tab
    [constraints addObject:[NSLayoutConstraint constraintWithItem:previewLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.previewTab attribute:NSLayoutAttributeLeading multiplier:1.0 constant:AAPLPreviewTabHorizontalPadding]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:previewLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.previewTab attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-AAPLPreviewTabHorizontalPadding]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:previewLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.previewTab attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    // Pin the top of the card to the bottom of the tab
    [constraints addObject:[NSLayoutConstraint constraintWithItem:cardView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.previewTab attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:cardView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.previewTab attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    
    // Ensure that the card fits within the view
    [constraints addObject:[NSLayoutConstraint constraintWithItem:cardView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
}

#pragma mark - Responding to Actions

- (void)didUpdateAge:(AAPLAgeSlider *)ageSlider {
    // Turn the value into a valid age
    ageSlider.value = round(ageSlider.value);
    
    // Display the updated age next to the slider
    [self updateAgeValueLabelFromSlider:ageSlider];
    
    // Update the model
    self.person.age = ageSlider.value;
    
    // Update the card view with the new data
    [self.cardView updateWithPerson:self.person];
}

- (BOOL)isCardRevealed {
    return (self.cardRevealConstraint.constant < 0.0);
}

- (CGFloat)cardHeight {
    return CGRectGetHeight(self.cardView.frame);
}

- (void)revealCard {
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:AAPLCardRevealAnimationDuration animations:^{
        self.cardRevealConstraint.constant = -1 * [self cardHeight];
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }];
}

- (void)dismissCard {
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:AAPLCardRevealAnimationDuration animations:^{
        self.cardRevealConstraint.constant = 0.0;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }];
}

- (void)didSlidePreviewTab:(UIPanGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            self.cardWasRevealedBeforePan = [self isCardRevealed];
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGFloat cardHeight = [self cardHeight];
            CGFloat cardRevealConstant = [gestureRecognizer translationInView:self.view].y;
            if (self.cardWasRevealedBeforePan) {
                cardRevealConstant += -1 * cardHeight;
            }
            // Never let the card tab move off screen
            cardRevealConstant = MIN(0.0, cardRevealConstant);
            // Never let the card have a gap below it
            cardRevealConstant = MAX(-1 * cardHeight, cardRevealConstant);
            self.cardRevealConstraint.constant = cardRevealConstant;
        }
            break;
        case UIGestureRecognizerStateEnded:
            if (self.cardRevealConstraint.constant > (-0.5 * [self cardHeight])) {
                // Card was closer to the bottom of the screen
                [self dismissCard];
            } else {
                [self revealCard];
            }
            break;
        case UIGestureRecognizerStateCancelled:
            if (self.cardWasRevealedBeforePan) {
                [self revealCard];
            } else {
                [self dismissCard];
            }
            break;
        default:
            break;
    }
}

- (void)doneButtonPressed:(id)sender {
    // End editing on whichever text field is first responder
    [self.hobbiesField resignFirstResponder];
    [self.elevatorPitchField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // Add a Done button so that the user can dismiss the keyboard easily
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    // Remove the Done button
    self.navigationItem.rightBarButtonItem = nil;
    
    // Update the model
    if (textField == self.hobbiesField) {
        self.person.hobbies = textField.text;
    } else if (textField == self.elevatorPitchField) {
        self.person.elevatorPitch = textField.text;
    }
    
    // Update the card view with the new data
    [self.cardView updateWithPerson:self.person];
}

#pragma mark - AAPLPreviewLabelDelegate

- (void)didActivatePreviewLabel:(AAPLPreviewLabel *)previewLabel {
    if ([self isCardRevealed]) {
        [self dismissCard];
    } else {
        [self revealCard];
    }
}

@end
