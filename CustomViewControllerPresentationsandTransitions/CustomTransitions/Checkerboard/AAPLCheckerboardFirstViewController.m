/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The initial view controller for the Checkerboard demo.
 */

#import "AAPLCheckerboardFirstViewController.h"
#import "AAPLCheckerboardTransitionAnimator.h"

@interface AAPLCheckerboardFirstViewController () <UINavigationControllerDelegate>
@end


@implementation AAPLCheckerboardFirstViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.delegate = self;
}

#pragma mark -
#pragma mark UINavigationControllerDelegate

//| ----------------------------------------------------------------------------
//  The navigation controller tries to invoke this method on its delegate to
//  retrieve an animator object to be used for animating the transition to the
//  incoming view controller.  Your implementation is expected to return an
//  object that conforms to the UIViewControllerAnimatedTransitioning protocol,
//  or nil if the transition should use the navigation controller's default
//  push/pop animation.
//
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    return [AAPLCheckerboardTransitionAnimator new];
}

@end
