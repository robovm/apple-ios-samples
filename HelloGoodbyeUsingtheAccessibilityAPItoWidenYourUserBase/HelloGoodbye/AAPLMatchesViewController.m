/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The matches view controller in the application.  Allows users to view matches suggested by the app.
  
 */

#import "AAPLMatchesViewController.h"
#import "AAPLPerson.h"
#import "AAPLStyleUtilities.h"
#import "AAPLCardView.h"

static const CGFloat AAPLHelloGoodbyeVerticalMargin = 5.0;
static const NSTimeInterval AAPLSwipeAnimationDuration = 0.5;
static const NSTimeInterval AAPLZoomAnimationDuration = 0.3;
static const NSTimeInterval AAPLFadeAnimationDuration = 0.3;

@interface AAPLMatchesViewController ()

@property (nonatomic) AAPLCardView *cardView;
@property (nonatomic) UIView *swipeInstructionsView;
@property (nonatomic) UIView *allMatchesViewedExplanatoryView;

@property (nonatomic) NSArray *cardViewVerticalConstraints;

// Array of AAPLPersons
@property (nonatomic) NSArray *matches;
@property (nonatomic) NSUInteger currentMatchIndex;

@end

@implementation AAPLMatchesViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray *serializedMatches = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"matches" ofType:@"plist"]];
        NSMutableArray *matches = [NSMutableArray arrayWithCapacity:[serializedMatches count]];
        for (NSDictionary *serializedMatch in serializedMatches) {
            AAPLPerson *match = [AAPLPerson personWithDictionary:serializedMatch];
            [matches addObject:match];
        }
        self.title = NSLocalizedString(@"Matches", @"Title of the matches page");
        self.matches = matches;
        
        self.backgroundImage = [UIImage imageNamed:@"dessert"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *containerView = self.view;
    NSMutableArray *constraints = [NSMutableArray array];
    
    // Show instructions for how to say hello and goodbye
    self.swipeInstructionsView = [self addSwipeInstructionsToContainerView:containerView constraints:constraints];
    
    // Add a dummy view to center the card between the explanatory view and the bottom layout guide
    UIView *dummyView = [self addDummyViewToContainerView:containerView topItem:self.swipeInstructionsView bottomItem:[self bottomLayoutGuide] constraints:constraints];
    
    // Create and add the card
    AAPLCardView *cardView = [self addCardViewToView:containerView];
    
    // Define the vertical positioning of the card
    // These constraints will be removed when the card animates off screen
    self.cardViewVerticalConstraints =
    @[
      [NSLayoutConstraint constraintWithItem:cardView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:dummyView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0],
      [NSLayoutConstraint constraintWithItem:cardView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.swipeInstructionsView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:AAPLHelloGoodbyeVerticalMargin]
      ];
    [constraints addObjectsFromArray:self.cardViewVerticalConstraints];
    
    // Ensure that the card is centered horizontally within the container view, and doesn't exceed its width
    [constraints addObjectsFromArray:
     @[
       [NSLayoutConstraint constraintWithItem:cardView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:cardView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:containerView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0],
       [NSLayoutConstraint constraintWithItem:cardView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationLessThanOrEqual toItem:containerView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0],
       ]];
    
    // When the matches run out, we'll show this message
    self.allMatchesViewedExplanatoryView = [self addAllMatchesViewExplanatoryViewToContainerView:containerView constraints:constraints];
    
    [containerView addConstraints:constraints];
}

- (UIView *)addDummyViewToContainerView:(UIView *)containerView topItem:(id)topItem bottomItem:(id)bottomItem constraints:(NSMutableArray *)constraints {
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

- (AAPLCardView *)addCardViewToView:(UIView *)containerView {
    AAPLCardView *cardView = [[AAPLCardView alloc] init];
    [cardView updateWithPerson:[self currentMatch]];
    cardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardView = cardView;
    [containerView addSubview:cardView];
    
    UISwipeGestureRecognizer *swipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    swipeUpRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    [cardView addGestureRecognizer:swipeUpRecognizer];
    
    UISwipeGestureRecognizer *swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
    swipeDownRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [cardView addGestureRecognizer:swipeDownRecognizer];
    
    UIAccessibilityCustomAction *helloAction = [[UIAccessibilityCustomAction alloc] initWithName:NSLocalizedString(@"Say hello", @"Accessibility action to say hello") target:self selector:@selector(sayHello)];
    UIAccessibilityCustomAction *goodbyeAction = [[UIAccessibilityCustomAction alloc] initWithName:NSLocalizedString(@"Say goodbye", @"Accessibility action to say goodbye") target:self selector:@selector(sayGoodbye)];
    for (UIView *element in cardView.accessibilityElements) {
        element.accessibilityCustomActions = @[helloAction, goodbyeAction];
    }
    
    return cardView;
}

- (UIView *)addOverlayViewToContainerView:(UIView *)containerView {
    UIView *overlayView = [[UIView alloc] init];
    overlayView.backgroundColor = [AAPLStyleUtilities overlayColor];
    overlayView.layer.cornerRadius = [AAPLStyleUtilities overlayCornerRadius];
    overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:overlayView];
    return overlayView;
}

- (UIView *)addSwipeInstructionsToContainerView:(UIView *)containerView constraints:(NSMutableArray *)constraints {
    UIView *overlayView = [self addOverlayViewToContainerView:containerView];
    
    UILabel *swipeInstructionsLabel = [AAPLStyleUtilities standardLabel];
    swipeInstructionsLabel.font = [AAPLStyleUtilities largeFont];
    [overlayView addSubview:swipeInstructionsLabel];
    swipeInstructionsLabel.text = NSLocalizedString(@"Swipe ↑ to say \"Hello!\"\nSwipe ↓ to say \"Goodbye...\"", @"Instructions for the Matches page");
    swipeInstructionsLabel.accessibilityLabel = NSLocalizedString(@"Swipe up to say \"Hello!\"\nSwipe down to say \"Goodbye\"", @"Accessibility instructions for the Matches page");
    
    CGFloat overlayMargin = [AAPLStyleUtilities overlayMargin];
    NSLayoutConstraint *topMarginConstraint = [NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:[self topLayoutGuide] attribute:NSLayoutAttributeBottom multiplier:1.0 constant:overlayMargin];
    topMarginConstraint.priority = UILayoutPriorityRequired - 1;
    [constraints addObject:topMarginConstraint];
    
    // Position the label inside the overlay view
    [constraints addObject:[NSLayoutConstraint constraintWithItem:swipeInstructionsLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:overlayView attribute:NSLayoutAttributeTop multiplier:1.0 constant:AAPLHelloGoodbyeVerticalMargin]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:swipeInstructionsLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:overlayView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:swipeInstructionsLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:AAPLHelloGoodbyeVerticalMargin]];
    
    // Center the overlay view horizontally
    [constraints addObject:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:overlayMargin]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-overlayMargin]];
    return overlayView;
}

- (UIView *)addAllMatchesViewExplanatoryViewToContainerView:(UIView *)containerView constraints:(NSMutableArray *)constraints {
    UIView *overlayView = [self addOverlayViewToContainerView:containerView];
    
    // Start out hidden
    // This view will become visible once all matches have been viewed
    overlayView.alpha = 0.0;
    
    UILabel *label = [AAPLStyleUtilities standardLabel];
    label.font = [AAPLStyleUtilities largeFont];
    label.text = NSLocalizedString(@"Stay tuned for more matches!", @"Shown when all matches have been viewed");
    [overlayView addSubview:label];
    
    // Center the overlay view
    [constraints addObject:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:overlayView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    // Position the label in the overlay view
    [constraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:overlayView attribute:NSLayoutAttributeTop multiplier:1.0 constant:[AAPLStyleUtilities contentVerticalMargin]]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:overlayView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-1 * [AAPLStyleUtilities contentVerticalMargin]]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:overlayView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:[AAPLStyleUtilities contentHorizontalMargin]]];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:overlayView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-1 * [AAPLStyleUtilities contentHorizontalMargin]]];
    return overlayView;
}

- (AAPLPerson *)currentMatch {
    AAPLPerson *currentMatch = nil;
    if (self.currentMatchIndex < [self.matches count]) {
        currentMatch = self.matches[self.currentMatchIndex];
    }
    return currentMatch;
}

- (void)zoomCardIntoView {
    self.cardView.transform = CGAffineTransformMakeScale(0.0, 0.0);
    [UIView animateWithDuration:AAPLZoomAnimationDuration animations:^{
        self.cardView.transform = CGAffineTransformIdentity;
    }];
}

- (void)animateCardOffScreenToTop:(BOOL)toTop completion:(void (^)())completion {
    NSLayoutConstraint *offScreenConstraint = nil;
    if (toTop) {
        offScreenConstraint = [NSLayoutConstraint constraintWithItem:self.cardView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    } else {
        offScreenConstraint = [NSLayoutConstraint constraintWithItem:self.cardView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    }
    
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:AAPLSwipeAnimationDuration animations:^{
        // Slide the card off screen
        [self.view removeConstraints:self.cardViewVerticalConstraints];
        [self.view addConstraint:offScreenConstraint];
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        // Bring the card back into view
        [self.view removeConstraint:offScreenConstraint];
        [self.view addConstraints:self.cardViewVerticalConstraints];
        if (completion) {
            completion();
        }
    }];
}

- (void)fadeCardIntoView {
    self.cardView.alpha = 0.0;
    [UIView animateWithDuration:AAPLFadeAnimationDuration animations:^{
        self.cardView.alpha = 1.0;
    }];
}

- (void)animateCardsForHello:(BOOL)forHello {
    [self animateCardOffScreenToTop:forHello completion:^{
        self.currentMatchIndex++;
        AAPLPerson *nextMatch = [self currentMatch];
        if (nextMatch) {
            // Show the next match's profile in the card
            [self.cardView updateWithPerson:nextMatch];
            
            // Ensure that the view's layout is up to date before we animate it
            [self.view layoutIfNeeded];
            
            if (UIAccessibilityIsReduceMotionEnabled()) {
                // Fade the card into view
                [self fadeCardIntoView];
            } else {
                // Zoom the new card from a tiny point into full view
                [self zoomCardIntoView];
            }
        } else {
            // Hide the card
            self.cardView.hidden = YES;
            
            // Fade in the "Stay tuned for more matches" blurb
            [UIView animateWithDuration:AAPLFadeAnimationDuration animations:^{
                self.swipeInstructionsView.alpha = 0.0;
                self.allMatchesViewedExplanatoryView.alpha = 1.0;
            }];
        }
        
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }];
}

- (BOOL)sayHello {
    [self animateCardsForHello:YES];
    return YES;
}

- (BOOL)sayGoodbye {
    [self animateCardsForHello:NO];
    return YES;
}

- (void)handleSwipeUp:(UISwipeGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        [self sayHello];
    }
}

- (void)handleSwipeDown:(UISwipeGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        [self sayGoodbye];
    }
}

@end
