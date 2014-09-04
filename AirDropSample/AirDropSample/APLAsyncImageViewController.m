/*
 
     File: APLAsyncImageViewController.m
 Abstract: View controller to handle sending a file that is asynchronously preprocessed after the user chooses their sending method.
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

#import "APLAsyncImageViewController.h"
#import "APLProgressAlertViewController.h"

NSString * const kProgressAlertViewControllerIdentifier = @"APLProgressAlertViewController";


@interface APLAsyncImageViewController ()

@property (strong, nonatomic) UIWindow *alertWindow;
@property (strong, nonatomic) APLProgressAlertViewController *alertViewController;
@property (strong, nonatomic) UIPopoverController *activityPopover;

@property (weak, nonatomic) IBOutlet UIButton *shareImageButton;

- (IBAction)openActivitySheet:(id)sender;

@end


@implementation APLAsyncImageViewController


- (IBAction)openActivitySheet:(id)sender
{
    //Create new activity provider item to pass to the activity view controller
    APLAsyncImageActivityItemProvider *aiImageItemProvider = [[APLAsyncImageActivityItemProvider alloc] init];
    
    //Use delegation to monitor the progress of the item method
    aiImageItemProvider.delegate = self;
    
    //Create an activity view controller with the activity provider item. UIActivityItemProvider (AsyncImageActivityItemProvider's superclass) conforms to the UIActivityItemSource protocol
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[aiImageItemProvider] applicationActivities:nil];
    
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        //iPhone, present activity view controller as is
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
    else
    {
        //iPad, present the view controller inside a popover
        if (![self.activityPopover isPopoverVisible]) {
            self.activityPopover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
            [self.activityPopover presentPopoverFromRect:[self.shareImageButton frame] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
        else
        {
            //Dismiss if the button is tapped while pop over is visible
            [self.activityPopover dismissPopoverAnimated:YES];
        }
    }
}

#pragma mark - AsyncImageActivityItemProviderDelegate

- (void)imageActivityItemProviderPreprocessingDidBegin:(APLAsyncImageActivityItemProvider *)imageActivityItemProvider
{
    //Show alert to let the user know the item method is processing in the background.
    self.alertWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.alertViewController = [[APLProgressAlertViewController alloc] initWithNibName:kProgressAlertViewControllerIdentifier bundle:nil];
    
    //Put window on top of all other windows/views
    [self.alertWindow setWindowLevel:UIWindowLevelNormal];
    
    [self.alertWindow setRootViewController:self.alertViewController];
    [self.alertWindow makeKeyAndVisible];
}

- (void)imageActivityItemProvider:(APLAsyncImageActivityItemProvider *)imageActivityItemProvider preprocessingProgressDidUpdate:(float)progress
{
    [self.alertViewController updateProgressBar:progress];
}

- (void)imageActivityItemProviderPreprocessingDidEnd:(APLAsyncImageActivityItemProvider *)imageActivityItemProvider
{
    //Dismiss alert by making main window key and visible
    [self.alertWindow resignKeyWindow];
    self.alertWindow = nil;
    self.alertViewController = nil;
}
@end
