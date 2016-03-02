/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The main root view controller of this app.
 */

#import "AppDelegate.h"
#import "RootViewController.h"
#import "NotesDocument.h"
#import "NotesDocumentViewController.h"
#import "FileRepresentation.h"

// segue identifiers that both navigate to NotesDocumentViewController
static NSString *kSegueIDForShowDocument = @"ShowDocument";
static NSString *kSegueIDForNewDocument = @"NewDocument";

@interface RootViewController () <NotesDocumentDelegate>

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

    // while in table edit mode, we allow for "Delete My Photos" feature in the bottom toolbar
    UIBarButtonItem *clearAllButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete All"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(deleteAllAction:)];
    [self setToolbarItems:@[clearAllButton] animated:NO];
    
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
    
    // hide/show toolbar on edit toggle
    [self.navigationController setToolbarHidden:!editing animated:YES];
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
        if ([documentURL.pathExtension isEqualToString:kFileExtension])
        {
            FileRepresentation *fileRepresentation = [[FileRepresentation alloc] initWithURL:documentURL];
            [self.documentList addObject:fileRepresentation];
        }
    }
    
    [self.tableView reloadData];
}


#pragma mark - Creating a new document

// called when the '+' button is tapped
- (IBAction)createDocument:(id)sender
{
    // display an alert to ask the user to enter the document name
    UIAlertController *createDocumentAlertController =
        [UIAlertController alertControllerWithTitle:@"New Document"
                                            message:@"Enter document name"
                                     preferredStyle:UIAlertControllerStyleAlert];
    
    // add the text field for entering the new document name,
    // note: we want to block certain characters when naming the new document
    // by listening for UITextFieldTextDidChangeNotification
    //
    __weak RootViewController *weakSelf = self;
    
    [createDocumentAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        [[NSNotificationCenter defaultCenter] addObserver:weakSelf
                                                 selector:@selector(editFieldChanged:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:textField];
    }];
    
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *act) {
                                                         /*
                                                          The user decided to create a new document.
                                                          
                                                          First check for a duplicate document already exists to avoid an overwrite.
                                                          Then add a new file item to the local file list and add a new row in the table view to display it.
                                                          Perform the "CreateNewDocument" segue to display the new empty file for editing.
                                                          */
                                                         
                                                         // the alert view contains the name of the document
                                                         UITextField *docNameField = createDocumentAlertController.textFields[0];
                                                         
                                                         // check if a document already exists with that name, to avoid an overwrite
                                                         NSString *fileName = [docNameField.text stringByAppendingPathExtension:kFileExtension];
                                                         NSURL *fileURL = [[AppDelegate localDocumentsDirectoryURL] URLByAppendingPathComponent:fileName];
                                                         
                                                         BOOL isDirectory;
                                                         if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path isDirectory:&isDirectory])
                                                         {
                                                             // we could a document with the same name, alert the user
                                                             NSString *message = [NSString stringWithFormat:@"Document \"%@\" already exists", docNameField.text];
                                                             UIAlertController *dupeAlert = [UIAlertController alertControllerWithTitle:message
                                                                                                                            message:@"Please choose a different name."
                                                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                                                             UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                  handler:nil];
                                                             [dupeAlert addAction:okAction];
                                                             [self presentViewController:dupeAlert animated:YES completion:^ {
                                                                 // (do more potential work here after the alert is presented)
                                                             }];
                                                         }
                                                         else
                                                         {
                                                             // no document found with the same name
                                                             
                                                             // add it to our data soruce
                                                             FileRepresentation *fileRepresentation = [[FileRepresentation alloc] initWithURL:fileURL];
                                                             [self.documentList addObject:fileRepresentation];
                                                             
                                                             // insert a table row for this document
                                                             NSIndexPath *newFileIndexPath = [NSIndexPath indexPathForRow:(self.documentList).count - 1 inSection:0];
                                                             [self.tableView insertRowsAtIndexPaths:@[newFileIndexPath] withRowAnimation:UITableViewRowAnimationNone];
                                                             [self.tableView selectRowAtIndexPath:newFileIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
                                                             // push navigate to the NotesDocumentViewcontroller for editing
                                                             [self performSegueWithIdentifier:kSegueIDForNewDocument sender:self];
                                                             
                                                             // resort the list of document since one was added
                                                             [self.documentList sortUsingComparator:^NSComparisonResult(FileRepresentation *fileRep1, FileRepresentation *fileRep2) {
                                                                 return [fileRep1.URL.lastPathComponent localizedStandardCompare:fileRep2.URL.lastPathComponent];
                                                             }];
                                                             [self.tableView reloadData];
                                                         }
                                                         
                                                         [[NSNotificationCenter defaultCenter] removeObserver:self
                                                                                                         name:UITextFieldTextDidChangeNotification
                                                                                                       object:docNameField];
                                                     }];
    
    [createDocumentAlertController addAction:OKAction];
    createDocumentAlertController.preferredAction = OKAction;
    OKAction.enabled = NO; // no docunemt name entered yet, don't allow OK dismissal
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction *act) {
            
                                                         UITextField *docNameField = createDocumentAlertController.textFields[0];
                                                         [[NSNotificationCenter defaultCenter] removeObserver:self
                                                                                                         name:UITextFieldTextDidChangeNotification
                                                                                                       object:docNameField];
                                                     }];
    [createDocumentAlertController addAction:cancelAction];

    [self presentViewController:createDocumentAlertController animated:YES completion:^ {
        // (do more potential work here after the alert is presented)
    }];
}

// called each time the user types a character in the UIAlertController's text field
- (void)editFieldChanged:(NSNotification *)aNotification
{
    if (self.presentedViewController != nil && [self.presentedViewController isKindOfClass:[UIAlertController class]])
    {
        UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
        UITextField *nameField = alertController.textFields.firstObject;
        
        if ([aNotification object] == nameField)    // is it the edit field we expect?
        {
            NSString *valueStr = nameField.text;
            
            // enable the OK button if we have a non-empty name
            UIAlertAction *okAction = alertController.preferredAction;
            okAction.enabled = valueStr.length > 0;
            
            if (valueStr.length > 0)
            {
                // don't allow files that start with "."
                if ([valueStr hasPrefix:@"."])
                {
                    valueStr = [valueStr stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:@"-"];
                }
                else
                {
                    // filter out "/" and ":" characters
                    valueStr = [valueStr stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
                    valueStr = [valueStr stringByReplacingOccurrencesOfString:@":" withString:@"-"];
                }
            }
            nameField.text = valueStr;
        }
    }
}


#pragma mark - Deleting a document

- (void)deleteDocumentWithIndex:(NSUInteger)index
{
    // deleta a particular document by index
    NSURL *documentURL = [(self.documentList)[index] URL];
    
    NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateWritingItemAtURL:documentURL
                                        options:NSFileCoordinatorWritingForDeleting
                                          error:nil
                                     byAccessor:^(NSURL *writingURL)
     {
         NSFileManager* fileManager = [[NSFileManager alloc] init];
         [fileManager removeItemAtURL:writingURL error:nil];
         
         // update the document list and remove the row from the table view
         [self.documentList removeObjectAtIndex:index];
         
         // update the table
         NSIndexPath *indexPathToDelete = [NSIndexPath indexPathForRow:index inSection:0];
         [self.tableView deleteRowsAtIndexPaths:@[indexPathToDelete] withRowAnimation:UITableViewRowAnimationAutomatic];
     }];
}

- (void)deleteAllAction:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Are you sure you want to delete all documents?"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         // OK button action
                                                         while (self.documentList.count > 0)
                                                         {
                                                             [self deleteDocumentWithIndex:0];
                                                         }
                                                         
                                                         // delete all operation means we exit edit mode
                                                         [self setEditing:NO animated:YES];
                                                         
                                                         // disable Edit button if we have no records
                                                         self.editButtonItem.enabled = (self.documentList.count > 0);
                                                     }];
    [alert addAction:OKAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
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
    
    FileRepresentation *fileRep = (self.documentList)[row];
    NSString *fileName = (fileRep.URL).lastPathComponent.stringByDeletingPathExtension;

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
        // user wants to delete a particular document
        [self deleteDocumentWithIndex:indexPath.row];
        
        // if no documents left exit edit mode here
        [self setEditing:!(self.documentList.count == 0)];
    }
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // get the view controller the segue will navigate to
    NotesDocumentViewController *notesDocumentViewController = segue.destinationViewController;

    notesDocumentViewController.delegate = self;  // so we can be notified if the document was renamed
    
    // Get the currently-selected row in the table view (the one the user tapped on) and use
    // its row to get the corresponding file representation object and from that the URL of
    // the document the user wants to open.
    //
    NSIndexPath *selectionPath = (self.tableView).indexPathForSelectedRow;
    NSUInteger row = selectionPath.row;
    FileRepresentation *fileRep = (self.documentList)[row];
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
