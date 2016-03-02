/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A transition animator that transitions between two view controllers in
  a navigation stack, using a 3D checkerboard effect.
 */

#import "AAPLCheckerboardTransitionAnimator.h"

@implementation AAPLCheckerboardTransitionAnimator

//| ----------------------------------------------------------------------------
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 3.0;
}


//| ----------------------------------------------------------------------------
//  Custom transitions within a UINavigationController follow the same
//  conventions as those used for modal presentations.  Your animator will
//  be given the incoming and outgoing view controllers along with a container
//  view where both view controller's views will reside.  Your animator is
//  tasked with animating the incoming view controller's view into the
//  container view.  The frame of the incoming view controller's view is
//  is expected to match the value returned from calling
//  [transitionContext finalFrameForViewController:toViewController] when the
//  transition is complete.
//
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = transitionContext.containerView;
    
    // For a Push:
    //      fromView = The current top view controller.
    //      toView   = The incoming view controller.
    // For a Pop:
    //      fromView = The outgoing view controller.
    //      toView   = The new top view controller.
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
    
    // If a push is being animated, the incoming view controller will have a
    // higher index on the navigation stack than the current top view
    // controller.
    BOOL isPush = ([toViewController.navigationController.viewControllers indexOfObject:toViewController] > [fromViewController.navigationController.viewControllers indexOfObject:fromViewController]);
    
    // Our animation will be operating on snapshots of the fromView and toView,
    // so the final frame of toView can be configured now.
    fromView.frame = [transitionContext initialFrameForViewController:fromViewController];
    toView.frame = [transitionContext finalFrameForViewController:toViewController];
    
    // We are responsible for adding the incoming view to the containerView
    // for the transition.
    [containerView addSubview:toView];
    
    UIImage *fromViewSnapshot;
    __block UIImage *toViewSnapshot;
    
    // Snapshot the fromView.
    UIGraphicsBeginImageContextWithOptions(containerView.bounds.size, YES, containerView.window.screen.scale);
    [fromView drawViewHierarchyInRect:containerView.bounds afterScreenUpdates:NO];
    fromViewSnapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // To avoid a blank snapshot, defer snapshotting the incoming view until it
    // has had a chance to perform layout and drawing (1 run-loop cycle).
    dispatch_async(dispatch_get_main_queue(), ^{
        UIGraphicsBeginImageContextWithOptions(containerView.bounds.size, YES, containerView.window.screen.scale);
        [toView drawViewHierarchyInRect:containerView.bounds afterScreenUpdates:NO];
        toViewSnapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    
    UIView *transitionContainer = [[UIView alloc] initWithFrame:containerView.bounds];
    transitionContainer.opaque = YES;
    transitionContainer.backgroundColor = UIColor.blackColor;
    [containerView addSubview:transitionContainer];
    
    // Apply a perpective transform to the sublayers of transitionContainer.
    CATransform3D t = CATransform3DIdentity;
    t.m34 = 1.0 / -900.0;
    transitionContainer.layer.sublayerTransform = t;
    
    // The size and number of slices is a function of the width.
    CGFloat sliceSize = round(CGRectGetWidth(transitionContainer.frame) / 10.f);
    NSUInteger horizontalSlices = ceil(CGRectGetWidth(transitionContainer.frame) / sliceSize);
    NSUInteger verticalSlices = ceil(CGRectGetHeight(transitionContainer.frame) / sliceSize);
    
    // transitionSpacing controls the transition duration for each slice.
    // Higher values produce longer animations with multiple slices having
    // their animations 'in flight' simultaneously.
    const CGFloat transitionSpacing = 160.f;
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    
    CGVector transitionVector;
    if (isPush) {
        transitionVector = CGVectorMake(CGRectGetMaxX(transitionContainer.bounds) - CGRectGetMinX(transitionContainer.bounds),
                                        CGRectGetMaxY(transitionContainer.bounds) - CGRectGetMinY(transitionContainer.bounds));
    } else {
        transitionVector = CGVectorMake(CGRectGetMinX(transitionContainer.bounds) - CGRectGetMaxX(transitionContainer.bounds),
                                        CGRectGetMinY(transitionContainer.bounds) - CGRectGetMaxY(transitionContainer.bounds));
    }
        
    CGFloat transitionVectorLength = sqrtf( transitionVector.dx * transitionVector.dx + transitionVector.dy * transitionVector.dy );
    CGVector transitionUnitVector = CGVectorMake(transitionVector.dx / transitionVectorLength, transitionVector.dy / transitionVectorLength);
    
    for (NSUInteger y = 0 ; y < verticalSlices; y++)
    {
        for (NSUInteger x = 0; x < horizontalSlices; x++)
        {
            CALayer *fromContentLayer = [CALayer new];
            fromContentLayer.frame = CGRectMake(x * sliceSize * -1.f, y * sliceSize * -1.f, containerView.bounds.size.width, containerView.bounds.size.height);
            fromContentLayer.rasterizationScale = fromViewSnapshot.scale;
            fromContentLayer.contents = (__bridge id)fromViewSnapshot.CGImage;
            
            CALayer *toContentLayer = [CALayer new];
            toContentLayer.frame = CGRectMake(x * sliceSize * -1.f, y * sliceSize * -1.f, containerView.bounds.size.width, containerView.bounds.size.height);
            
            // Snapshotting the toView was deferred so we must also defer applying
            // the snapshot to the layer's contents.
            dispatch_async(dispatch_get_main_queue(), ^{
                // Disable actions so the contents are applied without animation.
                BOOL wereActiondDisabled = [CATransaction disableActions];
                [CATransaction setDisableActions:YES];
                
                toContentLayer.rasterizationScale = toViewSnapshot.scale;
                toContentLayer.contents = (__bridge id)toViewSnapshot.CGImage;
                
                [CATransaction setDisableActions:wereActiondDisabled];
            });
            
            UIView *toCheckboardSquareView = [UIView new];
            toCheckboardSquareView.frame = CGRectMake(x * sliceSize, y * sliceSize, sliceSize, sliceSize);
            toCheckboardSquareView.opaque = NO;
            toCheckboardSquareView.layer.masksToBounds = YES;
            toCheckboardSquareView.layer.doubleSided = NO;
            toCheckboardSquareView.layer.transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
            [toCheckboardSquareView.layer addSublayer:toContentLayer];
            
            UIView *fromCheckboardSquareView = [UIView new];
            fromCheckboardSquareView.frame = CGRectMake(x * sliceSize, y * sliceSize, sliceSize, sliceSize);
            fromCheckboardSquareView.opaque = NO;
            fromCheckboardSquareView.layer.masksToBounds = YES;
            fromCheckboardSquareView.layer.doubleSided = NO;
            fromCheckboardSquareView.layer.transform = CATransform3DIdentity;
            [fromCheckboardSquareView.layer addSublayer:fromContentLayer];
            
            [transitionContainer addSubview:toCheckboardSquareView];
            [transitionContainer addSubview:fromCheckboardSquareView];
        }
    }
    
    
    // Used to track how many slices have animations which are still in flight.
    __block NSUInteger sliceAnimationsPending = 0;
    
    for (NSUInteger y = 0 ; y < verticalSlices; y++)
    {
        for (NSUInteger x = 0; x < horizontalSlices; x++)
        {
            UIView *toCheckboardSquareView = transitionContainer.subviews[y * horizontalSlices * 2 + (x * 2)];
            UIView *fromCheckboardSquareView = transitionContainer.subviews[y * horizontalSlices * 2 + (x * 2 + 1)];
            
            CGVector sliceOriginVector;
            if (isPush) {
                // Define a vector from the origin of transitionContainer to the
                // top left corner of the slice.
                sliceOriginVector = CGVectorMake(CGRectGetMinX(fromCheckboardSquareView.frame) - CGRectGetMinX(transitionContainer.bounds),
                                                 CGRectGetMinY(fromCheckboardSquareView.frame) - CGRectGetMinY(transitionContainer.bounds));
            } else {
                // Define a vector from the bottom right corner of
                // transitionContainer to the bottom right corner of the slice.
                sliceOriginVector = CGVectorMake(CGRectGetMaxX(fromCheckboardSquareView.frame) - CGRectGetMaxX(transitionContainer.bounds),
                                                 CGRectGetMaxY(fromCheckboardSquareView.frame) - CGRectGetMaxY(transitionContainer.bounds));
            }
            
            // Project sliceOriginVector onto transitionVector.
            CGFloat dot = sliceOriginVector.dx * transitionVector.dx + sliceOriginVector.dy * transitionVector.dy;
            CGVector projection = CGVectorMake(transitionUnitVector.dx * dot/transitionVectorLength,
                                               transitionUnitVector.dy * dot/transitionVectorLength);
            
            // Compute the length of the projection.
            CGFloat projectionLength = sqrtf( projection.dx * projection.dx + projection.dy * projection.dy );
            
            NSTimeInterval startTime = projectionLength/(transitionVectorLength + transitionSpacing) * transitionDuration;
            NSTimeInterval duration = ( (projectionLength + transitionSpacing)/(transitionVectorLength + transitionSpacing) * transitionDuration ) - startTime;
            
            sliceAnimationsPending++;
            
            [UIView animateWithDuration:duration delay:startTime options:0 animations:^{
                toCheckboardSquareView.layer.transform = CATransform3DIdentity;
                fromCheckboardSquareView.layer.transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
            } completion:^(BOOL finished) {
                // Finish the transition once the final animation completes.
                if (--sliceAnimationsPending == 0) {
                    BOOL wasCancelled = [transitionContext transitionWasCancelled];
                    
                    [transitionContainer removeFromSuperview];
                    
                    // When we complete, tell the transition context
                    // passing along the BOOL that indicates whether the transition
                    // finished or not.
                    [transitionContext completeTransition:!wasCancelled];
                }
            }];
        }
    }
}

@end
