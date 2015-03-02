/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  AAPLOverlayAnimatedTransitioning and AAPLOverlayTransitioningDelegate implementations.
  
 */

#import "AAPLOverlayTransitioner.h"
#import "AAPLOverlayPresentationController.h"
#import "AAPLCoolPresentationController.h"

#import "AAPLRootViewController.h"

@implementation AAPLOverlayTransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    // Here, we'll provide the presentation controller to be used for the presentation
    Class presentationControllerClass;
    
    // If our presentation should be awesome, return the AAPLCoolPresentationController. We determine this based on -[AAPLRootViewController presentationShouldBeAwesome]
    if([source isKindOfClass:[AAPLRootViewController class]] && [(AAPLRootViewController *)source presentationShouldBeAwesome])
    {
        presentationControllerClass = [AAPLCoolPresentationController class];
    }
    else
    {
        presentationControllerClass = [AAPLOverlayPresentationController class];
    }
    
    return [[presentationControllerClass alloc] initWithPresentedViewController:presented presentingViewController:presenting];
}

- (AAPLOverlayAnimatedTransitioning *)animationController
{
    AAPLOverlayAnimatedTransitioning *animationController = [[AAPLOverlayAnimatedTransitioning alloc] init];
    return animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    AAPLOverlayAnimatedTransitioning *animationController = [self animationController];
    [animationController setIsPresentation:YES];
    
    return animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    AAPLOverlayAnimatedTransitioning *animationController = [self animationController];
    [animationController setIsPresentation:NO];
    
    return animationController;
}

@end

@implementation AAPLOverlayAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    // Here, we perform the animations necessary for the transition

    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *fromView = [fromVC view];
    UIViewController *toVC   = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *toView = [toVC view];
    
    UIView *containerView = [transitionContext containerView];
    
    BOOL isPresentation = [self isPresentation];

    if(isPresentation)
    {
        [containerView addSubview:toView];
    }
    
    UIViewController *animatingVC = isPresentation? toVC : fromVC;
    UIView *animatingView = [animatingVC view];
    
    CGRect appearedFrame = [transitionContext finalFrameForViewController:animatingVC];
    // Our dismissed frame is the same as our appeared frame, but off the right edge of the container
    CGRect dismissedFrame = appearedFrame;
    dismissedFrame.origin.x += dismissedFrame.size.width;
    
    CGRect initialFrame = isPresentation ? dismissedFrame : appearedFrame;
    CGRect finalFrame = isPresentation ? appearedFrame : dismissedFrame;
    
    [animatingView setFrame:initialFrame];
    
    // Animate using the duration from -transitionDuration:
    [UIView animateWithDuration:[self transitionDuration:transitionContext]
                          delay:0
         usingSpringWithDamping:300.0
          initialSpringVelocity:5.0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [animatingView setFrame:finalFrame];
                    }
                     completion:^(BOOL finished){
                                    // If we're dismissing, remove the presented view from the hierarchy
                         if(![self isPresentation])
                         {
                             [fromView removeFromSuperview];
                         }
                         // We need to notify the view controller system that the transition has finished
                        [transitionContext completeTransition:YES];
                    }];
}

@end

