/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The initial view controller for the Cross Dissolve demo.
 */

#import "AAPLCrossDissolveFirstViewController.h"
#import "AAPLCrossDissolveTransitionAnimator.h"

@interface AAPLCrossDissolveFirstViewController() <UIViewControllerTransitioningDelegate>
@end


@implementation AAPLCrossDissolveFirstViewController

//| ----------------------------------------------------------------------------
- (IBAction)presentWithCustomTransitionAction:(id)sender
{
    // For the sake of example, this demo implements the presentation and
    // dismissal logic completely in code.  Take a look at the later demos
    // to learn how to integrate custom transitions with segues.
    UIViewController *secondViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SecondViewController"];
    
    // Setting the modalPresentationStyle to FullScreen enables the
    // <ContextTransitioning> to provide more accurate initial and final frames
    // of the participating view controllers
    secondViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    // The transitioning delegate can supply a custom animation controller
    // that will be used to animate the incoming view controller.
    secondViewController.transitioningDelegate = self;
    
    [self presentViewController:secondViewController animated:YES completion:NULL];
}

#pragma mark -
#pragma mark UIViewControllerTransitioningDelegate

//| ----------------------------------------------------------------------------
//  The system calls this method on the presented view controller's
//  transitioningDelegate to retrieve the animator object used for animating
//  the presentation of the incoming view controller.  Your implementation is
//  expected to return an object that conforms to the
//  UIViewControllerAnimatedTransitioning protocol, or nil if the default
//  presentation animation should be used.
//
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [AAPLCrossDissolveTransitionAnimator new];
}


//| ----------------------------------------------------------------------------
//  The system calls this method on the presented view controller's
//  transitioningDelegate to retrieve the animator object used for animating
//  the dismissal of the presented view controller.  Your implementation is
//  expected to return an object that conforms to the
//  UIViewControllerAnimatedTransitioning protocol, or nil if the default
//  dismissal animation should be used.
//
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [AAPLCrossDissolveTransitionAnimator new];
}

@end
