/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The delegate of the tab bar controller for the Slide demo.  Manages the
  gesture recognizer used for the interactive transition.  Vends
  instances of AAPLSlideTransitionAnimator and 
  AAPLSlideTransitionInteractionController.
 */

#import "AAPLSlideTransitionDelegate.h"
#import "AAPLSlideTransitionAnimator.h"
#import "AAPLSlideTransitionInteractionController.h"
#import <objc/runtime.h>

//! They key used to associate an instance of AAPLSlideTransitionDelegate with
//! the tab bar controller for which it is the delegate.
const char * AAPLSlideTabBarControllerDelegateAssociationKey = "AAPLSlideTabBarControllerDelegateAssociation";

@interface AAPLSlideTransitionDelegate ()
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@end


@implementation AAPLSlideTransitionDelegate

//| ----------------------------------------------------------------------------
//  Custom implementation of the setter for the tabBarController property.
//
//  An instance of the AAPLSlideTransitionDelegate class is defined in the
//  Tab Bar Controller's scene in the storyboard, and its tabBarControllerOutlet
//  connected to the tab bar controller.  At unarchive time this method will
//  be called, providing an opportunity to perform the necessary setup.
//
- (void)setTabBarController:(UITabBarController *)tabBarController
{
    if (tabBarController != _tabBarController) {
        // Remove all associations of this object from the old tab bar
        // controller.
        objc_setAssociatedObject(_tabBarController, AAPLSlideTabBarControllerDelegateAssociationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [_tabBarController.view removeGestureRecognizer:self.panGestureRecognizer];
        if (_tabBarController.delegate == self) _tabBarController.delegate = nil;
        
        _tabBarController = tabBarController;
        
        _tabBarController.delegate = self;
        [_tabBarController.view addGestureRecognizer:self.panGestureRecognizer];
        // Associate this object with the new tab bar controller.  This ensures
        // that this object wil not be deallocated prior to the tab bar
        // controller being deallocated.
        objc_setAssociatedObject(_tabBarController, AAPLSlideTabBarControllerDelegateAssociationKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark -
#pragma mark Gesture Recognizer

//| ----------------------------------------------------------------------------
//  Custom implementation of the getter for the panGestureRecognizer property.
//  Lazily creates the pan gesture recognizer for the tab bar controller.
//
- (UIPanGestureRecognizer*)panGestureRecognizer
{
    if (_panGestureRecognizer == nil)
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerDidPan:)];
    
    return _panGestureRecognizer;
}


//| ----------------------------------------------------------------------------
//! Action method for the panGestureRecognizer.
//
- (IBAction)panGestureRecognizerDidPan:(UIPanGestureRecognizer*)sender
{
    // Do not attempt to begin an interactive transition if one is already
    // ongoing
    if (self.tabBarController.transitionCoordinator)
        return;
    
    if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateChanged)
        [self beginInteractiveTransitionIfPossible:sender];
    
    // Remaining cases are handled by the vended
    // AAPLSlideTransitionInteractionController.
}


//| ----------------------------------------------------------------------------
//! Begins an interactive transition with the provided gesture recognizer, if
//! there is a view controller to transition to.
//
- (void)beginInteractiveTransitionIfPossible:(UIPanGestureRecognizer *)sender
{
    CGPoint translation = [sender translationInView:self.tabBarController.view];
    
    if (translation.x > 0.f && self.tabBarController.selectedIndex > 0) {
        // Panning right, transition to the left view controller.
        self.tabBarController.selectedIndex--;
    } else if (translation.x < 0.f && self.tabBarController.selectedIndex + 1 < self.tabBarController.viewControllers.count) {
        // Panning left, transition to the right view controller.
        self.tabBarController.selectedIndex++;
    } else {
        // Don't reset the gesture recognizer if we skipped starting the
        // transition because we don't have a translation yet (and thus, could
        // not determine the transition direction).
        if (!CGPointEqualToPoint(translation, CGPointZero)) {
            // There is not a view controller to transition to, force the
            // gesture recognizer to fail.
            sender.enabled = NO;
            sender.enabled = YES;
        }
    }
    
    // We must handle the case in which the user begins panning but then
    // reverses direction without lifting their finger.  The transition
    // should seamlessly switch to revealing the correct view controller
    // for the new direction.
    //
    // The approach presented in this demonstration relies on coordination
    // between this object and the AAPLSlideTransitionInteractionController
    // it vends.  If the AAPLSlideTransitionInteractionController detects
    // that the current position of the user's touch along the horizontal
    // axis has crossed over the initial position, it cancels the
    // transition.  A completion block is attached to the tab bar
    // controller's transition coordinator.  This block will be called when
    // the transition completes or is cancelled.  If the transition was
    // cancelled but the gesture recgonzier has not transitioned to the
    // ended or failed state, a new transition to the proper view controller
    // is started, and new animation + interaction controllers are created.
    //
    [self.tabBarController.transitionCoordinator animateAlongsideTransition:NULL completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if ([context isCancelled] && sender.state == UIGestureRecognizerStateChanged)
            [self beginInteractiveTransitionIfPossible:sender];
    }];
}

#pragma mark -
#pragma mark UITabBarControllerDelegate

//| ----------------------------------------------------------------------------
//  The tab bar controller tries to invoke this method on its delegate to
//  retrieve an animator object to be used for animating the transition to the
//  incoming view controller.  Your implementation is expected to return an
//  object that conforms to the UIViewControllerAnimatedTransitioning protocol,
//  or nil if the transition should not be animated.
//
- (id<UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController *)tabBarController animationControllerForTransitionFromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    NSAssert(tabBarController == self.tabBarController, @"%@ is not the tab bar controller currently associated with %@", tabBarController, self);
    NSArray *viewControllers = tabBarController.viewControllers;
    
    if ([viewControllers indexOfObject:toVC] > [viewControllers indexOfObject:fromVC]) {
        // The incoming view controller succeeds the outgoing view controller,
        // slide towards the left.
        return [[AAPLSlideTransitionAnimator alloc] initWithTargetEdge:UIRectEdgeLeft];
    } else {
        // The incoming view controller precedes the outgoing view controller,
        // slide towards the right.
        return [[AAPLSlideTransitionAnimator alloc] initWithTargetEdge:UIRectEdgeRight];
    }
}


//| ----------------------------------------------------------------------------
//  If an id<UIViewControllerAnimatedTransitioning> was returned from
//  -tabBarController:animationControllerForTransitionFromViewController:toViewController:,
//  the tab bar controller tries to invoke this method on its delegate to
//  retrieve an interaction controller for the transition.  Your implementation
//  is expected to return an object that conforms to the
//  UIViewControllerInteractiveTransitioning protocol, or nil if the transition
//  should not be a interactive.
//
- (id<UIViewControllerInteractiveTransitioning>)tabBarController:(UITabBarController *)tabBarController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    NSAssert(tabBarController == self.tabBarController, @"%@ is not the tab bar controller currently associated with %@", tabBarController, self);
    
    if (self.panGestureRecognizer.state == UIGestureRecognizerStateBegan || self.panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        return [[AAPLSlideTransitionInteractionController alloc] initWithGestureRecognizer:self.panGestureRecognizer];
    } else {
        // You must not return an interaction controller from this method unless
        // the transition will be interactive.
        return nil;
    }
}

@end
