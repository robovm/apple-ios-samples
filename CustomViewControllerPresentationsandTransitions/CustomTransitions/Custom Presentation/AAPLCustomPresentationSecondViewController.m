/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The second view controller for the Custom Presentation demo.
 */

#import "AAPLCustomPresentationSecondViewController.h"

//  NOTE: The third view controller is presented with a modalPresentationStyle
//        of UIModalPresentationOverFullScreen, rather than the default
//        UIModalPresentationFullScreen (configured in the storyboard).
//
//        When a fullscreen view controller is presented (the corresponding
//        presentation controller's -shouldRemovePresentersView returns YES),
//        the presentation controller temporarily relocates the
//        presenting view controller's view to the presentation controller's
//        containerView.  When the fullscreen view controller is dismissed,
//        the presentation controller places the presenting view controller's
//        view back in its previous superview.
//
//        The relocation of the presenting view controller's view poses a
//        problem in this example because only the presenting view controller's
//        view is relocated, not the intermediate view hierarchy we setup
//        to apply the rounded corner and shadow effect.  If you modify the
//        modalPresentationStyle of Third View Controller in the storyboard,
//        you may notice that during the presentation and dismissal animation
//        for Third View Controller, the rounded corner and shadow effect is
//        lost.
//
//        The workaround is to use the UIModalPresentationOverFullScreen
//        presentation style.  This presentation style is similar to
//        UIModalPresentationFullScreen but the presentation controller for
//        this presentation style overrides -shouldRemovePresentersView to
//        return NO, avoiding the above problem.

@interface AAPLCustomPresentationSecondViewController ()
@property (nonatomic, weak) IBOutlet UISlider *slider;
@end


@implementation AAPLCustomPresentationSecondViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updatePreferredContentSizeWithTraitCollection:self.traitCollection];
    
    // NOTE: View controllers presented with custom presentation controllers
    //       do not assume control of the status bar appearance by default
    //       (their -preferredStatusBarStyle and -prefersStatusBarHidden
    //       methods are not called).  You can override this behavior by
    //       setting the value of the presented view controller's
    //       modalPresentationCapturesStatusBarAppearance property to YES.
    /* self.modalPresentationCapturesStatusBarAppearance = YES; */
}


//| ----------------------------------------------------------------------------
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    // When the current trait collection changes (e.g. the device rotates),
    // update the preferredContentSize.
    [self updatePreferredContentSizeWithTraitCollection:newCollection];
}


//| ----------------------------------------------------------------------------
//! Updates the receiver's preferredContentSize based on the verticalSizeClass
//! of the provided \a traitCollection.
//
- (void)updatePreferredContentSizeWithTraitCollection:(UITraitCollection *)traitCollection
{
    self.preferredContentSize = CGSizeMake(self.view.bounds.size.width, traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact ? 270 : 420);
    
    // To demonstrate how a presentation controller can dynamically respond
    // to changes to its presented view controller's preferredContentSize,
    // this view controller exposes a slider.  Dragging this slider updates
    // the preferredContentSize of this view controller in real time.
    //
    // Update the slider with appropriate min/max values and reset the
    // current value to reflect the changed preferredContentSize.
    self.slider.maximumValue = self.preferredContentSize.height;
    self.slider.minimumValue = 220.f;
    self.slider.value = self.slider.maximumValue;
}


//| ----------------------------------------------------------------------------
- (IBAction)sliderValueChange:(UISlider*)sender
{
    self.preferredContentSize = CGSizeMake(self.view.bounds.size.width, sender.value);
}

#pragma mark -
#pragma mark Unwind Actions

//| ----------------------------------------------------------------------------
//! Action for unwinding from the presented view controller (C).
//
- (IBAction)unwindToCustomPresentationSecondViewController:(UIStoryboardSegue *)sender
{ }

@end
