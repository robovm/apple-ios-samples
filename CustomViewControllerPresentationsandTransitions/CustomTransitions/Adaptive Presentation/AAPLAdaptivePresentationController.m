/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLAdaptivePresentationController.h"

@interface AAPLAdaptivePresentationController () <UIViewControllerAnimatedTransitioning>
@property (nonatomic, strong) UIView *presentationWrappingView;
@property (nonatomic, strong) UIButton *dismissButton;
@end


@implementation AAPLAdaptivePresentationController

//| ----------------------------------------------------------------------------
- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController
{
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    
    if (self) {
        // The presented view controller must have a modalPresentationStyle
        // of UIModalPresentationCustom for a custom presentation controller
        // to be used.
        presentedViewController.modalPresentationStyle = UIModalPresentationCustom;
    }
    
    return self;
}


//| ----------------------------------------------------------------------------
- (UIView*)presentedView
{
    // Return the wrapping view created in -presentationTransitionWillBegin.
    return self.presentationWrappingView;
}


//| ----------------------------------------------------------------------------
//  This is one of the first methods invoked on the presentation controller
//  at the start of a presentation.  By the time this method is called,
//  the containerView has been created and the view hierarchy set up for the
//  presentation.  However, the -presentedView has not yet been retrieved.
//
- (void)presentationTransitionWillBegin
{
    // The default implementation of -presentedView returns
    // self.presentedViewController.view.
    UIView *presentedViewControllerView = [super presentedView];
    
    // Wrap the presented view controller's view in an intermediate hierarchy
    // that applies a shadow and adds a dismiss button to the top left corner.
    //
    // presentationWrapperView              <- shadow
    //     |- presentedViewControllerView (presentedViewController.view)
    //     |- close button
    {
        UIView *presentationWrapperView = [[UIView alloc] initWithFrame:CGRectZero];
        presentationWrapperView.layer.shadowOpacity = 0.63f;
        presentationWrapperView.layer.shadowRadius = 17.f;
        self.presentationWrappingView = presentationWrapperView;
        
        // Add presentedViewControllerView -> presentationWrapperView.
        presentedViewControllerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        //presentedViewControllerView.layer.borderColor = [UIColor grayColor].CGColor;
        //presentedViewControllerView.layer.borderWidth = 2.f;
        [presentationWrapperView addSubview:presentedViewControllerView];
        
        // Create the dismiss button.
        UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        dismissButton.frame = CGRectMake(0, 0, 26.f, 26.f);
        [dismissButton setImage:[UIImage imageNamed:@"CloseButton"] forState:UIControlStateNormal];
        [dismissButton addTarget:self action:@selector(dismissButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        self.dismissButton = dismissButton;
        
        // Add dismissButton -> presentationWrapperView.
        [presentationWrapperView addSubview:dismissButton];
    }
}

#pragma mark -
#pragma mark Dismiss Button

//| ----------------------------------------------------------------------------
//  IBAction for the dismiss button.  Dismisses the presented view controller.
//
- (IBAction)dismissButtonTapped:(UIButton*)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -
#pragma mark Layout

//| ----------------------------------------------------------------------------
//  This method is invoked when the interface rotates.  For performance,
//  the shadow on presentationWrapperView is disabled for the duration
//  of the rotation animation.
//
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    self.presentationWrappingView.clipsToBounds = YES;
    self.presentationWrappingView.layer.shadowOpacity = 0.f;
    self.presentationWrappingView.layer.shadowRadius = 0.f;
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Intentionally left blank.
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.presentationWrappingView.clipsToBounds = NO;
        self.presentationWrappingView.layer.shadowOpacity = 0.63f;
        self.presentationWrappingView.layer.shadowRadius = 17.f;
    }];
}


//| ----------------------------------------------------------------------------
//  When the presentation controller receives a
//  -viewWillTransitionToSize:withTransitionCoordinator: message it calls this
//  method to retrieve the new size for the presentedViewController's view.
//  The presentation controller then sends a
//  -viewWillTransitionToSize:withTransitionCoordinator: message to the
//  presentedViewController with this size as the first argument.
//
//  Note that it is up to the presentation controller to adjust the frame
//  of the presented view controller's view to match this promised size.
//  We do this in -containerViewWillLayoutSubviews.
//
- (CGSize)sizeForChildContentContainer:(id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize
{
    if (container == self.presentedViewController)
        return CGSizeMake(parentSize.width/2, parentSize.height/2);
    else
        return [super sizeForChildContentContainer:container withParentContainerSize:parentSize];
}


//| ----------------------------------------------------------------------------
- (CGRect)frameOfPresentedViewInContainerView
{
    CGRect containerViewBounds = self.containerView.bounds;
    CGSize presentedViewContentSize = [self sizeForChildContentContainer:self.presentedViewController withParentContainerSize:containerViewBounds.size];
    
    // Center the presentationWrappingView view within the container.
    CGRect frame = CGRectMake(CGRectGetMidX(containerViewBounds) - presentedViewContentSize.width/2,
                              CGRectGetMidY(containerViewBounds) - presentedViewContentSize.height/2,
                              presentedViewContentSize.width, presentedViewContentSize.height);
    
    // Outset the centered frame of presentationWrappingView so that the
    // dismiss button is within the bounds of presentationWrappingView.
    return CGRectInset(frame, -20, -20);
}


//| ----------------------------------------------------------------------------
//  This method is similar to the -viewWillLayoutSubviews method in
//  UIViewController.  It allows the presentation controller to alter the
//  layout of any custom views it manages.
//
- (void)containerViewWillLayoutSubviews
{
    [super containerViewWillLayoutSubviews];
    
    self.presentationWrappingView.frame = self.frameOfPresentedViewInContainerView;
    
    // Undo the outset that was applied in -frameOfPresentedViewInContainerView.
    self.presentedViewController.view.frame = CGRectInset(self.presentationWrappingView.bounds, 20, 20);
    
    // Position the dismissButton above the top-left corner of the presented
    // view controller's view.
    self.dismissButton.center = CGPointMake(CGRectGetMinX(self.presentedViewController.view.frame),
                                            CGRectGetMinY(self.presentedViewController.view.frame));
}

#pragma mark -
#pragma mark UIViewControllerAnimatedTransitioning

//| ----------------------------------------------------------------------------
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return [transitionContext isAnimated] ? 0.35 : 0;
}


//| ----------------------------------------------------------------------------
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = transitionContext.containerView;
    
    // For a Presentation:
    //      fromView = The presenting view.
    //      toView   = The presented view.
    // For a Dismissal:
    //      fromView = The presented view.
    //      toView   = The presenting view.
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    
    BOOL isPresenting = (fromViewController == self.presentingViewController);
    
    // We are responsible for adding the incoming view to the containerView
    // for the presentation (will have no effect on dismissal because the
    // presenting view controller's view was not removed).
    [containerView addSubview:toView];
    
    if (isPresenting) {
        toView.alpha = 0.f;
        
        // This animation only affects the alpha.  The views can be set to
        // their final frames now.
        fromView.frame = [transitionContext finalFrameForViewController:fromViewController];
        toView.frame = [transitionContext finalFrameForViewController:toViewController];
    } else {
        // Because our presentation wraps the presented view controller's view
        // in an intermediate view hierarchy, it is more accurate to rely
        // on the current frame of fromView than fromViewInitialFrame as the
        // initial frame.
        toView.frame = [transitionContext finalFrameForViewController:toViewController];
    }
    
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:transitionDuration animations:^{
        if (isPresenting)
            toView.alpha = 1.f;
        else
            fromView.alpha = 0.f;
        
    } completion:^(BOOL finished) {
        // When we complete, tell the transition context
        // passing along the BOOL that indicates whether the transition
        // finished or not.
        BOOL wasCancelled = [transitionContext transitionWasCancelled];
        [transitionContext completeTransition:!wasCancelled];
        
        // Reset the alpha of the dismissed view, in case it will be used
        // elsewhere in the app.
        if (isPresenting == NO)
            fromView.alpha = 1.f;
    }];
}

#pragma mark -
#pragma mark UIViewControllerTransitioningDelegate

//| ----------------------------------------------------------------------------
//  If the modalPresentationStyle of the presented view controller is
//  UIModalPresentationCustom, the system calls this method on the presented
//  view controller's transitioningDelegate to retrieve the presentation
//  controller that will manage the presentation.  If your implementation
//  returns nil, an instance of UIPresentationController is used.
//
- (UIPresentationController*)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    NSAssert(self.presentedViewController == presented, @"You didn't initialize %@ with the correct presentedViewController.  Expected %@, got %@.",
             self, presented, self.presentedViewController);
    
    return self;
}


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
    return self;
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
    return self;
}

@end
