/*
     File: MainViewController.m
 Abstract: The root view controller. Demonstrates detailed steps on how to show content on an external display.
  Version: 1.0
 
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

#import "MainViewController.h"
#import "GLViewController.h"

@interface MainViewController ()

@property (nonatomic, strong) UIWindow *extWindow;
@property (nonatomic, strong) UIScreen *extScreen;

@end

@implementation MainViewController

- (void)screenDidChange:(NSNotification *)notification
{
    // To display content on an external display, do the following:
    // 1. Use the screens class method of the UIScreen class to determine if an external display is available.
    NSArray	*screens = [UIScreen screens];
	
    NSUInteger screenCount = [screens count];
    
	if (screenCount > 1)
    {
        // 2. If an external screen is available, get the screen object and look at the values in its availableModes
        // property. This property contains the configurations supported by the screen.
        
        // Select first external screen
		self.extScreen = [screens objectAtIndex:1]; //index 0 is your iPhone/iPad
		NSArray	*availableModes = [self.extScreen availableModes];
        
        // 3. Select the UIScreenMode object corresponding to the desired resolution and assign it to the currentMode
        // property of the screen object.
        
        // Select the highest resolution in this sample
        NSInteger selectedRow = [availableModes count] - 1;
        self.extScreen.currentMode = [availableModes objectAtIndex:selectedRow];
        
        // Set a proper overscanCompensation mode
        self.extScreen.overscanCompensation = UIScreenOverscanCompensationInsetApplicationFrame;
		
        if (self.extWindow == nil) {
            // 4. Create a new window object (UIWindow) to display your content.
            UIWindow *extWindow = [[UIWindow alloc] initWithFrame:[self.extScreen bounds]];
            self.extWindow = extWindow;
        }
        
        // 5. Assign the screen object to the screen property of your new window.
        self.extWindow.screen = self.extScreen;
        
        // 6. Configure the window (by adding views or setting up your OpenGL ES rendering context).
        
        // Resize the GL view to fit the external screen
        self.glController.view.frame = self.extWindow.frame;
        
        // Set the target screen to the external screen
        // This will let the GL view create a CADisplayLink that fires at the native fps of the target display.
        [(GLViewController *)self.glController setTargetScreen:self.extScreen];
        
        // Configure user interface
        // In this sample, we use the same UI layout when an external display is connected or not.
        // In your real application, you probably want to provide distinct UI layouts for best user experience.
        [(GLViewController *)self.glController screenDidConnect:self.userInterfaceController];
        
        // Add the GL view
        [self.extWindow addSubview:self.glController.view];
            
        // 7. Show the window.
        [self.extWindow makeKeyAndVisible];
        
        // On the iPhone/iPad screen
        // Remove the GL view (it is displayed on the external screen)
        for (UIView* v in [self.view subviews])
            [v removeFromSuperview];
        
        // Display the fullscreen UI on the iPhone/iPad screen
        [self.view addSubview:self.userInterfaceController.view];
	}
	else //handles disconnection of the external display
    {
        // Release external screen and window
		self.extScreen = nil;
		self.extWindow = nil;
        
        // On the iPhone/iPad screen
        // Remove the fullscreen UI (a window version will be displayed atop the GL view)
        for (UIView* v in [self.view subviews])
            [v removeFromSuperview];
        
        // Resize the GL view to fit the iPhone/iPad screen
        self.glController.view.frame = self.view.frame;
        
        // Set the target screen to the main screen
        // This will let the GL view create a CADisplayLink that fires at the native fps of the target display.
        [(GLViewController *)self.glController setTargetScreen:[UIScreen mainScreen]];
        
        // Configure user interface
        // In this sample, we use the same UI layout when an external display is connected or not.
        // In your real application, you probably want to provide distinct UI layouts for best user experience.
        [(GLViewController *)self.glController screenDidDisconnect:self.userInterfaceController];
        
        // Display the GL view on the iPhone/iPad screen
        [self.view addSubview:self.glController.view];
	}
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIScreenDidConnectNotification
												  object:nil];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIScreenDidDisconnectNotification
												  object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIViewController *userInterfaceController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:NULL] instantiateViewControllerWithIdentifier:@"UserInterfaceViewController"];
    self.userInterfaceController = userInterfaceController;
    
    UIViewController *glController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:NULL] instantiateViewControllerWithIdentifier:@"GLViewController"];
    self.glController = glController;
    
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

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

@end
