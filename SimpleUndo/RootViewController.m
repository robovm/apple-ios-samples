/*
     File: RootViewController.m
 Abstract: The table view controller responsible for displaying information about a book. 
 The user can also edit the information.  When editing starts, the root view controller 
 creates an undo manager to record changes. The undo manager supports up to three levels 
 of and redo.  When the user taps Done, changes are considered to be committed and the 
 undo manager is disposed of.
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "RootViewController.h"
#import "EditingViewController.h"
#import "Book.h"

@interface RootViewController ()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSUndoManager *undoManager;
@end


@implementation RootViewController

// Must explicitly synthesize this.
@synthesize undoManager;

#pragma mark - View lifecycle

// -------------------------------------------------------------------------------
//	viewDidLoad
// -------------------------------------------------------------------------------
- (void)viewDidLoad
{
	[super viewDidLoad];
    
    // UIViewController provides a pre-configured edit button that toggles its
    // title and associated state between Edit and Done.
    // -setEditing:animated: will be called when the user taps this button.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

// -------------------------------------------------------------------------------
//	viewWillAppear:
// -------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Redisplay the data.
    [self.tableView reloadData];
}

// -------------------------------------------------------------------------------
//	viewDidAppear:
// -------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    
    // We must be the first responder to receive shake events for undo.
	[self becomeFirstResponder];
}

// -------------------------------------------------------------------------------
//	viewWillDisappear:
// -------------------------------------------------------------------------------
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    // You should resign first responder status when exiting the screen.
	[self resignFirstResponder];
}

// -------------------------------------------------------------------------------
//	didReceiveMemoryWarning
// -------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Release any properties that can be recreated lazily.
	self.dateFormatter = nil;
}

#pragma mark - Rotation

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
// -------------------------------------------------------------------------------
//	shouldAutorotateToInterfaceOrientation:
//  Disable rotation on iOS 5.x and earlier.  Note, for iOS 6.0 and later all you
//  need is "UISupportedInterfaceOrientations" defined in your Info.plist
// -------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#endif

#pragma mark - UITableViewDataSource
// Standard table view data source and delegate methods to display a table view
// containing a single section with three rows showing different properties of the
// book.

// -------------------------------------------------------------------------------
//	tableView:numberOfRowsInSection:
//  There are three rows, corresponding to the three pieces of information
//  the user can edit for a Book object.
// -------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

// -------------------------------------------------------------------------------
//	tableView:cellForRowAtIndexPath:
// -------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
    
    // Dequeue and then configure a table cell for each attribute of the book.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	switch (indexPath.row) {
        case 0: // Title
			cell.textLabel.text = @"Title";
			cell.detailTextLabel.text = self.book.title;
			break;
        case 1: // Author
			cell.textLabel.text = @"Author";
			cell.detailTextLabel.text = self.book.author;
			break;
        case 2: // Copyright
			cell.textLabel.text = @"Copyright";
			cell.detailTextLabel.text = [self.dateFormatter stringFromDate:self.book.copyright];
			break;
    }
    
    return cell;
}

// -------------------------------------------------------------------------------
//	tableView:editingStyleForRowAtIndexPath:
//  This optional UITableViewDelegate method is overridden to disallow rows to be
//  deleted when in editing mode.
// -------------------------------------------------------------------------------
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

// -------------------------------------------------------------------------------
//	tableView:shouldIndentWhileEditingRowAtIndexPath:
//  This optional UITableViewDelegate method is overridden to prevent rows from
//  being indented while in editing mode.
// -------------------------------------------------------------------------------
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

// -------------------------------------------------------------------------------
//	prepareForSegue:sender:
//  Called when a row is selected.  Configures the destination
//  EditingViewController to edit the property of book corresponding to the
//  selected row in the table view.
// -------------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"EditBook"]) {
        // sender will always be a UITableViewCell
        UITableViewCell *cell = (UITableViewCell*)sender;
        
        // Lookup the cell's index path so we know which row was selected.
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForCell:cell];
        
        // Configure the destination EditingViewController.
        EditingViewController *editingController = (EditingViewController*)segue.destinationViewController;
        editingController.sourceController = self;
        editingController.editedObject = self.book;
        
        switch (selectedIndexPath.row) {
            case 0: // Title
                editingController.editedPropertyKey = @"title";
                editingController.editedPropertyDisplayName = NSLocalizedString(@"title", @"display name for title");
                editingController.editingDate = NO;
                break;
            case 1: // Author
                editingController.editedPropertyKey = @"author";
                editingController.editedPropertyDisplayName = NSLocalizedString(@"author", @"display name for author");
                editingController.editingDate = NO;
                break;
            case 2: // Copyright
                editingController.editedPropertyKey = @"copyright";
                editingController.editedPropertyDisplayName = NSLocalizedString(@"copyright", @"display name for copyright");
                editingController.editingDate = YES;
                break;
        }
    }
}

#pragma mark - Editing

// -------------------------------------------------------------------------------
//  setValue:forEditedProperty: (Declared in the PropertyEditing protocol) 
//	Method to update a value in the book, and at the same time register the
//  undo/redo operation with the undo manager.
//  The implementation uses an invocation since the method requires two arguments.
//  This method is invoked by the editing view controller if the user taps Save.
// -------------------------------------------------------------------------------
- (void)setValue:(id)newValue forEditedProperty:(NSString *)field
{
	
	// prepareWithInvocationTarget: pushes a new undo item onto the undo stack
    // (or onto the redop stack if this method is invoked during an undo operation).
    // If the user chooses undo, then the undo manager sends the target (self)
    // setValue:forEditedProperty: message with the arguments
    // currentValueforEditedProperty and field.
	id currentValueforEditedProperty = [self.book valueForKey:field];
	[[self.undoManager prepareWithInvocationTarget:self] setValue:currentValueforEditedProperty forEditedProperty:field];
	
	// Update the book's property to the new value.
	[self.book setValue:newValue forKey:field];
	
	// Set the action name (which appears in the undo button title) to the
    // user-visible name of the field.
	if (![self.undoManager isUndoing])
		[self.undoManager setActionName:NSLocalizedString(field, @"string provided dynamically")];
}

// -------------------------------------------------------------------------------
//  setEditing:animated
//	This method is called when the view controller should transition in or out
//  of the editing state in response to the user tapping the edit button.
// -------------------------------------------------------------------------------
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    // This method is originally declared in UIViewController.  We must invoke
    // its implementation.
    [super setEditing:editing animated:animated];

	// Respond to change in editing state:
    // If editing begins, create and set an undo manager to track edits. Then
    // register as an observer of undo manager change notifications, so that if an
    // undo or redo operation is performed, the table view can be reloaded.
    // If editing ends, de-register from the notification center and remove the
    // undo manager.
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	if (editing) {
        // Create a new undo manager.
		NSUndoManager *anUndoManager = [[NSUndoManager alloc] init];
		self.undoManager = anUndoManager;
		
		// 3 levels of undo is somewhat arbitrary. It happens here to coincide
        // with the number of properties that can be edited, but in general you
        // need to consider the memory overhead of maintaining a large number of
        // undo actions, and the user interaction (how easy will it be for the user
        // to backtrack through a dozen or more actions).
		[self.undoManager setLevelsOfUndo:3];
        
        // Listen for undo or redo notifications to we know when to reload the
        // table view to display the change.
		[nc addObserver:self selector:@selector(undoManagerDidUndo:) name:NSUndoManagerDidUndoChangeNotification object:self.undoManager];
		[nc addObserver:self selector:@selector(undoManagerDidRedo:) name:NSUndoManagerDidRedoChangeNotification object:self.undoManager];
	}
	else {
        // Tear down the undo manager.
		[nc removeObserver:self name:NSUndoManagerDidUndoChangeNotification object:self.undoManager];
        [nc removeObserver:self name:NSUndoManagerDidRedoChangeNotification object:self.undoManager];
		self.undoManager = nil;
	}
}


#pragma mark - Undo support

// -------------------------------------------------------------------------------
//  undoManagerDidUndo:
//	Handler for the NSUndoManagerDidUndoChangeNotification.  Redisplays the table
//  view to reflect the changed value.
//  See also: -setEditing:animated:
// -------------------------------------------------------------------------------
- (void)undoManagerDidUndo:(NSNotification *)notification
{
	[self.tableView reloadData];
}

// -------------------------------------------------------------------------------
//  undoManagerDidRedo:
//	Handler for the NSUndoManagerDidRedoChangeNotification.  Redisplays the table
//  view to reflect the changed value.
//  See also: -setEditing:animated:
// -------------------------------------------------------------------------------
- (void)undoManagerDidRedo:(NSNotification *)notification
{
	[self.tableView reloadData];
}

// -------------------------------------------------------------------------------
//  canBecomeFirstResponder
//	The view controller must be first responder in order to be able to receive
//  shake events for undo.
// -------------------------------------------------------------------------------
- (BOOL)canBecomeFirstResponder
{
	return YES;
}

#pragma mark - Date formatter

// -------------------------------------------------------------------------------
//  dateFormatter
//	Custom implementation of the getter for the dateFormatter property.  This
//  method lazily creates and configures an NSDateFormatter if one does not
//  presently exist.
// -------------------------------------------------------------------------------
- (NSDateFormatter *)dateFormatter
{
	if (_dateFormatter == nil) {
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	}
	return _dateFormatter;
}

@end

