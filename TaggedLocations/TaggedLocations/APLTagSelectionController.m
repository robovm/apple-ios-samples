
/*
     File: APLTagSelectionController.m
 Abstract: The table view controller responsible for displaying all available tags.
 The controller is also given an Event object. Row for tags related to the event display a checkmark.  If the user taps a row, the corresponding tag is added to or removed from the event's tags relationship as appropriate.
 
  Version: 2.3
 
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


#import "APLTagSelectionController.h"

#import "APLEvent.h"
#import "APLTag.h"
#import "APLEditableTableViewCell.h"



@interface APLTagSelectionController ()

@property (nonatomic) IBOutlet UILabel *headerLabel;
@property (nonatomic) NSMutableArray *tagsArray;

@end



@implementation APLTagSelectionController

- (void)viewDidLoad
{
	// Configure the table view and controller.
	[super viewDidLoad];	
	self.tableView.allowsSelectionDuringEditing = YES;
	
	// Set up the navigation bar.
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	NSString *eventName = self.event.name;
	if (![eventName length] > 0) {
		eventName = NSLocalizedString(@"Unnamed event", @"Replacement name for unnamed event");
	}
    NSString *formatString = NSLocalizedString(@"Tags for \"%@\" are indicated by a check mark.", @"Header label.");
	self.headerLabel.text = [NSString stringWithFormat:formatString, eventName];

	/*
     The goal is to display all the tags, so fetch them using the event's context.
     Put the fetched tags into a mutable array.
     */
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"APLTag"];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	[fetchRequest setSortDescriptors:@[sortDescriptor]];
	
	NSManagedObjectContext *context = self.event.managedObjectContext;
    NSError *error;
	NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
	if (fetchedObjects == nil) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
	}
	
	self.tagsArray = [fetchedObjects mutableCopy];
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if ([self.tagsArray count] == 0) {
		// There are no tags, so assume the user wants to add one.
		// Create a tag and edit it straightaway.
		[self setEditing:YES animated:NO];
		[self insertTagAnimated:NO];
	}
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Return the number of tags in the array, adding one if editing (for the Add Tag row).
	NSUInteger count = [self.tagsArray count];
	if (self.editing) {
		count++;
	}
    return count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger row = indexPath.row;

	/*
     If the row number is equal to the number of items in tagsArray, then the row is the Add Tag row.
     */
	if (row == [self.tagsArray count]) {
		static NSString *InsertionCellIdentifier = @"InsertionCell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:InsertionCellIdentifier];
		return cell;
	}
	
	static NSString *TagCellIdentifier = @"EditableTableViewCell";
	
    APLEditableTableViewCell *cell = (APLEditableTableViewCell *)[tableView dequeueReusableCellWithIdentifier:TagCellIdentifier];
	    
	/*
     Set the numeric view tag on the text field to the row number so it can be identified later if edited.
     */
	cell.textField.tag = row;
	
	APLTag *tag = (self.tagsArray)[row];
	
	/*
     If the tag at this row in the tags array is related to the event, display a checkmark, otherwise remove any checkmark that might have been present.
     */
	cell.textField.text = tag.name;
	if ([self.event.tags containsObject:tag]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
    return cell;
}


#pragma mark - Editing rows

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// The Add Tag row gets an insertion marker, the others a delete marker.
	if (indexPath.row == [self.tagsArray count]) {
		return UITableViewCellEditingStyleInsert;
	}
    return UITableViewCellEditingStyleDelete;
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
	
	// Don't show the Back button while editing.
	[self.navigationItem setHidesBackButton:editing animated:YES];

	
	[self.tableView beginUpdates];
	
    NSUInteger count = [self.tagsArray count];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:count inSection:0];
    
	// Add or remove the Add row as appropriate.
    UITableViewRowAnimation animationStyle = UITableViewRowAnimationNone;
    if (animated) {
        animationStyle = UITableViewRowAnimationAutomatic;
    }

	if (editing) {
		[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:animationStyle];
	}
	else {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:animationStyle];
    }
    
    [self.tableView endUpdates];
	
	// If editing is finished, save the managed object context.
	
	if (!editing) {
		NSManagedObjectContext *context = self.event.managedObjectContext;
		NSError *error;
		if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
		}
	}
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSManagedObjectContext *context = self.event.managedObjectContext;
	
    if (editingStyle == UITableViewCellEditingStyleDelete) {
	
		// Delete the tag.
		
		/*
         Ensure the cell is not being edited, otherwise the callback in textFieldShouldEndEditing: may look for a non-existent row.
         */
		APLEditableTableViewCell *cell = (APLEditableTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
		[cell.textField resignFirstResponder];

		
		// Find the tag to delete.
		APLTag *tag = (self.tagsArray)[indexPath.row];

		/*
         Delete the tag from the context.  Because the relationship between Tag and Event is defined in both directions, and the delete rule is nullify, Core Data automatically removes the tag from any relationships in which it is present.
         */
		[context deleteObject:tag];

		// Remove the tag from the tags array and the corresponding row from the table view.
		[self.tagsArray removeObject:tag];
		
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		
		// Save the change.
		NSError *error;
		if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
		}
		
    }
	
	if (editingStyle == UITableViewCellEditingStyleInsert) {
		[self insertTagAnimated:YES];
		// Don't save yet because the user must set a name first.
	}	
}


- (void)insertTagAnimated:(BOOL)animated
{
	/*
     Create a new instance of Tag, insert it into the tags array, and add a corresponding new row to the table view.
	 */
	APLTag *tag = [NSEntityDescription insertNewObjectForEntityForName:@"APLTag" inManagedObjectContext:[self.event managedObjectContext]];
	
	/*
     Presumably the tag was added for the current event, so relate it to the event.
	 */
    [self.event addTagsObject:tag];
	
	// Add the new tag to the tags array and to the table view.	
	[self.tagsArray addObject:tag];
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.tagsArray count]-1 inSection:0];
	[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	
	// Start editing the tag's name.
	APLEditableTableViewCell *cell = (APLEditableTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	[cell.textField becomeFirstResponder];
}


#pragma mark - Row selection

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Disable selection of the Add row.
	if (indexPath.row == [self.tagsArray count]) {
		return nil;
	}
	return indexPath;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	/*
	 Find the tag at the row index in the tags array, then
	 * If the event currently has this tag, remove the tag;
	 * If the event doesn't have this tag, add the tag.
	
	 (The Add row is not selectable.)
	 */
	APLTag *tag = (self.tagsArray)[indexPath.row];
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	if ([self.event.tags containsObject:tag]) {
		cell.accessoryType = UITableViewCellAccessoryNone;
		[self.event removeTagsObject:tag];
	}
	else {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		[self.event addTagsObject:tag];
	}
	
	// Save the change.
	NSError *error;
	if (![self.event.managedObjectContext save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Editing text fields

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    // Update the tag's name with the text in the text field.
    APLTag *tag = (self.tagsArray)[textField.tag];
	tag.name = textField.text;
	
	return YES;
}	


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;	
}


@end

