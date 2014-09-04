/*
     File: PortraitViewController.m
 Abstract: The application view controller used when the device is in portrait 
 orientation.
 
  Version: 1.3
 
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

#import "PortraitViewController.h"

@implementation PortraitViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    // Instruct the system to generate notifications when the device orientation
    // changes.  This view controller will not receive calls to
    // willRotateToInterfaceOrientation:duration: and
    // didRotateFromInterfaceOrientation: because the system will never attempt
    // to rotate this view controller.  Thus, orientation notifications are the
    // only way to know the orientation changed.
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

#pragma mark - 
#pragma mark Rotation

//| ----------------------------------------------------------------------------
//! Handler for the UIDeviceOrientationDidChangeNotification.
//
- (void)onDeviceOrientationDidChange:(NSNotification *)notification
{
    // A delay must be added here, otherwise the new view will be swapped in
	// too quickly resulting in an animation glitch
    [self performSelector:@selector(updateLandscapeView) withObject:nil afterDelay:0];
}


//| ----------------------------------------------------------------------------
//  This method contains the logic for presenting and dismissing the
//  LandscapeViewController depending on the current device orientation and
//  whether the LandscapeViewController is currently presented.
//
- (void)updateLandscapeView
{
    // Get the device's current orientation.  By the time the
    // UIDeviceOrientationDidChangeNotification has been posted, this value
    // reflects the new orientation of the device.
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    if (UIDeviceOrientationIsLandscape(deviceOrientation) && self.presentedViewController == nil)
    // Only take action if the orientation is landscape and
    // presentedViewController is nil (no view controller is presented).  The
    // later check prevents this view controller from trying to present
    // landscapeViewController again if the device rotates from landscape to
    // landscape (the user turns the device 180 degrees).
	{
        // Trigger the segue to present LandscapeViewController modally.
        [self performSegueWithIdentifier:@"PresentLandscapeViewControllerSegue" sender:self];
    }
	else if (deviceOrientation == UIDeviceOrientationPortrait && self.presentedViewController != nil)
    // Only take action if the orientation is portrait and
    // presentedViewController is not nil (a view controller is presented).
	{
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}


//| ----------------------------------------------------------------------------
//  Support only portrait orientation.
//
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - 
#pragma mark Cleanup

//| ----------------------------------------------------------------------------
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Instruct the system to stop generating device orientation notifications.
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

@end
