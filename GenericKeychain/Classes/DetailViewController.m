/*
     File: DetailViewController.m
 Abstract: 
 Controller for editing text view data.
 
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
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
*/

#import <Security/Security.h>

#import "DetailViewController.h"
#import "KeychainItemWrapper.h"
#import "EditorController.h"

enum {
	kUsernameSection = 0,
	kPasswordSection,
	kAccountNumberSection,
	kShowCleartextSection
};

// Defined UI constants.
static NSInteger kPasswordTag	= 2;	// Tag table view cells that contain a text field to support secure text entry.

@implementation DetailViewController

@synthesize tableView, textFieldController, passwordItem, accountNumberItem;

+ (NSString *)titleForSection:(NSInteger)section
{
    switch (section)
    {
        case kUsernameSection: return NSLocalizedString(@"Username", @"");
        case kPasswordSection: return NSLocalizedString(@"Password", @"");
        case kAccountNumberSection: return NSLocalizedString(@"Account Number", @"");
    }
    return nil;
}

+ (id)secAttrForSection:(NSInteger)section
{
    switch (section)
    {
        case kUsernameSection: return (id)kSecAttrAccount;
        case kPasswordSection: return (id)kSecValueData;
        case kAccountNumberSection: return (id)kSecValueData;
    }
    return nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
    {
        // Title displayed by the navigation controller.
        self.title = @"Keychain";
    }
    return self;
}

- (void)dealloc
{
    // Release allocated resources.
    [tableView release];
    [textFieldController release];
	[passwordItem release];
	[accountNumberItem release];
    [super dealloc];
}

- (void)awakeFromNib {
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (void)switchAction:(id)sender
{
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:
							 [NSIndexPath indexPathForRow:0 inSection:kPasswordSection]];
	UITextField *textField = (UITextField *) [cell.contentView viewWithTag:kPasswordTag];
	textField.secureTextEntry = ![sender isOn];
	
	cell = [self.tableView cellForRowAtIndexPath:
			[NSIndexPath indexPathForRow:0 inSection:kAccountNumberSection]];
	textField = (UITextField *) [cell.contentView viewWithTag:kPasswordTag];
	textField.secureTextEntry = ![sender isOn];
}

// Action sheet delegate method.
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == 0)
    {
        [passwordItem resetKeychainItem];
        [accountNumberItem resetKeychainItem];
        [self.tableView reloadData];
    }
}

- (IBAction)resetKeychain:(id)sender
{
    // open a dialog with an OK and cancel button
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Reset Generic Keychain Item?"
            delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"OK" otherButtonTitles:nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showInView:self.view];
    [actionSheet release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [tableView reloadData];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [tableView reloadData];
}

#pragma mark -
#pragma mark <UITableViewDelegate, UITableViewDataSource> Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    // 4 sections, one for each property and one for the switch
    return 4;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    // Only one row for each section
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return (section == kAccountNumberSection) ? 48.0 : 0.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [DetailViewController titleForSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *title = nil;
	
	if (section == kAccountNumberSection)
	{
		title = NSLocalizedString(@"AccountNumberShared", @"");
	}
	
	return title;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString *kUsernameCellIdentifier =	@"UsernameCell";
	static NSString *kPasswordCellIdentifier =	@"PasswordCell";
	static NSString *kSwitchCellIdentifier =	@"SwitchCell";
	
	UITableViewCell *cell = nil;	
	
	switch (indexPath.section)
	{
		case kUsernameSection:
		{
			cell = [aTableView dequeueReusableCellWithIdentifier:kUsernameCellIdentifier];
			if (cell == nil)
			{
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kUsernameCellIdentifier] autorelease];
			}
			
			cell.textLabel.text = [passwordItem objectForKey:[DetailViewController secAttrForSection:indexPath.section]];
			cell.accessoryType = (self.editing) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
			
			break;
		}
			
		case kPasswordSection:
		case kAccountNumberSection:
		{
			UITextField *textField = nil;
			
			cell = [aTableView dequeueReusableCellWithIdentifier:kPasswordCellIdentifier];
			if (cell == nil)
			{
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kPasswordCellIdentifier] autorelease];

				textField = [[UITextField alloc] initWithFrame:CGRectInset(cell.contentView.bounds, 10, 10)];
				textField.tag = kPasswordTag;
				textField.font = [UIFont systemFontOfSize:17.0];
				
				// prevent editing
				textField.enabled = NO;
				
				// display contents as bullets rather than text
				textField.secureTextEntry = YES;
				
				[cell.contentView addSubview:textField];
				[textField release];
			}
			else {
				textField = (UITextField *) [cell.contentView viewWithTag:kPasswordTag];
			}
			
			KeychainItemWrapper *wrapper = (indexPath.section == kPasswordSection) ? passwordItem : accountNumberItem;
			textField.text = [wrapper objectForKey:[DetailViewController secAttrForSection:indexPath.section]];
			cell.accessoryType = (self.editing) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
						
			break;
		}
						
		case kShowCleartextSection:
		{
			cell = [aTableView dequeueReusableCellWithIdentifier:kSwitchCellIdentifier];
			if (cell == nil)
			{
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSwitchCellIdentifier] autorelease];
				
				cell.textLabel.text = NSLocalizedString(@"Show Cleartext", @"");
				cell.selectionStyle = UITableViewCellSelectionStyleNone;

				UISwitch *switchCtl = [[[UISwitch alloc] initWithFrame:CGRectMake(194, 8, 94, 27)] autorelease];
				[switchCtl addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
				[cell.contentView addSubview:switchCtl];
			}
			
			break;
		}
	}
    
	return cell;
}


- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{    
	if (indexPath.section != kShowCleartextSection)
	{
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		id secAttr = [DetailViewController secAttrForSection:indexPath.section];
		[textFieldController.textControl setPlaceholder:[DetailViewController titleForSection:indexPath.section]];
		[textFieldController.textControl setSecureTextEntry:(indexPath.section == kPasswordSection || indexPath.section == kAccountNumberSection)];
		if (indexPath.section == kUsernameSection || indexPath.section == kPasswordSection)
		{
			textFieldController.keychainItemWrapper = passwordItem;
		}
		else {
			textFieldController.keychainItemWrapper = accountNumberItem;
		}
		textFieldController.textValue = [textFieldController.keychainItemWrapper objectForKey:secAttr];
		textFieldController.editedFieldKey = secAttr;
		textFieldController.title = [DetailViewController titleForSection:indexPath.section];
		
		[self.navigationController pushViewController:textFieldController animated:YES];
	}
}

@end