/*
     File: QuickContactsViewController.m
 Abstract: Demonstrates how to use ABPeoplePickerNavigationControllerDelegate, ABPersonViewControllerDelegate,
 ABNewPersonViewControllerDelegate, and ABUnknownPersonViewControllerDelegate. Shows how to browse a list of 
 Address Book contacts, display and edit a contact record, create a new contact record, and update a partial contact record.
  Version: 1.3
 
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

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import "QuickContactsViewController.h"

enum TableRowSelected
{
	kUIDisplayPickerRow = 0,
	kUICreateNewContactRow,
	kUIDisplayContactRow,
	kUIEditUnknownContactRow
};

// Height for the Edit Unknown Contact row
#define kUIEditUnknownContactRowHeight 81.0

@interface QuickContactsViewController () < ABPeoplePickerNavigationControllerDelegate,ABPersonViewControllerDelegate,
                                            ABNewPersonViewControllerDelegate, ABUnknownPersonViewControllerDelegate>
@property (nonatomic, assign) ABAddressBookRef addressBook;
@property (nonatomic, strong) NSMutableArray *menuArray;

@end

@implementation QuickContactsViewController

#pragma mark Load views
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	[super viewDidLoad];
    // Create an address book object
	_addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    self.menuArray = [[NSMutableArray alloc] initWithCapacity:0];
    [self checkAddressBookAccess];
}

#pragma mark -
#pragma mark Address Book Access
// Check the authorization status of our application for Address Book
-(void)checkAddressBookAccess
{
    switch (ABAddressBookGetAuthorizationStatus())
    {
        // Update our UI if the user has granted access to their Contacts
        case  kABAuthorizationStatusAuthorized:
            [self accessGrantedForAddressBook];
            break;
            // Prompt the user for access to Contacts if there is no definitive answer
        case  kABAuthorizationStatusNotDetermined :
            [self requestAddressBookAccess];
            break;
            // Display a message if the user has denied or restricted access to Contacts
        case  kABAuthorizationStatusDenied:
        case  kABAuthorizationStatusRestricted:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy Warning"
                                                            message:@"Permission was not granted for Contacts."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
            break;
        default:
            break;
    }
}

// Prompt the user for access to their Address Book data
-(void)requestAddressBookAccess
{
    QuickContactsViewController * __weak weakSelf = self;
    
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error)
    {
        if (granted)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf accessGrantedForAddressBook];
                                                         
            });
        }
    });
}

// This method is called when the user has granted access to their address book data.
-(void)accessGrantedForAddressBook
{
    // Load data from the plist file
	NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Menu" ofType:@"plist"];
	self.menuArray = [NSMutableArray arrayWithContentsOfFile:plistPath];
    [self.tableView reloadData];
}

#pragma mark Table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [self.menuArray count];
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *CellIdentifier = @"CellID";
    UITableViewCell *aCell;
	// Make the Display Picker and Create New Contact rows look like buttons
    if (indexPath.section < 2)
    {
        aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        aCell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    else
    {
        aCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        aCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        aCell.detailTextLabel.numberOfLines = 0;
        // Display descriptions for the Edit Unknown Contact and Display and Edit Contact rows
        aCell.detailTextLabel.text = [[self.menuArray objectAtIndex:indexPath.section] valueForKey:@"description"];
    }
	aCell.textLabel.text = [[self.menuArray objectAtIndex:indexPath.section] valueForKey:@"title"];
	return aCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case kUIDisplayPickerRow:
			[self showPeoplePickerController];
			break;
		case kUICreateNewContactRow:
			[self showNewPersonViewController];
			break;
		case kUIDisplayContactRow:
			[self showPersonViewController];
			break;
		case kUIEditUnknownContactRow:
			[self showUnknownPersonViewController];
			break;
		default:
			[self showPeoplePickerController];
			break;
	}	
}

#pragma mark TableViewDelegate method
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Change the height if Edit Unknown Contact is the row selected
	return (indexPath.section==kUIEditUnknownContactRow) ? kUIEditUnknownContactRowHeight : tableView.rowHeight;	
}

#pragma mark Show all contacts
// Called when users tap "Display Picker" in the application. Displays a list of contacts and allows users to select a contact from that list.
// The application only shows the phone, email, and birthdate information of the selected contact.
-(void)showPeoplePickerController
{
	ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
	// Display only a person's phone, email, and birthdate
	NSArray *displayedItems = [NSArray arrayWithObjects:[NSNumber numberWithInt:kABPersonPhoneProperty], 
							    [NSNumber numberWithInt:kABPersonEmailProperty],
							    [NSNumber numberWithInt:kABPersonBirthdayProperty], nil];
	
	
	picker.displayedProperties = displayedItems;
	// Show the picker
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark Display and edit a person
// Called when users tap "Display and Edit Contact" in the application. Searches for a contact named "Appleseed" in 
// in the address book. Displays and allows editing of all information associated with that contact if
// the search is successful. Shows an alert, otherwise.
-(void)showPersonViewController
{
	// Search for the person named "Appleseed" in the address book
	NSArray *people = (NSArray *)CFBridgingRelease(ABAddressBookCopyPeopleWithName(self.addressBook, CFSTR("Appleseed")));
	// Display "Appleseed" information if found in the address book 
	if ((people != nil) && [people count])
	{
		ABRecordRef person = (__bridge ABRecordRef)[people objectAtIndex:0];
		ABPersonViewController *picker = [[ABPersonViewController alloc] init];
		picker.personViewDelegate = self;
		picker.displayedPerson = person;
		// Allow users to edit the person’s information
		picker.allowsEditing = YES;
		[self.navigationController pushViewController:picker animated:YES];
	}
	else 
	{
		// Show an alert if "Appleseed" is not in Contacts
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" 
														message:@"Could not find Appleseed in the Contacts application" 
													   delegate:nil 
											  cancelButtonTitle:@"Cancel" 
											  otherButtonTitles:nil];
		[alert show];
	}
}

#pragma mark Create a new person
// Called when users tap "Create New Contact" in the application. Allows users to create a new contact.
-(void)showNewPersonViewController
{
	ABNewPersonViewController *picker = [[ABNewPersonViewController alloc] init];
	picker.newPersonViewDelegate = self;
	
	UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:picker];
    [self presentViewController:navigation animated:YES completion:nil];
}

#pragma mark Add data to an existing person
// Called when users tap "Edit Unknown Contact" in the application. 
-(void)showUnknownPersonViewController
{
	ABRecordRef aContact = ABPersonCreate();
	CFErrorRef anError = NULL;
	ABMultiValueRef email = ABMultiValueCreateMutable(kABMultiStringPropertyType);
	bool didAdd = ABMultiValueAddValueAndLabel(email, @"John-Appleseed@mac.com", kABOtherLabel, NULL);
	
	if (didAdd == YES)
	{
		ABRecordSetValue(aContact, kABPersonEmailProperty, email, &anError);
		if (anError == NULL)
		{
			ABUnknownPersonViewController *picker = [[ABUnknownPersonViewController alloc] init];
			picker.unknownPersonViewDelegate = self;
			picker.displayedPerson = aContact;
			picker.allowsAddingToAddressBook = YES;
		    picker.allowsActions = YES;
			picker.alternateName = @"John Appleseed";
			picker.title = @"John Appleseed";
			picker.message = @"Company, Inc";
			
			[self.navigationController pushViewController:picker animated:YES];
		}
		else 
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" 
															message:@"Could not create unknown user" 
														   delegate:nil 
												  cancelButtonTitle:@"Cancel"
												  otherButtonTitles:nil];
			[alert show];
		}
	}	
	CFRelease(email);
	CFRelease(aContact);
}

#pragma mark ABPeoplePickerNavigationControllerDelegate methods
// Displays the information of a selected person
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	return YES;
}

// Does not allow users to perform default actions such as dialing a phone number, when they select a person property.
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person 
								property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	return NO;
}

// Dismisses the people picker and shows the application when users tap Cancel.
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark ABPersonViewControllerDelegate methods
// Does not allow users to perform default actions such as dialing a phone number, when they select a contact property.
- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person 
					property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
	return NO;
}


#pragma mark ABNewPersonViewControllerDelegate methods
// Dismisses the new-person view controller. 
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark ABUnknownPersonViewControllerDelegate methods
// Dismisses the picker when users are done creating a contact or adding the displayed person properties to an existing contact. 
- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView didResolveToPerson:(ABRecordRef)person
{
    [self.navigationController popViewControllerAnimated:YES];
}

// Does not allow users to perform default actions such as emailing a contact, when they select a contact property.
- (BOOL)unknownPersonViewController:(ABUnknownPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	return NO;
}

@end
