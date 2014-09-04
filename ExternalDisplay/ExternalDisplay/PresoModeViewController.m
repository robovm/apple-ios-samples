/*
     File: PresoModeViewController.m
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

#import "PresoModeViewController.h"
#import <unistd.h>

@interface PresoModeViewController()

@property (nonatomic, strong) id <PresoModeViewDelegate> pmvDelegate;
@property (nonatomic, strong) UIScreen *extScreen;
@property (nonatomic, strong) UIWindow *extWindow;
@property (nonatomic, strong) IBOutlet UILabel *toggleLabel;
@property (nonatomic, strong) IBOutlet UISwitch	*toggleSwitch;
@property (nonatomic, strong) IBOutlet UIPickerView	*modePicker;
@property (nonatomic, strong) IBOutlet UIButton	*modeSetButton;
@property (nonatomic, strong) NSArray *availableModes;

- (IBAction)switchAction:(id)sender;
- (IBAction)buttonAction:(id)sender;

@end

@implementation PresoModeViewController

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


- (IBAction)switchAction:(id)sender
{
    assert(self.extWindow != nil);
	
	[self.pmvDelegate presoMode:[sender isOn]];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	return 140.0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 46.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	NSInteger rows = [self.availableModes count];
	return rows;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	UIScreenMode *mode = (self.availableModes)[row];
	
	if (mode != nil) {
		uint32_t width = mode.size.width;
		uint32_t height = mode.size.height;
		
		return [NSString stringWithFormat:@"%d x %d", width, height];
	}
	else {
		return [NSString stringWithFormat:@"%d", row];
	}
}

- (IBAction)buttonAction:(id)sender
{
	NSInteger selectedRow = [self.modePicker selectedRowInComponent:0];
	
	self.extScreen.currentMode = (self.availableModes)[selectedRow];
		
	if (self.extWindow == nil || !CGRectEqualToRect(self.extWindow.bounds, [self.extScreen bounds])) {
		// Size of window has actually changed
		
		// 4.
		self.extWindow = [[UIWindow alloc] initWithFrame:[self.extScreen bounds]];
	
		// 5.
		self.extWindow.screen = self.extScreen;
		
		UIView *view = [[UIView alloc] initWithFrame:[self.extWindow frame]];
		view.backgroundColor = [UIColor whiteColor];
		
		[self.pmvDelegate logMessage:[NSString stringWithFormat:@"Background view: %@.\n", view]];

		[self.extWindow addSubview:view];

		// 6.
		
		// 7.
		[self.extWindow makeKeyAndVisible];
		
		// Inform delegate that the external window has been created.
		// 
		// NOTE: we ensure that the external window is sent to the delegate before
		// the preso mode is sent.
		
		[self.pmvDelegate externalWindow:self.extWindow];
	
		// Enable preso mode option
		self.toggleLabel.enabled = YES;
		self.toggleSwitch.enabled = YES;
		
		[self switchAction:self.toggleSwitch];
	}
}


- (void)screenDidChange:(NSNotification *)notification
{
	NSArray			*screens;
	UIScreen		*aScreen;
	UIScreenMode	*mode;
	
	// 1.	
	
	// Log the current screens and display modes
	screens = [UIScreen screens];
	
	[self.pmvDelegate logMessage:[NSString stringWithFormat:@"Device has %d screen(s).\n",
					  [screens count]]];
	
	uint32_t screenNum = 1;
	for (aScreen in screens) {			  
		NSArray *displayModes;
		
		[self.pmvDelegate logMessage:[NSString stringWithFormat:@"\tScreen %d\n",
						  screenNum]];
		
		displayModes = [aScreen availableModes];
		for (mode in displayModes) {
			[self.pmvDelegate logMessage:[NSString stringWithFormat:@"\t\tScreen mode: %@\n",
							  mode]];
		}
		
		screenNum++;
	}
	
	NSUInteger screenCount = [screens count];
	
	if (screenCount > 1) {
		// 2.
		
		// Select first external screen
		self.extScreen = screens[1];
		self.availableModes = [self.extScreen availableModes];
		
		// Update picker with display modes
		[self.modePicker reloadAllComponents];
		
		// Enable mode set option
		self.modeSetButton.enabled = YES;
		
		// Set initial display mode to highest resolution
		[self.modePicker selectRow:([self.modePicker numberOfRowsInComponent:0] - 1) inComponent:0 animated:NO];
		[self buttonAction:self.modeSetButton];
	}
	else {
		// Release external screen and window
		self.extScreen = nil;
		
		self.extWindow = nil;
		self.availableModes = nil;
		
		[self.pmvDelegate externalWindow:self.extWindow];
		
		// Clear out picker
		[self.modePicker reloadAllComponents];
		
		// Disable mode set option
		self.modeSetButton.enabled = NO;
		
		// Disable display toggle option
		self.toggleLabel.enabled = NO;
		self.toggleSwitch.enabled = NO;
	}
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	// No notifications are sent for screens that are present when the app is launched.
	[self screenDidChange:nil];
	
	// Register for screen connect and disconnect notifications.
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(screenDidChange:)
												 name:UIScreenDidConnectNotification 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(screenDidChange:)
												 name:UIScreenDidDisconnectNotification 
											   object:nil];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIScreenDidConnectNotification 
												  object:nil];

	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIScreenDidDisconnectNotification 
												  object:nil];

	[super viewDidDisappear:animated];
}


@end
