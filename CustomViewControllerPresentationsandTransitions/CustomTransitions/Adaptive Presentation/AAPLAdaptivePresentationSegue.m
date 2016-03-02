/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import "AAPLAdaptivePresentationSegue.h"
#import "AAPLAdaptivePresentationController.h"

@implementation AAPLAdaptivePresentationSegue

//| ----------------------------------------------------------------------------
- (void)perform
{
    UIViewController *sourceViewController = self.destinationViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    
    // For presentations which will use a custom presentation controller,
    // it is possible for that presentation controller to also be the
    // transitioningDelegate.
    //
    // transitioningDelegate does not hold a strong reference to its
    // destination object.  To prevent presentationController from being
    // released prior to calling -presentViewController:animated:completion:
    // the NS_VALID_UNTIL_END_OF_SCOPE attribute is appended to the declaration.
    AAPLAdaptivePresentationController *presentationController NS_VALID_UNTIL_END_OF_SCOPE;
    
    presentationController = [[AAPLAdaptivePresentationController alloc] initWithPresentedViewController:destinationViewController presentingViewController:sourceViewController];
    
    destinationViewController.transitioningDelegate = presentationController;
    
    [self.sourceViewController presentViewController:destinationViewController animated:YES completion:NULL];
}

@end
