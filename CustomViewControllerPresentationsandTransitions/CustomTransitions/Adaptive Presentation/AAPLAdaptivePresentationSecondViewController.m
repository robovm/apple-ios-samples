/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The second view controller for the Adaptive Presentation demo.
 */

#import "AAPLAdaptivePresentationSecondViewController.h"
#import "AAPLAdaptivePresentationController.h"

@interface AAPLAdaptivePresentationSecondViewController () <UIAdaptivePresentationControllerDelegate>
@end


@implementation AAPLAdaptivePresentationSecondViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // In the regular environment, AAPLAdaptivePresentationController displays
    // a close button for the presented view controller.  For the compact
    // environment, a 'dismiss' button is added to this view controller's
    // navigationItem.  This button will be picked up and displayed in the
    // navigation bar of the navigation controller returned by
    // -presentationController:viewControllerForAdaptivePresentationStyle:
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithTitle:@"Dismiss" style:UIBarButtonItemStylePlain target:self action:@selector(dismissButtonAction:)];
    self.navigationItem.leftBarButtonItem = dismissButton;
}


//| ----------------------------------------------------------------------------
- (void)setTransitioningDelegate:(id<UIViewControllerTransitioningDelegate>)transitioningDelegate
{
    [super setTransitioningDelegate:transitioningDelegate];
    
    // For an adaptive presentation, the presentation controller's delegate
    // must be configured prior to invoking
    // -presentViewController:animated:completion:.  This ensures the
    // presentation is able to properly adapt if the initial presentation
    // environment is compact.
    self.presentationController.delegate = self;
}


//| ----------------------------------------------------------------------------
- (IBAction)dismissButtonAction:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"unwindToFirstViewController" sender:sender];
}

#pragma mark -
#pragma mark UIAdaptivePresentationControllerDelegate

//| ----------------------------------------------------------------------------
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    // An adaptive presentation may only fallback to
    // UIModalPresentationFullScreen or UIModalPresentationOverFullScreen
    // in the horizontally compact environment.  Other presentation styles
    // are interpreted as UIModalPresentationNone - no adaptation occurs.
    return UIModalPresentationFullScreen;
}


//| ----------------------------------------------------------------------------
- (UIViewController*)presentationController:(UIPresentationController *)controller viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style
{
    return [[UINavigationController alloc] initWithRootViewController:controller.presentedViewController];
}

@end
