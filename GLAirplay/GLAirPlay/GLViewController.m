/*
     File: GLViewController.m
 Abstract: This UIViewController configures the OpenGL ES view and its UI when an external display is connected/disconnected.
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

#import "GLViewController.h"
#import "UserInterfaceViewController.h"
#import "GLView.h"

@implementation GLViewController

- (void)screenDidConnect:(UIViewController *)userInterface
{
    // Remove UI previously added atop the GL view
    for (UIView* v in [self.view subviews])
            [v removeFromSuperview];
    
    // One of these userInterface view controllers is visible at a time,
    // so release the other one to minimize memory usage
    self.userInterfaceOnTop = nil;
    self.userInterfaceFullscreen = userInterface;
        
    if (self.userInterfaceFullscreen)
    {
        // Setup UI (When an external display is connected, it will be added to mainViewController's view
        // in MainViewController/-screenDidChange:)
        [(UserInterfaceViewController *)self.userInterfaceFullscreen screenDidConnect];
        
        // Set the userControlDelegte, which is responsible for setting the cube's rotating radius
        [(GLView *)self.view setUserControlDelegate:(id)self.userInterfaceFullscreen];
    }
}
    
- (void)screenDidDisconnect:(UIViewController *)userInterface
{
    // One of these userInterface view controllers is visible at a time,
    // so release the other one to minimize memory usage
    self.userInterfaceFullscreen = nil;
    self.userInterfaceOnTop = userInterface;
    
    if (self.userInterfaceOnTop)
    {
        // Setup UI
        [(UserInterfaceViewController *)self.userInterfaceOnTop screenDidDisconnect];
        
        // Add UI on top
        [(GLView *)self.view addSubview:self.userInterfaceOnTop.view];
        
        // Set the userControlDelegte, which is responsible for setting the cube's rotating radius
        [(GLView *)self.view setUserControlDelegate:(id)self.userInterfaceOnTop];
    }
}

- (void)setTargetScreen:(UIScreen *)targetScreen
{
    // Delegate to the GL view to create a CADisplayLink for the target display (UIScreen/-displayLinkWithTarget:selector:)
    // This will result in the native fps for whatever display you create it from.
    [(GLView *)self.view setTargetScreen:targetScreen];
}

- (void)startAnimation
{
    [(GLView *)self.view startAnimation];
}

- (void)stopAnimation
{
    [(GLView *)self.view stopAnimation];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.autoresizingMask =
        UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
