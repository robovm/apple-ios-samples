/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The interaction controller for the Slide demo.
 */

#import "AAPLSlideTransitionInteractionController.h"

@interface AAPLSlideTransitionInteractionController ()
@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *gestureRecognizer;
@property (nonatomic, readwrite) CGPoint initialLocationInContainerView;
@property (nonatomic, readwrite) CGPoint initialTranslationInContainerView;
@end


@implementation AAPLSlideTransitionInteractionController

//| ----------------------------------------------------------------------------
- (instancetype)initWithGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer
{
    self = [super init];
    if (self)
    {
        _gestureRecognizer = gestureRecognizer;
        
        // Add self as an observer of the gesture recognizer so that this
        // object receives updates as the user moves their finger.
        [_gestureRecognizer addTarget:self action:@selector(gestureRecognizeDidUpdate:)];
    }
    return self;
}


//| ----------------------------------------------------------------------------
- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Use -initWithGestureRecognizer:" userInfo:nil];
}


//| ----------------------------------------------------------------------------
- (void)dealloc
{
    [self.gestureRecognizer removeTarget:self action:@selector(gestureRecognizeDidUpdate:)];
}


//| ----------------------------------------------------------------------------
- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Save the transitionContext, initial location, and the translation within
    // the containing view.
    self.transitionContext = transitionContext;
    self.initialLocationInContainerView = [self.gestureRecognizer locationInView:transitionContext.containerView];
    self.initialTranslationInContainerView = [self.gestureRecognizer translationInView:transitionContext.containerView];
    
    [super startInteractiveTransition:transitionContext];
}


//| ----------------------------------------------------------------------------
//! Returns the offset of the pan gesture recognizer from its initial location
//! as a percentage of the transition container view's width.  This is
//! the percent completed for the interactive transition.
//
- (CGFloat)percentForGesture:(UIPanGestureRecognizer *)gesture
{
    UIView *transitionContainerView = self.transitionContext.containerView;
    
    CGPoint translationInContainerView = [gesture translationInView:transitionContainerView];
    
    // If the direction of the current touch along the horizontal axis does not
    // match the initial direction, then the current touch position along
    // the horizontal axis has crossed over the initial position.  See the
    // comment in the -beginInteractiveTransitionIfPossible: method of
    // AAPLSlideTransitionDelegate.
    if ((translationInContainerView.x > 0.f && self.initialTranslationInContainerView.x < 0.f) ||
        (translationInContainerView.x < 0.f && self.initialTranslationInContainerView.x > 0.f))
        return -1.f;
    
    // Figure out what percentage we've traveled.
    return fabs(translationInContainerView.x) / CGRectGetWidth(transitionContainerView.bounds);
}


//| ----------------------------------------------------------------------------
//! Action method for the gestureRecognizer.
//
- (IBAction)gestureRecognizeDidUpdate:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            // The Began state is handled by AAPLSlideTransitionDelegate.  In
            // response to the gesture recognizer transitioning to this state,
            // it will trigger the transition.
            break;
        case UIGestureRecognizerStateChanged:
            // -percentForGesture returns -1.f if the current position of the
            // touch along the horizontal axis has crossed over the initial
            // position.  See the comment in the
            // -beginInteractiveTransitionIfPossible: method of
            // AAPLSlideTransitionDelegate for details.
            if ([self percentForGesture:gestureRecognizer] < 0.f) {
                [self cancelInteractiveTransition];
                // Need to remove our action from the gesture recognizer to
                // ensure it will not be called again before deallocation.
                [self.gestureRecognizer removeTarget:self action:@selector(gestureRecognizeDidUpdate:)];
            } else {
                // We have been dragging! Update the transition context
                // accordingly.
                [self updateInteractiveTransition:[self percentForGesture:gestureRecognizer]];
            }
            break;
        case UIGestureRecognizerStateEnded:
            // Dragging has finished.
            // Complete or cancel, depending on how far we've dragged.
            if ([self percentForGesture:gestureRecognizer] >= 0.4f)
                [self finishInteractiveTransition];
            else
                [self cancelInteractiveTransition];
            break;
        default:
            // Something happened. cancel the transition.
            [self cancelInteractiveTransition];
            break;
    }
}

@end
