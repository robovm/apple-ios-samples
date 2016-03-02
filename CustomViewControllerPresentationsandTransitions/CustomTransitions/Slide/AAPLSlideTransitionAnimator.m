/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A transition animator that transitions between two view controllers in
  a tab bar controller by sliding both view controllers in a given
  direction.
 */

#import "AAPLSlideTransitionAnimator.h"

@implementation AAPLSlideTransitionAnimator

//| ----------------------------------------------------------------------------
- (instancetype)initWithTargetEdge:(UIRectEdge)targetEdge
{
    self = [self init];
    if (self) {
        _targetEdge = targetEdge;
    }
    return self;
}


//| ----------------------------------------------------------------------------
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.35;
}

//| ----------------------------------------------------------------------------
//  Custom transitions within a UITabBarController follow the same
//  conventions as those used for modal presentations.  Your animator will
//  be given the incoming and outgoing view controllers along with a container
//  view where both view controller's views will reside.  Your animator is
//  tasked with animating the incoming view controller's view into the
//  container view.  The frame of the incoming view controller's view is
//  is expected to match the value returned from calling
//  [transitionContext finalFrameForViewController:toViewController] when
//  the transition is complete.
//
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = transitionContext.containerView;
    UIView *fromView;
    UIView *toView;
    
    // In iOS 8, the viewForKey: method was introduced to get views that the
    // animator manipulates.  This method should be preferred over accessing
    // the view of the fromViewController/toViewController directly.
    if ([transitionContext respondsToSelector:@selector(viewForKey:)]) {
        fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    } else {
        fromView = fromViewController.view;
        toView = toViewController.view;
    }
    
    CGRect fromFrame = [transitionContext initialFrameForViewController:fromViewController];
    CGRect toFrame = [transitionContext finalFrameForViewController:toViewController];
    
    // Based on the configured targetEdge, derive a normalized vector that will
    // be used to offset the frame of the view controllers.
    CGVector offset;
    if (self.targetEdge == UIRectEdgeLeft)
        offset = CGVectorMake(-1.f, 0.f);
    else if (self.targetEdge == UIRectEdgeRight)
        offset = CGVectorMake(1.f, 0.f);
    else
        NSAssert(NO, @"targetEdge must be one of UIRectEdgeLeft, or UIRectEdgeRight.");
    
    // The toView starts off-screen and slides in as the fromView slides out.
    fromView.frame = fromFrame;
    toView.frame = CGRectOffset(toFrame, toFrame.size.width * offset.dx * -1,
                                toFrame.size.height * offset.dy * -1);
    
    // We are responsible for adding the incoming view to the containerView.
    [containerView addSubview:toView];
    
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:transitionDuration animations:^{
        fromView.frame = CGRectOffset(fromFrame, fromFrame.size.width * offset.dx,
                                      fromFrame.size.height * offset.dy);
        toView.frame = toFrame;
        
    } completion:^(BOOL finished) {
        BOOL wasCancelled = [transitionContext transitionWasCancelled];
        // When we complete, tell the transition context
        // passing along the BOOL that indicates whether the transition
        // finished or not.
        [transitionContext completeTransition:!wasCancelled];
    }];
}

@end
