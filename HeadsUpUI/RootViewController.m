/*
     File: RootViewController.m
 Abstract: The main view controller of this app.
  Version: 1.2
 
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

#import "RootViewController.h"
#import "HoverView.h"

@interface RootViewController ()
// Outlet to hold the HoverView instance loaded from HoverView.xib
@property (nonatomic, strong) IBOutlet HoverView *hoverView;
@property (nonatomic, strong) NSTimer *hoverViewInactiveTimer;
@end


@implementation RootViewController

#pragma mark - View Lifecycle

// -------------------------------------------------------------------------------
//	viewDidLoad
// -------------------------------------------------------------------------------
- (void)viewDidLoad
{
    // Load the hoverView from HoverView.xib
    UINib *hoverViewXib = [UINib nibWithNibName:@"HoverView" bundle:nil];
    [hoverViewXib instantiateWithOwner:self options:nil];
    
    [self.view addSubview:self.hoverView];
    self.hoverView.alpha = 0.0f;
}

// -------------------------------------------------------------------------------
//	viewDidLayoutSubviews
// -------------------------------------------------------------------------------
- (void)viewDidLayoutSubviews
{
    // Position hoverView in the lower center of the view.
	CGRect frame = self.hoverView.frame;
	frame.origin.x = round((self.view.bounds.size.width - frame.size.width) / 2.0);
	frame.origin.y = self.view.bounds.size.height - 100;
	self.hoverView.frame = frame;
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
// -------------------------------------------------------------------------------
//	viewDidUnload
//  iOS 6 no longer unloads views under low memory conditions so this method
//  will not be called.  On iOS 5, unload anything that will be recreated in
//  viewDidLoad.
// -------------------------------------------------------------------------------
- (void)viewDidUnload
{
    [self.hoverView removeFromSuperview];
    self.hoverView = nil;
}
#endif

#pragma mark - Rotation

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
// -------------------------------------------------------------------------------
//	shouldAutorotateToInterfaceOrientation:
//  Disable rotation on iOS 5.x and earlier.  Note, for iOS 6.0 and later all you
//  need is "UISupportedInterfaceOrientations" defined in your Info.plist
// -------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#endif

#pragma mark - Actions

// -------------------------------------------------------------------------------
//	showHoverView:
//  Helper method that animates the hoverView into or out of view deending on
//  the value of the 'show' parameter.  If animating the hoverView into view,
//  it starts a timer to hide the hoverView after a few seconds of inactivity.
// -------------------------------------------------------------------------------
- (void)showHoverView:(BOOL)show
{
    // Clear any pending actions.
    [self.hoverViewInactiveTimer invalidate];
    self.hoverViewInactiveTimer = nil;
    
    [UIView animateWithDuration:0.40 animations:^{
        
        if (show)
        {
            // Fade the hoverView into view by affecting its alpha.
            self.hoverView.alpha = 1.0f;
            
            // Start the timeout timer for automatically hiding HoverView
            self.hoverViewInactiveTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                                           target:self
                                                                         selector:@selector(timerFired:)
                                                                         userInfo:nil
                                                                          repeats:NO];
        }
        else
        {
            // Fade the hoverView out of view by affecting its alpha.
            self.hoverView.alpha = 0.0f;
        }
        
    }];
}

// -------------------------------------------------------------------------------
//	timerFired:
//  Called when the hoverViewInactiveTimer fires.
// -------------------------------------------------------------------------------
- (void)timerFired:(NSTimer *)timer
{
	// Time has passed, hide the HoverView.
	[self showHoverView: NO];
}

// -------------------------------------------------------------------------------
//	touchesEnded:withEvent:
//  Called when the user touches our view.
// -------------------------------------------------------------------------------
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[touches anyObject] tapCount] == 1)
        [self showHoverView:(self.hoverView.alpha != 1.0)];
}

// -------------------------------------------------------------------------------
//	leftAction:
//  IBAction for the pause button.
// -------------------------------------------------------------------------------
- (IBAction)leftAction:(id)sender
{
	// user touched the left button in HoverView
	[self showHoverView:NO];
}

// -------------------------------------------------------------------------------
//	rightAction:
//  IBAction for the play button.
// -------------------------------------------------------------------------------
- (IBAction)rightAction:(id)sender
{
	[self showHoverView:NO];
}

@end

