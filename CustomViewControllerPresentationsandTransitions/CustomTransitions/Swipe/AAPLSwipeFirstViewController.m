/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The initial view controller for the Swipe demo.
 */

#import "AAPLSwipeFirstViewController.h"
#import "AAPLSwipeTransitionDelegate.h"

@interface AAPLSwipeFirstViewController ()
@property (nonatomic, strong) AAPLSwipeTransitionDelegate *customTransitionDelegate;
@end


@implementation AAPLSwipeFirstViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This gesture recognizer could be defined in the storyboard but is
    // instead created in code for clarity.
    UIScreenEdgePanGestureRecognizer *interactiveTransitionRecognizer;
    interactiveTransitionRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(interactiveTransitionRecognizerAction:)];
    interactiveTransitionRecognizer.edges = UIRectEdgeRight;
    [self.view addGestureRecognizer:interactiveTransitionRecognizer];
}


//| ----------------------------------------------------------------------------
//! Action method for the interactiveTransitionRecognizer.
//
- (IBAction)interactiveTransitionRecognizerAction:(UIScreenEdgePanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
        [self performSegueWithIdentifier:@"CustomTransition" sender:sender];
    
    // Remaining cases are handled by the
    // AAPLSwipeTransitionInteractionController.
}


//| ----------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"CustomTransition"])
    {
        UIViewController *destinationViewController = segue.destinationViewController;
        
        // Unlike in the Cross Dissolve demo, we use a separate object as the
        // transition delegate rather then (our)self.  This promotes
        // 'separation of concerns' as AAPLSwipeTransitionDelegate will
        // handle pairing the correct animation controller and interaction
        // controller for the presentation.
        AAPLSwipeTransitionDelegate *transitionDelegate = self.customTransitionDelegate;
        
        // If this will be an interactive presentation, pass the gesture
        // recognizer along to our AAPLSwipeTransitionDelegate instance
        // so it can return the necessary
        // <UIViewControllerInteractiveTransitioning> for the presentation.
        if ([sender isKindOfClass:UIGestureRecognizer.class])
            transitionDelegate.gestureRecognizer = sender;
        else
            transitionDelegate.gestureRecognizer = nil;
        
        // Set the edge of the screen to present the incoming view controller
        // from.  This will match the edge we configured the
        // UIScreenEdgePanGestureRecognizer with previously.
        //
        // NOTE: We can not retrieve the value of our gesture recognizer's
        //       configured edges because prior to iOS 8.3
        //       UIScreenEdgePanGestureRecognizer would always return
        //       UIRectEdgeNone when querying its edges property.
        transitionDelegate.targetEdge = UIRectEdgeRight;
        
        // Note that the view controller does not hold a strong reference to
        // its transitioningDelegate.  If you instantiate a separate object
        // to be the transitioningDelegate, ensure that you hold a strong
        // reference to that object.
        destinationViewController.transitioningDelegate = transitionDelegate;
        
        // Setting the modalPresentationStyle to FullScreen enables the
        // <ContextTransitioning> to provide more accurate initial and final
        // frames of the participating view controllers.
        destinationViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    }
}


//| ----------------------------------------------------------------------------
//  Custom implementation of the getter for the customTransitionDelegate
//  property.  Lazily creates an instance of AAPLSwipeTransitionDelegate.
//
- (AAPLSwipeTransitionDelegate *)customTransitionDelegate
{
    if (_customTransitionDelegate == nil)
        _customTransitionDelegate = [[AAPLSwipeTransitionDelegate alloc] init];
    
    return _customTransitionDelegate;
}

#pragma mark -
#pragma mark Unwind Actions

//| ----------------------------------------------------------------------------
//! Action for unwinding from AAPLSwipeSecondViewController.
//
- (IBAction)unwindToSwipeFirstViewController:(UIStoryboardSegue *)sender
{ }

@end
