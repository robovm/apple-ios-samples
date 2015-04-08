/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The application's main (initial) view controller.
 */

#import "MainViewController.h"

@interface MainViewController () <UIActionSheetDelegate>
@end


@implementation MainViewController

//| ----------------------------------------------------------------------------
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


//| ----------------------------------------------------------------------------
//  Unwind action that is targeted by the demos which present a modal view
//  controller, to return to the main screen.
//
- (IBAction)unwindToMainViewController:(UIStoryboardSegue*)sender
{ }

#pragma mark -
#pragma mark Style Action Sheet

//| ----------------------------------------------------------------------------
- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Change the navigation bar style
	switch (buttonIndex)
	{
		case 0: // "Default"
			self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
            // Bars are translucent by default.
            self.navigationController.navigationBar.translucent = YES;
            // Reset the bar's tint color to the system default.
            self.navigationController.navigationBar.tintColor = nil;
			break;
		case 1: // "Black Opaque"
			self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
            self.navigationController.navigationBar.translucent = NO;
            self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
			break;
		case 2: // "Black Translucent"
			self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
            self.navigationController.navigationBar.translucent = YES;
            self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
			break;
	}
    
    // Ask the system to re-query our -preferredStatusBarStyle.
    [self setNeedsStatusBarAppearanceUpdate];
}


//| ----------------------------------------------------------------------------
//! IBAction for the 'Style' bar button item.
//
- (IBAction)styleAction:(id)sender
{
	UIActionSheet *styleAlert = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose a UIBarStyle:", @"")
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:NSLocalizedString(@"Default", @""),
																	 NSLocalizedString(@"Black Opaque", @""),
																	 NSLocalizedString(@"Black Translucent", @""),
																	 nil];
	
	// use the same style as the nav bar
	styleAlert.actionSheetStyle = (UIActionSheetStyle)self.navigationController.navigationBar.barStyle;
	
	[styleAlert showInView:self.view];
}

@end

