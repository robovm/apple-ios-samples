/*
     File: MainViewController.m
 Abstract: The application's main (initial) view controller.
 
  Version: 1.12
 
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
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

