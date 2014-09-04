/*
 
     File: APLProfileViewController.m
 Abstract: View controller to handle displaying, editing, and AirDropping an instance of the custom APLProfile class.
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

#import "APLAppDelegate.h"
#import "APLProfileViewController.h"
#import "APLProfile.h"

int const kAspectFillRow = 0;
int const kAspectFitRow = 1;

@interface APLProfileViewController ()

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareItem;

@property (strong, nonatomic) UIPopoverController *activityPopover;
@property (strong, nonatomic) UIBarButtonItem *doneButton;

@end


@implementation APLProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    if (self.interactive) {
        
        //Set up done button that appears when text is being edited.
        self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishEditing)];
    }
    else
    {
        //Interactivity is turned off when the view is used to display received profiles.
        [self.toolbar setHidden:YES];
        [self.nameTextField setEnabled:NO];
        [self.profileImageView setUserInteractionEnabled:NO];
        [self.profileImageView setBackgroundColor:[UIColor whiteColor]];
        
    }
    
    if (self.profile) {
        
        //Set user interface values.
        self.nameTextField.text = self.profile.name;
        [self.profileImageView setImage:self.profile.image];
        
        if (self.profile.imageContentMode == UIViewContentModeScaleAspectFill) {
            self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
        }
    }
    
}
- (void)viewWillAppear:(BOOL)animated
{
    //Register for when the save window appears so the keyboard won't conflict with it.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveWindowWillAppear) name:DisplayingSaveWindowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DisplayingSaveWindowNotification object:nil];
}


#pragma mark - Actions

- (IBAction)openActivitySheet:(id)sender
{
    //Create an activity view controller with the profile as its activity item. APLProfile conforms to the UIActivityItemSource protocol.
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.profile] applicationActivities:nil];
    
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        //iPhone, present activity view controller as is.
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
    else
    {
        //iPad, present the view controller inside a popover.
        if (![self.activityPopover isPopoverVisible]) {
            self.activityPopover = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
            [self.activityPopover presentPopoverFromBarButtonItem:self.shareItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
        else
        {
            //Dismiss if the button is tapped while popover is visible.
            [self.activityPopover dismissPopoverAnimated:YES];
        }
    }
}

- (void)saveWindowWillAppear
{
    //Remove keyboard if needed.
    [self.nameTextField resignFirstResponder];
}

- (IBAction)openAspectModeActionSheet:(id)sender {
    
    //Display action sheet to allow the user to pick between content modes for the profile image.
    NSString *titleString = NSLocalizedString(@"Choose Image Content Mode", @"Title for aspect ratio action sheet");
    NSString *cancelString = NSLocalizedString(@"Cancel", @"Cancel for aspect ratio action sheet");
    NSString *aspectFitString = NSLocalizedString(@"Aspect Fit", @"Aspect fit button title for aspect ratio action sheet");
    NSString *aspectFillString = NSLocalizedString(@"Aspect Fill", @"Aspect fill button title fill button titletle for aspect ratio action sheet");


    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:titleString
                                                             delegate:self
                                                    cancelButtonTitle:cancelString
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:aspectFillString, aspectFitString, nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //Handle the user's choice of content mode for the profile image.
    if (buttonIndex == kAspectFillRow) {
        self.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.profile.imageContentMode = UIViewContentModeScaleAspectFill;
    }
    else if (buttonIndex == kAspectFitRow)
    {
        self.profileImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.profile.imageContentMode = UIViewContentModeScaleAspectFit;
    }
}

#pragma mark - Editing

- (void)finishEditing
{
    [self.view endEditing:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.navigationItem setRightBarButtonItem:self.doneButton];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (![self.profile.name isEqualToString:textField.text]) {
        self.profile.name = textField.text;
        [self.delegate profileViewController:self profileDidChange:self.profile];
    }
    [textField resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //Resign when the keyboard done button is tapped.
    [textField resignFirstResponder];
    return YES;
}

@end
