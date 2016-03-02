/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The interaction controller for the Swipe demo.  Tracks a UIScreenEdgePanGestureRecognizer
  from a specified screen edge and derives the completion percentage for the
  transition.
 */

#import "AAPLSwipeTransitionInteractionController.h"

@interface AAPLSwipeTransitionInteractionController ()
@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, strong, readonly) UIScreenEdgePanGestureRecognizer *gestureRecognizer;
@property (nonatomic, readonly) UIRectEdge edge;
@end


@implementation AAPLSwipeTransitionInteractionController

//| ----------------------------------------------------------------------------
- (instancetype)initWithGestureRecognizer:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer edgeForDragging:(UIRectEdge)edge
{
    NSAssert(edge == UIRectEdgeTop || edge == UIRectEdgeBottom ||
             edge == UIRectEdgeLeft || edge == UIRectEdgeRight,
             @"edgeForDragging must be one of UIRectEdgeTop, UIRectEdgeBottom, UIRectEdgeLeft, or UIRectEdgeRight.");
    
    self = [super init];
    if (self)
    {
        _gestureRecognizer = gestureRecognizer;
        _edge = edge;
        
        // Add self as an observer of the gesture recognizer so that this
        // object receives updates as the user moves their finger.
        [_gestureRecognizer addTarget:self action:@selector(gestureRecognizeDidUpdate:)];
    }
    return self;
}


//| ----------------------------------------------------------------------------
- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Use -initWithGestureRecognizer:edgeForDragging:" userInfo:nil];
}


//| ----------------------------------------------------------------------------
- (void)dealloc
{
    [self.gestureRecognizer removeTarget:self action:@selector(gestureRecognizeDidUpdate:)];
}


//| ----------------------------------------------------------------------------
- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Save the transitionContext for later.
    self.transitionContext = transitionContext;
    
    [super startInteractiveTransition:transitionContext];
}


//| ----------------------------------------------------------------------------
//! Returns the offset of the pan gesture recognizer from the edge of the
//! screen as a percentage of the transition container view's width or height.
//! This is the percent completed for the interactive transition.
//
- (CGFloat)percentForGesture:(UIScreenEdgePanGestureRecognizer *)gesture
{
    // Because view controllers will be sliding on and off screen as part
    // of the animation, we want to base our calculations in the coordinate
    // space of the view that will not be moving: the containerView of the
    // transition context.
    UIView *transitionContainerView = self.transitionContext.containerView;
    
    CGPoint locationInSourceView = [gesture locationInView:transitionContainerView];
    
    // Figure out what percentage we've gone.

    CGFloat width = CGRectGetWidth(transitionContainerView.bounds);
    CGFloat height = CGRectGetHeight(transitionContainerView.bounds);
    
    // Return an appropriate percentage based on which edge we're dragging
    // from.
    if (self.edge == UIRectEdgeRight)
        return (width - locationInSourceView.x) / width;
    else if (self.edge == UIRectEdgeLeft)
        return locationInSourceView.x / width;
    else if (self.edge == UIRectEdgeBottom)
        return (height - locationInSourceView.y) / height;
    else if (self.edge == UIRectEdgeTop)
        return locationInSourceView.y / height;
    else
        return 0.f;
}


//| ----------------------------------------------------------------------------
//! Action method for the gestureRecognizer.
//
- (IBAction)gestureRecognizeDidUpdate:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            // The Began state is handled by the view controllers.  In response
            // to the gesture recognizer transitioning to this state, they
            // will trigger the presentation or dismissal.
            break;
        case UIGestureRecognizerStateChanged:
            // We have been dragging! Update the transition context accordingly.
            [self updateInteractiveTransition:[self percentForGesture:gestureRecognizer]];
            break;
        case UIGestureRecognizerStateEnded:
            // Dragging has finished.
            // Complete or cancel, depending on how far we've dragged.
            if ([self percentForGesture:gestureRecognizer] >= 0.5f)
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
