/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The first view controller in the application.  Shows the application logo and navigation buttons.
  
 */

#import "AAPLStartViewController.h"
#import "AAPLStyleUtilities.h"
#import "AAPLProfileViewController.h"
#import "AAPLMatchesViewController.h"

static const CGFloat AAPLButtonToButtonVerticalSpacing = 10.0;
static const CGFloat AAPLLogoPadding = 30.0;

@implementation AAPLStartViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"HelloGoodbye", @"Title of the start page");
        self.backgroundImage = [UIImage imageNamed:@"couple"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *containerView = self.view;
    
    UIView *logoOverlayView = [[UIView alloc] init];
    logoOverlayView.backgroundColor = [AAPLStyleUtilities overlayColor];
    logoOverlayView.layer.cornerRadius = [AAPLStyleUtilities overlayCornerRadius];
    logoOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:logoOverlayView];
    
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    logo.isAccessibilityElement = YES;
    logo.accessibilityLabel = NSLocalizedString(@"Hello goodbye, meet your match", @"Logo description");
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:logo];
    
    UIButton *profileButton = [self roundedRectButtonWithTitle:NSLocalizedString(@"Profile", @"Title of the profile page") action:@selector(showProfile)];
    [containerView addSubview:profileButton];
    UIButton *matchesButton = [self roundedRectButtonWithTitle:NSLocalizedString(@"Matches", @"Title of the matches page") action:@selector(showMatches)];
    [containerView addSubview:matchesButton];
    
    NSMutableArray *constraints = [NSMutableArray array];
    
    // Use dummy views space the top of the view, the logo, the buttons, and the bottom of the view evenly apart
    UIView *topDummyView = [self addDummyViewToContainerView:containerView alignedOnTopWithItem:[self topLayoutGuide] onBottomWithItem:logoOverlayView constraints:constraints];
    UIView *middleDummyView = [self addDummyViewToContainerView:containerView alignedOnTopWithItem:logoOverlayView onBottomWithItem:profileButton constraints:constraints];
    UIView *bottomDummyView = [self addDummyViewToContainerView:containerView alignedOnTopWithItem:matchesButton onBottomWithItem:[self bottomLayoutGuide] constraints:constraints];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:topDummyView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:middleDummyView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:middleDummyView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:bottomDummyView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
    
    // Position the logo
    [constraints addObjectsFromArray:
     @[
       [NSLayoutConstraint constraintWithItem:logoOverlayView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topDummyView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:logoOverlayView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:logoOverlayView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:middleDummyView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:logo attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:logoOverlayView attribute:NSLayoutAttributeTop multiplier:1.0 constant:AAPLLogoPadding],
       [NSLayoutConstraint constraintWithItem:logo attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:logoOverlayView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-AAPLLogoPadding],
       [NSLayoutConstraint constraintWithItem:logo attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:logoOverlayView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:AAPLLogoPadding],
       [NSLayoutConstraint constraintWithItem:logo attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:logoOverlayView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-AAPLLogoPadding]
       ]];
    
    // Position the profile button
    [constraints addObject:[NSLayoutConstraint constraintWithItem:profileButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:profileButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:middleDummyView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    
    // Put the matches button below the profile button
    [constraints addObject:[NSLayoutConstraint constraintWithItem:matchesButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:profileButton attribute:NSLayoutAttributeBottom multiplier:1.0 constant:AAPLButtonToButtonVerticalSpacing]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:matchesButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomDummyView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    
    // Align the left and right edges of the two buttons and the logo
    [constraints addObject:[NSLayoutConstraint constraintWithItem:matchesButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:profileButton attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:matchesButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:profileButton attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:matchesButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:logoOverlayView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:matchesButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:logoOverlayView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    
    [containerView addConstraints:constraints];
}

- (UIView *)addDummyViewToContainerView:(UIView *)containerView alignedOnTopWithItem:(id)topItem onBottomWithItem:(id)bottomItem constraints:(NSMutableArray *)constraints
{
    UIView *dummyView = [[UIView alloc] init];
    dummyView.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:dummyView];
    
    // The horizontal layout of the dummy view does not matter, but for completeness, we give it a width of 0 and center it horizontally.
    [constraints addObjectsFromArray:
     @[
       [NSLayoutConstraint constraintWithItem:dummyView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:dummyView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:dummyView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:topItem attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:dummyView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:bottomItem attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]
       ]];
    return dummyView;
}

- (UIButton *)roundedRectButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [AAPLStyleUtilities overlayRoundedRectButton];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)showProfile {
    AAPLProfileViewController *profileViewController = [[AAPLProfileViewController alloc] init];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

- (void)showMatches {
    AAPLMatchesViewController *matchesViewController = [[AAPLMatchesViewController alloc] init];
    [self.navigationController pushViewController:matchesViewController animated:YES];
}

@end
