/*
     File: APLTransitionManager.m
 Abstract: Responsible for managing the transition between the two collection views via the pinch gesture recognizer.
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "APLTransitionManager.h"
#import "APLTransitionLayout.h"

@interface APLTransitionManager ()

@property (nonatomic) APLTransitionLayout *transitionLayout;
@property (nonatomic) id <UIViewControllerContextTransitioning> context;
@property (nonatomic) CGFloat initialPinchDistance;
@property (nonatomic) CGPoint initialPinchPoint;

@end

#pragma mark -

@implementation APLTransitionManager 

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
{
    self = [super init];
    if (self != nil)
    {
        // setup our pinch gesture:
        //  pinch in closes photos down into a stack,
        //  pinch out expands the photos intoa  grid
        //
        UIPinchGestureRecognizer *pinchGesture =
            [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        [collectionView addGestureRecognizer:pinchGesture];
        
        self.collectionView = collectionView;
    }
    return self;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // transition animation time between grid and stack layout
    return 1.0;
}

// required method for view controller transitions, called when the system needs to set up
// the interactive portions of a view controller transition and start the animations
//
- (void)startInteractiveTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    self.context = transitionContext;
    
    UICollectionViewController *fromCollectionViewController =
        (UICollectionViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UICollectionViewController *toCollectionViewController =
        (UICollectionViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:[toCollectionViewController view]];
    
    self.transitionLayout = (APLTransitionLayout *)[fromCollectionViewController.collectionView startInteractiveTransitionToCollectionViewLayout:toCollectionViewController.collectionViewLayout completion:^(BOOL didFinish, BOOL didComplete) {
            [self.context completeTransition:didComplete];
            self.transitionLayout = nil;
            self.context = nil;
            self.hasActiveInteraction = NO;
        }];
}

- (void)updateWithProgress:(CGFloat)progress andOffset:(UIOffset)offset
{
    if (self.context != nil &&  // we must have a valid context for updates
        ((progress != self.transitionLayout.transitionProgress) || !UIOffsetEqualToOffset(offset, self.transitionLayout.offset)))
    {
        [self.transitionLayout setOffset:offset];
        [self.transitionLayout setTransitionProgress:progress];
        [self.transitionLayout invalidateLayout];
        [self.context updateInteractiveTransition:progress];
    }
}

// called by our pinch gesture recognizer when the gesture has finished or cancelled, which
// in turn is responsible for finishing or cancelling the transition.
//
- (void)endInteractionWithSuccess:(BOOL)success
{
    if (self.context == nil)
    {
        self.hasActiveInteraction = NO;
    }
    // allow for the transition to finish when it's progress has started as a threshold of 10%,
    // if you want to require the pinch gesture with a wider threshold, change it it a value closer to 1.0
    //
    else if ((self.transitionLayout.transitionProgress > 0.1) && success)
    {
        [self.collectionView finishInteractiveTransition];
        [self.context finishInteractiveTransition];
    }
    else
    {
        [self.collectionView cancelInteractiveTransition];
        [self.context cancelInteractiveTransition];
    }
}

// action method for our pinch gesture recognizer
//
- (void)handlePinch:(UIPinchGestureRecognizer *)sender
{
    // here we want to end the transition interaction if the user stops or finishes the pinch gesture
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [self endInteractionWithSuccess:YES];
    }
    else if (sender.state == UIGestureRecognizerStateCancelled)
    {
        [self endInteractionWithSuccess:NO];
    }
    else if (sender.numberOfTouches == 2)
    {
        // here we expect two finger touch
        CGPoint point;      // the main touch point
        CGPoint point1;     // location of touch #1
        CGPoint point2;     // location of touch #2
        CGFloat distance;   // computed distance between both touches

        // return the locations of each gesture’s touches in the local coordinate system of a given view
        point1 = [sender locationOfTouch:0 inView:sender.view];
        point2 = [sender locationOfTouch:1 inView:sender.view];
        distance = sqrt((point1.x - point2.x) * (point1.x - point2.x) + (point1.y - point2.y) * (point1.y - point2.y));
        
        // get the main touch point
        point = [sender locationInView:sender.view];

        if (sender.state == UIGestureRecognizerStateBegan)
        {
            // start the pinch in our out
            if (!self.hasActiveInteraction)
            {
                self.initialPinchDistance = distance;
                self.initialPinchPoint = point;
                self.hasActiveInteraction = YES;    // the transition is in active motion
                [self.delegate interactionBeganAtPoint:point];
            }
        }
        
        if (self.hasActiveInteraction)
        {
            if (sender.state == UIGestureRecognizerStateChanged)
            {
                // update the progress of the transtition as the user continues to pinch
                CGFloat offsetX = point.x - self.initialPinchPoint.x;
                CGFloat offsetY = point.y - self.initialPinchPoint.y;
                UIOffset offsetToUse = UIOffsetMake(offsetX, offsetY);

                CGFloat distanceDelta = distance - self.initialPinchDistance;
                if (self.navigationOperation == UINavigationControllerOperationPop)
                {
                    distanceDelta = -distanceDelta;
                }
                CGFloat dimension = sqrt(self.collectionView.bounds.size.width * self.collectionView.bounds.size.width + self.collectionView.bounds.size.height * self.collectionView.bounds.size.height);
                CGFloat progress = MAX(MIN((distanceDelta / dimension), 1.0), 0.0);
                
                // tell our UICollectionViewTransitionLayout subclass (transitionLayout)
                // the progress state of the pinch gesture
                //
                [self updateWithProgress:progress andOffset:offsetToUse];
            }
        }
    }
}

@end
