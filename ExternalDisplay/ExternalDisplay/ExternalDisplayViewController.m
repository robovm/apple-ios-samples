/*
     File: ExternalDisplayViewController.m
 Abstract: Basics of how to show content on an external display.
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

#import "ExternalDisplayViewController.h"
#import <unistd.h>

@interface ExternalDisplayViewController()

@property (nonatomic, strong) IBOutlet UITextView *consoleLog;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *presoModeBarButton;
@property (nonatomic, strong) IBOutlet UIViewController *presoModeViewController;
@property (nonatomic, strong) UIPopoverController *presoModePopoverController;
@property (nonatomic, strong) IBOutlet UIImageView *mainView;
@property (nonatomic, strong) IBOutlet UIImageView *extView;
@property (nonatomic, strong) UIWindow *extWindow;
@property (nonatomic, strong) IBOutlet UIView *placeHolderView;

- (IBAction)barButtonAction:(id)sender;

@end

@implementation ExternalDisplayViewController

/*
 
 Support for External Displays and Projectors
 
 iPad, iPhone 4 and later, and iPod touch (4th generation) and later can now be connected to an external display
 through a supported cable. Applications can use this connection to present content in addition to the content
 on the device’s main screen. Depending on the cable, you can output content at up to a 720p (1280 x 720)
 resolution. A resolution of 1024 by 768 resolution may also be available if you prefer to use that aspect ratio.
 
 To display content on an external display, do the following:
 
 1. Use the screens class method of the UIScreen class to determine if an external display is available.
 
 2. If an external screen is available, get the screen object and look at the values in its availableModes
 property. This property contains the configurations supported by the screen.
 
 3. Select the UIScreenMode object corresponding to the desired resolution and assign it to the currentMode
 property of the screen object.
 
 4. Create a new window object (UIWindow) to display your content.
 
 5. Assign the screen object to the screen property of your new window.
 
 6. Configure the window (by adding views or setting up your OpenGL ES rendering context).
 
 7. Show the window.
 
 Important: You should always assign a screen object to your window before you show that window. Although you 
 can change the screen while a window is already visible, doing so is an expensive operation and not recommended.
 Screen mode objects identify a specific resolution supported by the screen. Many screens support multiple
 resolutions, some of which may include different pixel aspect ratios. The decision for which screen mode to use
 should be based on performance and which resolution best meets the needs of your user interface. When you are
 ready to start drawing, use the bounds provided by the UIScreen object to get the proper size for rendering
 your content. The screen’s bounds take into account any aspect ratio data so that you can focus on drawing your content.
 
 If you want to detect when screens are connected and disconnected, you can register to receive screen
 connection and disconnection notifications. For more information about screens and screen notifications, see
 UIScreen Class Reference. For information about screen modes, see UIScreenMode Class Reference.
 
*/


- (void) logMessage:(NSString *)message
{
	self.consoleLog.text = [self.consoleLog.text stringByAppendingString:message];
	
	[self.consoleLog scrollRangeToVisible:NSMakeRange([self.consoleLog.text length], 0)];
}


- (void) logError:(NSError *)error
{
    NSString *message = [NSString stringWithFormat:@"Error: %@ %@\n",
						  [error localizedDescription],
						  [error localizedFailureReason]];
    
	[self logMessage:message];
}


- (IBAction)barButtonAction:(id)sender
{
	if (self.presoModePopoverController == nil)
    {
        Class cls = NSClassFromString(@"UIPopoverController");
        if (cls != nil) {
            UIPopoverController *aPopoverController =
			[[cls alloc] initWithContentViewController:self.presoModeViewController];
			aPopoverController.delegate = self;
			
            self.presoModePopoverController = aPopoverController;
            
            
            [self.presoModePopoverController presentPopoverFromBarButtonItem:self.presoModeBarButton
                                      permittedArrowDirections:UIPopoverArrowDirectionUp
                                                      animated:YES];
        }
    }	
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	self.presoModePopoverController = nil;
}


- (void)externalWindow:(UIWindow*)window
{
	[self logMessage:[NSString stringWithFormat:@"External window %@\n",
								  window]];
	self.extWindow = window;
}


- (void)presoMode:(BOOL)isOn
{
	[self logMessage:[NSString stringWithFormat:@"Preso mode %@\n",
					  isOn ? @"on": @"off"]];
	
	self.extWindow.hidden = YES;
	 
	if (isOn == YES)
    {
		// Show the main view ("1") in the external window
		[self.extView removeFromSuperview];
		[self.extWindow addSubview:self.mainView];
	}
    else {
		// Show the external view ("2") in the external window
		[self.mainView removeFromSuperview];
	    [self.extWindow addSubview:self.extView];
    }

	self.extWindow.hidden = NO;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		self.presoModeViewController.contentSizeForViewInPopover = CGSizeMake(320, 252);
	}
	else {
		CGRect newFrame = CGRectMake(0, 0, self.placeHolderView.frame.size.width, self.placeHolderView.frame.size.height);
        self.presoModeViewController.view.frame = newFrame;
        [self.placeHolderView addSubview:self.presoModeViewController.view];
        [self addChildViewController:self.presoModeViewController];
        [self.presoModeViewController didMoveToParentViewController:self];
	}
}

@end
