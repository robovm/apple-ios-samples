/*
 
     File: APLCustomURLViewController.m
 Abstract: View controller to handle displaying, editing, parsing, and AirDropping a URL with a custom scheme.
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

#import "APLCustomURLViewController.h"
#import "APLCustomURLContainer.h"
#import "APLUtilities.h"
#import "APLAppDelegate.h"

@interface APLCustomURLViewController ()

@property (strong, nonatomic) UIPopoverController *activityPopover;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareItem;
@property (weak, nonatomic) IBOutlet UITextField *customURLTextField;

@end

@implementation APLCustomURLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Load custom url
    NSURL *customURL = [APLUtilities loadCustomURL];
    if (!customURL) {
        customURL = [[NSURL alloc] initWithString:@"adcs://test/one/two?key1=value1"];
    }
    
    self.customURLContainer = [[APLCustomURLContainer alloc] initWithURL:customURL];
    
    //Fill textfield with URL
    self.customURLTextField.text = [self stringFromURLWithoutScheme:self.customURLContainer.url];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Register for notifications about received content
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadURL) name:SavedCustomURLNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveWindowWillAppear) name:DisplayingSaveWindowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SavedCustomURLNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DisplayingSaveWindowNotification object:nil];
}

#pragma mark - Actions

- (IBAction)openActivitySheet:(id)sender
{
    //Create an activity view controller with the url container as its activity item. APLCustomURLContainer conforms to the UIActivityItemSource protocol.
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.customURLContainer] applicationActivities:nil];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        //iPhone, present activity view controller as is
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
    else
    {
        //iPad, present the view controller inside a popover
        if (![self.activityPopover isPopoverVisible]) {
            self.activityPopover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
            [self.activityPopover presentPopoverFromBarButtonItem:self.shareItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
        else
        {
            //Dismiss if the button is tapped while pop over is visible
            [self.activityPopover dismissPopoverAnimated:YES];
        }
    }
}

- (void)saveWindowWillAppear
{
    [self.customURLTextField resignFirstResponder];
}

- (void)reloadURL
{
    NSURL *customURL = [APLUtilities loadCustomURL];
    if (customURL) {
        self.customURLContainer.url = customURL;
        self.customURLTextField.text = [self stringFromURLWithoutScheme:customURL];
    }

}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //Handle updates to the URL
    if (![textField.text isEqualToString:[self stringFromURLWithoutScheme:self.customURLContainer.url]]) {
        
        NSString *urlString = [NSString stringWithFormat:@"%@://%@", kCustomScheme, textField.text];
        self.customURLContainer.url = [NSURL URLWithString:urlString];
        
        [APLUtilities saveCustomURL:self.customURLContainer.url];
    }
}

#pragma mark - Convenience Methods

- (NSString *)stringFromURLWithoutScheme:(NSURL *)url
{
    NSString *scheme = [[url scheme] stringByAppendingString:@"://"];
    return [[url absoluteString] substringFromIndex:[scheme length]];
}

@end
