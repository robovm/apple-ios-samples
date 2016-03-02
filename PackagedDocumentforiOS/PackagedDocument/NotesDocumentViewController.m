/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The view controller used for editing "NotesDocument".
 */

#import "NotesDocumentViewController.h"
#import "ImageViewController.h"
#import "NotesDocument.h"
#import "AppDelegate.h"
#import "Note.h"


#define kDocImageSection 1

#pragma mark -

@interface NotesDocumentViewController ()  <UITextFieldDelegate,
                                            UINavigationControllerDelegate,
                                            UIImagePickerControllerDelegate>

@property (nonatomic, strong) NotesDocument *document;

// cached references to our table cell controls
@property (nonatomic, weak) IBOutlet UITextField *textField;        // document's name
@property (nonatomic, weak) IBOutlet UITableViewCell *imageCell;    // table's image cell containing document's image
@property (nonatomic, weak) IBOutlet UITextView *textView;          // document's notes

// these are our data source pieces to back our UITableView in case user cancels any edit session
@property (nonatomic, strong) NSString *sourceName;
@property (nonatomic, strong) NSString *sourceNotes;
@property (nonatomic, strong) UIImage *sourceImage;

@property (nonatomic, assign) BOOL cancelling;

@end


#pragma mark -

@implementation NotesDocumentViewController

// this can be called internally or externally by whoever hosts this UIDocument
// (in our case RootViewController), so open a new NotesDocument
//
- (void)setDocumentURL:(NSURL *)url createNewFile:(BOOL)createNewFile
{
    self.document = [[NotesDocument alloc] initWithFileURL:url];
    if (createNewFile)
    {
        Note *note = [[Note alloc] init];
        self.document.note = note;
        [self.document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            // note this block will be called after the document is saved, so there may be some delay
            //
        }];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // add an edit/done button to the navigation bar
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // opening the document could take a while depending on the document size,
    // so show a activity indicator and block user touches to the table until the open completes
    //
    self.tableView.userInteractionEnabled = NO;
    UIActivityIndicatorView *indView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    indView.color = (self.navigationController.navigationBar).tintColor;
    [indView startAnimating];
    UIBarButtonItem *indViewItem = [[UIBarButtonItem alloc] initWithCustomView:indView];
    self.navigationItem.rightBarButtonItem = indViewItem;
    
    // set our view controller's title and data source to match our document name
    self.title = (self.document.fileURL).lastPathComponent.stringByDeletingPathExtension;
    
    // open our document and update the table with it's content,
    // we balance out by closing after populating the table
    //
    [self.document openWithCompletionHandler:^(BOOL success) {
        if (success)
        {
            // we need to populate our table cell data source
            // (we are called here after the UIDocument has been read)
            //
            self.sourceImage = self.document.note.image;
            self.sourceNotes = self.document.note.notes;
            self.sourceName = self.document.fileURL.lastPathComponent.stringByDeletingPathExtension;
            
            // update the title cell
            self.textField.text = self.sourceName;

            // update just our image cell
            self.imageCell.imageView.image = self.sourceImage;
            
            // update the notes cell
            self.textView.text = self.sourceNotes;

            [self.tableView reloadData];
        }
        
        // done opening and ready to edit,
        // remove the loading indicator, enable editing, allow the table to be used
        //
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        self.tableView.userInteractionEnabled = YES;
        
        // done populating table, close the document
        [self.document closeWithCompletionHandler:nil];
    }];

    // listen for when we are suspended to the background
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    // listen for text field changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:nil];
}

- (BOOL)documentNameExists:(NSString *)documentName
{
    NSString *newFileName = [documentName stringByAppendingPathExtension:kFileExtension];
    NSURL *checkFileURL = [[AppDelegate localDocumentsDirectoryURL] URLByAppendingPathComponent:newFileName];
    
    BOOL isDirectory;
    return [[NSFileManager defaultManager] fileExistsAtPath:checkFileURL.path isDirectory:&isDirectory];
}

// signifies whether or not we want to allow the editing operation to be fulfilled
// (includes both Done (save) and Cancel operations), returns NO only if the user wanted
// to rename the document that matches one already on disk
//
- (BOOL)processEditResults:(BOOL)editing
{
    BOOL processEditResults = YES;
    
    if (editing)
    {
        // user has "started" editing (tapped Edit button)
        //
        // apply the Cancel button in place of the left back button
        self.navigationItem.leftBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                          target:self
                                                          action:@selector(cancelAction:)];
    }
    else
    {
        // user has "finished" editing (tapped either Done or Cancel buttons)
        //
        NSString *existingDocName = (self.document.fileURL).lastPathComponent.stringByDeletingPathExtension;
        
        if (self.cancelling)
        {
            // user tapped "Cancel" button,
            // so cancel all work, and revert to the current document's data
            //
            self.sourceImage = self.document.note.image;
            self.sourceName = existingDocName;
            self.sourceNotes = self.document.note.notes;
            
            self.textField.text = self.sourceName;
            self.imageCell.imageView.image = self.sourceImage;
            self.textView.text = self.sourceNotes;
        }
        else
        {
            // user tapped "Done" button.
            // is the document name on disk match what the user entered?
            //
            if (![existingDocName isEqualToString:self.textField.text])
            {
                // user chose a different document name,
                // check if there exists another doc with that name
                //
                if ([self documentNameExists:self.textField.text])
                {
                    // a document with that name already exists, warn the user
                    //
                    NSString *message = [NSString stringWithFormat:@"Document \"%@\" already exists", self.textField.text];
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:message
                                                                                   message:@"Please choose a different name."
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction *act) {
                                                                         
                                                                         // user dismissed duplicate alert, revert the title field to the previous value
                                                                         NSString *originalFileName = (self.document.fileURL).lastPathComponent.stringByDeletingPathExtension;
                                                                         self.sourceName = self.textField.text = originalFileName;
                                                                     }];

                    [alert addAction:OKAction];
                    [self presentViewController:alert animated:YES completion:^ {
                        // (do more potential work here after the alert is presented)
                    }];
                    
                    processEditResults = NO; // don't yet leave edit mode since there's a conflict
                }
                else
                {
                    NSString *newDocName = [self.textField.text stringByAppendingPathExtension:kFileExtension];
                    NSURL *renamedDocumentURL = [[AppDelegate localDocumentsDirectoryURL] URLByAppendingPathComponent:newDocName];
                    
                    // save the docoument to the new URL with a new name
                    [self.document saveToURL:renamedDocumentURL
                            forSaveOperation:UIDocumentSaveForCreating
                           completionHandler:^(BOOL success) {
                               if (success)
                               {
                                   // note this block will be called after the document is saved, so there may be some delay
                                   //
                                   
                                   // update the view control's title to reflect the new document name
                                   self.title = renamedDocumentURL.lastPathComponent.stringByDeletingPathExtension;
                                   
                                   // remove activity indicator
                                   
                                   // since we have renamed the document successfully, notify our
                                   // delegate (in this case our RootViewController) to update it's table
                                   // view with the new document name
                                   //
                                   if ([self.delegate respondsToSelector:@selector(directoryDidChange)])
                                   {
                                       [self.delegate directoryDidChange];
                                   }
                               }
                           }];
                }
            }
            
            if (processEditResults)
            {
                // user has finished and wants to "commit" all changes to disk
                //
                Note *note = self.document.note;
                note.image = self.imageCell.imageView.image;
                note.notes = self.textView.text;
                
                // update our interim data source (to be reflected in our table cells)
                self.sourceImage = self.imageCell.imageView.image;
                self.sourceName = self.textField.text;
                self.sourceNotes = self.textView.text;
                
                // trigger autosave of this document bump the change count
                [self.document updateChangeCount:UIDocumentChangeDone];
            }
        }
        
        [self.tableView reloadData];
    }

    return processEditResults;
}

// invoked by the Edit/Done button to toggle the editing state of the document.
//
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if ([self processEditResults:editing])
    {
        // start or end editing (used tapped either Cancel or Done)
        //
        // When editing, hide the back button and replace it with 'Cancel' so the user can't
        // navigate away from the view until committing the changes.
        //
        [self.navigationItem setHidesBackButton:editing animated:YES];
        
        // update the image cell label indicator to reflect the edit state
        self.imageCell.textLabel.text = editing ? @"Add or Edit" : @"";
        
        // update the enabled states of our edit cells to reflect the edit state
        self.textField.enabled = self.textView.editable = editing;
        
        if (self.cancelling || !editing)
        {
            // we are done editing the document
            
            /*
            When you directly call closeWithCompletionHandler: on the document instance,
            UIDocument saves the document if there are any unsaved changes, by calling your
            UIDocument subclass method:

            - (id)contentsForType:(NSString *)typeName error:(NSError **)outError;

            So you call "closeWithCompletionHandler" to begin the sequence of method calls that
            saves a document safely and asynchronously.  After the save operation concludes,
            the code in completionHandler is executed.

            You typically would not override closeWithCompletionHandler.
            The default implementation calls the autosaveWithCompletionHandler: method.
            */

            if (!(self.document.documentState & UIDocumentStateClosed))
            {
                // note this close operation may take some time for bigger documents
                [_document closeWithCompletionHandler:^(BOOL success) {
                    if (success)
                    {
                        // document was successfully closed
                    }
                }];
            }
            
            // remove the Cancel button on the left
            self.navigationItem.leftBarButtonItem = nil;
        }
        else
        {
            // start editing means we need to open the document to make changes
            [self.document openWithCompletionHandler:^(BOOL success) {
                 if (success)
                 {
                     // document was successfully opened
                 }
            }];
        }
            
        // allow the edit session to be honored by calling our super
        [super setEditing:editing animated:animated];
    }
}

- (void)dealloc
{
    // we are no longer interested in these notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidChangeNotification
                                                  object:nil];
}

- (UIImage *)normalizedImage:(UIImage *)image
{
    UIImage *returnImage = nil;
    if (image != nil)
    {
        if (image.imageOrientation == UIImageOrientationUp)
        {
            return image;
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        [image drawInRect:(CGRect){{0, 0}, image.size}];
        returnImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return returnImage;
}


#pragma mark - Notifications

// we are being notified that this app is being put to the background (suspended)
- (void)didEnterBackground:(NSNotification *)notif
{
    // we are moving to the background, so exit edit mode
    [self setEditing:NO animated:NO];
}

// we are being notified when text has changed in our UITextField
- (void)textFieldDidChange:(NSNotification *)notif
{
    // check if the text field has text, keep the Done button disabled until we have valid text
    UITextField *textField = (UITextField *)notif.object;
    if (textField == self.textField)
    {
        self.navigationItem.rightBarButtonItem.enabled = (textField.text.length > 0) ? YES : NO;
    }
}


#pragma mark - Action methods

- (void)cancelAction:(id)sender
{
    // flag ourselves that the user is cancelling
    // (used inside "setEditing" method to distinquish between a commit or cancel)
    //
    self.cancelling = YES;
    
    [self setEditing:NO animated:NO];
    
    self.cancelling = NO;
    
    // re-enable the "Edit" button since the user cancelled the last edit
    self.navigationItem.rightBarButtonItem.enabled = YES;
}


#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	// use the uncropped - uneditied image
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    if (originalImage != nil)
    {
        // adjust its orientation if necesary
        self.sourceImage = [self normalizedImage:originalImage];
        
        // update just our image cell in the table
        self.imageCell.imageView.image = self.sourceImage;
        
        [self.tableView reloadData];
    }
    
    [self dismissViewControllerAnimated:YES completion:^ {
         // picker finished closing, do what ever you need here
    }];
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // user tapped out of the text field, navigated to pick an image or tapped Cancel/Done
    if (!self.cancelling)
    {
        self.sourceName = textField.text;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // a document name is required to dismiss the keyboard
    if (textField.text.length > 0)
    {
        // dismiss the keyboard and toggle back to non edit (changes Done button to Edit)
        [textField resignFirstResponder];
        return YES;
    }
    else
    {
        return NO;
    }
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kDocImageSection)
    {
        if (self.tableView.editing)
        {
            // when in edit mode, open the image picker
            UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imagePickerController.delegate = self;
            imagePickerController.allowsEditing = NO;

            [self.navigationController presentViewController:imagePickerController animated:YES completion:^ {
                // image picker is done presenting
            }];
        }
        else if (self.imageCell.imageView.image != nil)
        {
            // when not in edit mode, just display the image
            ImageViewController *imageViewController =
                [self.storyboard instantiateViewControllerWithIdentifier:@"imageViewController"];
            imageViewController.image = self.imageCell.imageView.image;
            imageViewController.title = @"Image";
            
            [self.navigationController pushViewController:imageViewController animated:YES];
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

