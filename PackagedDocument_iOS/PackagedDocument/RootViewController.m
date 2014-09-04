/*
     File: RootViewController.m
 Abstract: The main root view controller of this app.
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "AppDelegate.h"
#import "RootViewController.h"
#import "NotesDocument.h"
#import "NotesDocumentViewController.h"
#import "FileRepresentation.h"

// segue identifiers that both navigate to NotesDocumentViewController
static NSString *kSegueIDForShowDocument = @"ShowDocument";
static NSString *kSegueIDForNewDocument = @"NewDocument";

@interface RootViewController () <UIAlertViewDelegate, NotesDocumentDelegate>

@property (nonatomic, strong) NSMutableArray *documentList;

@end


#pragma mark -

@implementation RootViewController

- (void)viewDidLoad
{
    // configure the view by setting up the Edit/Done button, and create the list of documents
    [super viewDidLoad];
    
    self.tableView.allowsSelectionDuringEditing = NO;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    [self populateTableWithDirectoryContents];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // whenever we come back to this view controller update the enable state of the "Edit" button
    self.navigationItem.leftBarButtonItem.enabled = self.documentList.count > 0 ? YES : NO;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    // change the enable state of the '+' button,
    // don't allow adding documents while our table is being edited for document removals
    //
    self.navigationItem.rightBarButtonItem.enabled = !editing;
    
    // after editing starts or ends, make sure to update the enable state of the "Edit" button
    self.navigationItem.leftBarButtonItem.enabled = self.documentList.count > 0 ? YES : NO;
}

// called to populate or re-populate our table with the conts in the Documents folder,
// called upon initialiation and when we are notified as NotesDocumentDelegate
//
- (void)populateTableWithDirectoryContents
{
    self.documentList = [[NSMutableArray alloc] init];
    
    // enumerate the contents of the Documents directory:
    // for each file in the directory, create a FileRepresentation object and add it to
    // the documentList array
    //
    NSError *error = nil;
    NSArray *localDocuments =
        [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[AppDelegate localDocumentsDirectoryURL]
                                      includingPropertiesForKeys:nil
                                                         options:NSDirectoryEnumerationSkipsPackageDescendants
                                                           error:&error];
    NSAssert(error == nil, ([NSString stringWithFormat:@"Error contentsOfDirectoryAtURL: %@", error]));

    for (NSURL *documentURL in localDocuments)
    {
        // only add documents to the table that match our extension
        if ([[documentURL pathExtension] isEqualToString:kFileExtension])
        {
            FileRepresentation *fileRepresentation = [[FileRepresentation alloc] initWithURL:documentURL];
            [self.documentList addObject:fileRepresentation];
        }
    }
    
    [self.tableView reloadData];
}


#pragma mark - Creating a new document

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        /*
         The user decided to create a new document. The alert view contains the name of the document.
         Add a new file item to the local file list and add a new row in the table view to display it.
         Perform the "CreateNewDocument" segue to display the new empty file.
         */
        NSString *fileName = [[[alertView textFieldAtIndex:0] text] stringByAppendingPathExtension:kFileExtension];
        NSURL *fileURL = [[AppDelegate localDocumentsDirectoryURL] URLByAppendingPathComponent:fileName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:NO])
        {
            NSString *message = [NSString stringWithFormat:@"Document \"%@\" already exists", [[alertView textFieldAtIndex:0] text]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:message
                                                            message:@"Please choose a different name."
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
            [alert show];
        }
        else
        {
            FileRepresentation *fileRepresentation = [[FileRepresentation alloc] initWithURL:fileURL];
            
            [self.documentList addObject:fileRepresentation];
            
            NSIndexPath *newFileIndexPath = [NSIndexPath indexPathForRow:[self.documentList count] - 1 inSection:0];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newFileIndexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView selectRowAtIndexPath:newFileIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            
            [self performSegueWithIdentifier:kSegueIDForNewDocument sender:self];
        }
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidChangeNotification
                                                  object:[alertView textFieldAtIndex:0]];
}


- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    // don't allow Create button to work if there is no docoument name
    UITextField *textField = [alertView textFieldAtIndex:0];
    return (textField.text.length > 0) ? YES : NO;
}

// called each time the user types a character in the UIAlertView's text field
- (void)editFieldChanged:(NSNotification *)aNotification
{
    UITextField *textField = [aNotification object];
    
    NSString *valueStr = textField.text;
    
    // don't allow files that start with "."
    if ([valueStr hasPrefix:@"."])
    {
        valueStr = [valueStr stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:@"-"];
    }
    else
    {
        // filter out / and :
        valueStr = [valueStr stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
        valueStr = [valueStr stringByReplacingOccurrencesOfString:@":" withString:@"-"];
    }
    
    textField.text = valueStr;
}

// called when the '+' button is tapped
- (IBAction)createDocument:(id)sender
{
    // display an alert to ask the user to enter the document name
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Document"
                                                    message:@"Enter document name"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Create", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    // we want to block certain characters when naming the new document
    // by listening for UITextFieldTextDidChangeNotification
    //
    UITextField *textField = [alert textFieldAtIndex:0];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editFieldChanged:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:textField];
    [alert show];
}


#pragma mark - UITableViewDataSource

// Data for the first section comes from the documentList array; elements in each array
// are instances of FileRepresentation class.
//
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.documentList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // configure the cell (just display the filename without the extension)
    NSUInteger row = indexPath.row;
    
    FileRepresentation *fileRep = [self.documentList objectAtIndex:row];
    NSString *fileName = [[fileRep.URL lastPathComponent] stringByDeletingPathExtension];

    cell.textLabel.text = fileName;
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;  // no reordering, we display alphabetically
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // which edit action?
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // user wants to delete the document
        NSURL *documentURL = [[self.documentList objectAtIndex:indexPath.row] URL];
        
        // asynchonously delete the document
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void)
        {
            NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            [fileCoordinator coordinateWritingItemAtURL:documentURL
                                                options:NSFileCoordinatorWritingForDeleting
                                                  error:nil
                                             byAccessor:^(NSURL *writingURL)
            {
                NSFileManager* fileManager = [[NSFileManager alloc] init];
                [fileManager removeItemAtURL:writingURL error:nil];
            }];
        });
        
        // update the document list and remove the row from the table view
        [self.documentList removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[[NSArray alloc] initWithObjects:&indexPath count:1]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if (self.documentList.count == 0)
        {
            // no documents left, which means no more documents to remove, so exit edit mode here
            [self setEditing:NO];
        }
    }
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // get the view controller the segue will navigate to
    NotesDocumentViewController *notesDocumentViewController = [segue destinationViewController];

    notesDocumentViewController.delegate = self;  // so we can be notified if the document was renamed
    
    // Get the currently-selected row in the table view (the one the user tapped on) and use
    // its row to get the corresponding file representation object and from that the URL of
    // the document the user wants to open.
    //
    NSIndexPath *selectionPath = [self.tableView indexPathForSelectedRow];
    NSUInteger row = selectionPath.row;
    FileRepresentation *fileRep = [self.documentList objectAtIndex:row];
    NSURL *selectedDocumentURL = fileRep.URL;

    // determine which segue is being performed, and configure the destination view controller
    // by invoking setDocumentURL:createNewFile: with the appropriate arguments
    //
    if ([segue.identifier isEqualToString:kSegueIDForShowDocument])
    {
        // we are navigating to view the document
        [notesDocumentViewController setDocumentURL:selectedDocumentURL createNewFile:NO];
    }
    else if ([segue.identifier isEqualToString:kSegueIDForNewDocument])
    {
        // we are navigating to create the new document
        [notesDocumentViewController setDocumentURL:selectedDocumentURL createNewFile:YES];
    }
}


#pragma mark - NotesDocumentDelegate

- (void)directoryDidChange
{
    // we are notified as a delegate that a document name has changed (from NotesDocumentViewController)
    // so re-populate our table view content.
    //
    [self populateTableWithDirectoryContents];
}

@end
