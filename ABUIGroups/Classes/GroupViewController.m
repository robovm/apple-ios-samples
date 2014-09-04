/*
     File: GroupViewController.m
 Abstract: Prompts a user for access to their address book data, then updates its UI according to their response.
 Adds, displays, and removes group records from Contacts.
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

#import "AddGroupViewController.h"
#import "GroupViewController.h"
#import "MySource.h"

@interface GroupViewController ()
@property (nonatomic, assign) ABAddressBookRef addressBook;
@property (nonatomic, strong) NSMutableArray *sourcesAndGroups;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;

@end

@implementation GroupViewController

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create an address book object
	_addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    //Display all groups available in the Address Book
	self.sourcesAndGroups = [[NSMutableArray alloc] initWithCapacity:0];
    
    // Check whether we are authorized to access the user's address book data
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
                                                  otherButtonTitles: nil];
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
    GroupViewController * __weak weakSelf = self;
    
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
    // Enable the Add button
    self.addButton.enabled = YES;
    // Add the Edit button
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
        
    // Fetch all groups available in address book
    self.sourcesAndGroups = [self fetchGroupsInAddressBook:self.addressBook];
    [self.tableView reloadData];
}


#pragma mark -
#pragma mark Manage groups

// Return the name associated with the given identifier
- (NSString *)nameForSourceWithIdentifier:(int)identifier
{
	switch (identifier)
	{
		case kABSourceTypeLocal:
			return @"On My Device";
			break;
		case kABSourceTypeExchange:
			return @"Exchange server";
			break;
		case kABSourceTypeExchangeGAL:
			return @"Exchange Global Address List";
			break;
		case kABSourceTypeMobileMe:
			return @"MobileMe";
			break;
		case kABSourceTypeLDAP:
			return @"LDAP server";
			break;
		case kABSourceTypeCardDAV:
			return @"CardDAV server";
			break;
		case kABSourceTypeCardDAVSearch:
			return @"Searchable CardDAV server";
			break;
		default:
			break;
	}
	return nil;
}


// Return the name of a given group
- (NSString *)nameForGroup:(ABRecordRef)group
{
    return (NSString *)CFBridgingRelease(ABRecordCopyCompositeName(group));
}


// Return the name of a given source
- (NSString *)nameForSource:(ABRecordRef)source
{
	// Fetch the source type 
	CFNumberRef sourceType = ABRecordCopyValue(source, kABSourceTypeProperty);
	
	// Fetch and return the name associated with the source type
	return [self nameForSourceWithIdentifier:[(NSNumber*)CFBridgingRelease(sourceType) intValue]];
}


#pragma mark -
#pragma mark Manage Address Book contacts

// Create and add a new group to the address book database
-(void)addGroup:(NSString *)name fromAddressBook:(ABAddressBookRef)myAddressBook
{
    BOOL sourceFound = NO;
    if ([name length] != 0)
    {
        ABRecordRef newGroup = ABGroupCreate();
        CFStringRef newName = CFBridgingRetain(name);
        ABRecordSetValue(newGroup,kABGroupNameProperty,newName,NULL);
        
        // Add the new group 
		ABAddressBookAddRecord(myAddressBook,newGroup, NULL);
		ABAddressBookSave(myAddressBook, NULL);
        CFRelease(newName);
        
        // Get the ABSource object that contains this new group
		ABRecordRef groupSource = ABGroupCopySource(newGroup);
		// Fetch the source name
		NSString *sourceName = [self nameForSource:groupSource];
        CFRelease(groupSource);
        
        // Look for the above source among the sources in sourcesAndGroups
        for (MySource *source in self.sourcesAndGroups)
        {
            if ([source.name isEqualToString:sourceName])
            {
                // Associate the new group with the found source
                [source.groups addObject:CFBridgingRelease(newGroup)];
                // Set sourceFound to YES if sourcesAndGroups already contains this source
                sourceFound = YES;
            }
        }
        // Add this source to sourcesAndGroups
		if (!sourceFound)
		{
			NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithObjects:CFBridgingRelease(newGroup), nil];
			MySource *newSource = [[MySource alloc] initWithAllGroups:mutableArray name:sourceName];
		    [self.sourcesAndGroups addObject:newSource];
		}
    }
}


// Remove a group from the given address book
- (void)deleteGroup:(ABRecordRef)group fromAddressBook:(ABAddressBookRef)myAddressBook
{
	ABAddressBookRemoveRecord(myAddressBook, group, NULL);
	ABAddressBookSave(myAddressBook, NULL);
}


// Return a list of groups organized by sources
- (NSMutableArray *)fetchGroupsInAddressBook:(ABAddressBookRef)myAddressBook
{
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:0];
    // Get all the sources from the address book
	NSArray *allSources = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllSources(myAddressBook));
    if ([allSources count] >0)
    {
        for (id aSource in allSources)
        {
            ABRecordRef source = (ABRecordRef)CFBridgingRetain(aSource);
            // Fetch all groups included in the current source
            CFArrayRef result = ABAddressBookCopyArrayOfAllGroupsInSource (myAddressBook, source);
            // The app displays a source if and only if it contains groups
            if ((result) && (CFArrayGetCount(result) > 0))
            {
                NSMutableArray *groups = [(__bridge NSArray *)result mutableCopy];
                // Fetch the source name
                NSString *sourceName = [self nameForSource:source];
                //Create a MySource object that contains the source name and all its groups
                MySource *source = [[MySource alloc] initWithAllGroups:groups name:sourceName];
                
                // Save the source object into the array
                [list addObject:source];
            }
            if (result)
            {
                CFRelease(result);
            }
            CFRelease(source);
        }
    }
    
    return list;
}

#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sourcesAndGroups count];
}


// Customize section header titles
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self.sourcesAndGroups objectAtIndex:section] name];
}


// Customize the number of rows in the table view
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[[self.sourcesAndGroups objectAtIndex:section] groups] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupCell" forIndexPath:indexPath];
	
	MySource *source = [self.sourcesAndGroups objectAtIndex:indexPath.section];
	ABRecordRef group = (ABRecordRef)CFBridgingRetain([source.groups objectAtIndex:indexPath.row]);
	cell.textLabel.text = [self nameForGroup:group];
    CFRelease(group);
    
    return cell;
}


#pragma mark -
#pragma mark Editing rows

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
	//Disable the Add button while editing
	self.navigationItem.rightBarButtonItem.enabled = !editing;
}


// Handle the deletion of a group
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		MySource *source = [self.sourcesAndGroups objectAtIndex:indexPath.section];
		// group to be deleted
		ABRecordRef group = (__bridge ABRecordRef)([source.groups objectAtIndex:indexPath.row]);
		
		// Remove the above group from its associated source
		[source.groups removeObjectAtIndex:indexPath.row];
		
		// Remove the group from the address book
		[self deleteGroup:group fromAddressBook:self.addressBook];
		
		// Update the table view
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		// Remove the section from the table if the associated source does not contain any groups
		if ([source.groups count] == 0)
		{
			// Remove the source from sourcesAndGroups
			[self.sourcesAndGroups removeObject:source];
			
			[tableView deleteSections: [NSIndexSet indexSetWithIndex:indexPath.section]
                     withRowAnimation:UITableViewRowAnimationFade];
		}
	}
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    // Release the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}


#pragma mark -
#pragma mark Get user input

// This method is called when the user taps Done in the "Add Group" view.
- (IBAction)done:(UIStoryboardSegue *)segue
{
    if ([[segue identifier] isEqualToString:@"returnInput"])
    {
        AddGroupViewController *addGroupViewController = [segue sourceViewController];
        if (addGroupViewController.group)
        {
            [self addGroup:addGroupViewController.group fromAddressBook:self.addressBook];
            [[self tableView] reloadData];
        }
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}


// This method is called when the user taps Cancel in the "Add Group" view.
- (IBAction)cancel:(UIStoryboardSegue *)segue
{
    if ([[segue identifier] isEqualToString:@"cancelInput"])
    {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}


- (void)dealloc
{
    if(_addressBook)
    {
        CFRelease(_addressBook);
    }
}

@end

