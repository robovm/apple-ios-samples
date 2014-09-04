/*
     File: ThreeViewController.m 
 Abstract: The view controller for page three. 
  Version: 1.6 
  
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

#import "ThreeViewController.h"

NSString *kBadgeValuePrefKey = @"kBadgeValue";  // badge value key for storing to NSUserDefaults

@interface ThreeViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, weak) IBOutlet UITextField *badgeField;

- (void)doneAction:(id)sender;

@end

@implementation ThreeViewController

@synthesize doneButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set the badge value in our test field and tabbar item
    NSString *badgeValue = [[NSUserDefaults standardUserDefaults] stringForKey:kBadgeValuePrefKey];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
	if (badgeValue.length != 0)
	{
        self.badgeField.text = badgeValue;
        self.navigationController.tabBarItem.badgeValue = self.badgeField.text;
    }
}

- (void)doneAction:(id)sender
{
	// dismiss the keyboard by resigning our badge edit field as first responder
	[self.badgeField resignFirstResponder];
	
	// set the badge value to our tab item (but only if a valid string)
	if (self.badgeField.text.length > 0)
	{
        // a value was entered,
        // because we are inside a navigation controller,
        // we must access its tabBarItem to set the badgeValue.
        self.navigationController.tabBarItem.badgeValue = self.badgeField.text;
	}
    else
    {
        // no value was entered
        self.navigationController.tabBarItem.badgeValue = nil;
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:self.badgeField.text forKey:kBadgeValuePrefKey];
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	// user is starting to edit, add the done button to the navigation bar
	self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	/// user is done editing, remove the done button from the navigation bar
	self.navigationItem.rightBarButtonItem = nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	BOOL result = YES;
	
	// restrict the maximum number of characters to 5
	if (textField.text.length == 5 && string.length > 0)
		result = NO;
	
	return result;
}

@end

