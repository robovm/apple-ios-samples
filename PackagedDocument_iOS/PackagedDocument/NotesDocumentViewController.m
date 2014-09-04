/*
     File: NotesDocumentViewController.m
 Abstract: The view controller used for editing "NotesDocument".
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

#import "NotesDocumentViewController.h"
#import "ImageViewController.h"
#import "NotesDocument.h"
#import "AppDelegate.h"
#import "Note.h"

static NSString *TextFieldCellID = @"TextFieldCell";
static NSString *ImageViewCellID = @"ImageViewCell";
static NSString *TextViewCellID = @"TextViewCell";

// table view section index values
#define kDocNameSection     0
#define kDocImageSection    1
#define kDocNotesSection    2

// view tags to our UIControls inside each table view cell
#define kTextFieldViewTag   1
#define kTextViewViewTag    2


#pragma mark -

@interface NotesDocumentViewController ()  <UITextFieldDelegate,
                                            UITextViewDelegate,
                                            UINavigationControllerDelegate,
                                            UIImagePickerControllerDelegate>

@property (nonatomic, strong) NotesDocument *document;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

// cached references to our table cell controls
@property (nonatomic, weak) UITextField *textField; // document's name
@property (nonatomic, weak) UIImageView *imageView; // document's image
@property (nonatomic, weak) UITextView *textView;   // document's notes

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
        [self.document saveToURL:url forSaveOperation:UIDocumentSaveForCreating completionHandler:nil];
    }

    if (createNewFile)
    {
        // important: calling saveToURL for save operation "UIDocumentSaveForCreating" is
        // critical for new, unsaved documents.  Otherwise the next close operation will
        // not complete and no initial save is done!
        //
        [self.document saveToURL:self.document.fileURL
                forSaveOperation:UIDocumentSaveForCreating
               completionHandler:^(BOOL success) {
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
    [indView setColor:[self.navigationController.navigationBar tintColor]];
    [indView startAnimating];
    UIBarButtonItem *indViewItem = [[UIBarButtonItem alloc] initWithCustomView:indView];
    self.navigationItem.rightBarButtonItem = indViewItem;
    
    // set our view controller's title and data source to match our document name
    self.title = [[self.document.fileURL lastPathComponent] stringByDeletingPathExtension];
    
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
            self.sourceName = [[self.document.fileURL lastPathComponent] stringByDeletingPathExtension];
            
            // re-populate the table with our updated data source
            [self refreshTableSections];
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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // user dismissed duplicate alert below, revert the title field to the previous value
    NSString *originalFileName = [[self.document.fileURL lastPathComponent] stringByDeletingPathExtension];
    self.sourceName = self.textField.text = originalFileName;
}

- (BOOL)documentNameExists:(NSString *)documentName
{
    NSString *newFileName = [documentName stringByAppendingPathExtension:kFileExtension];
    NSURL *checkFileURL = [[AppDelegate localDocumentsDirectoryURL] URLByAppendingPathComponent:newFileName];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:[checkFileURL path] isDirectory:NO];
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
        // user has started editing (tapped Edit button)
        //
        // apply the Cancel button in place of the left back button
        self.navigationItem.leftBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                          target:self
                                                          action:@selector(cancelAction:)];
    }
    else
    {
        // user has finished editing (tapped either Done or Cancel buttons)
        //
        NSString *existingDocName = [[self.document.fileURL lastPathComponent] stringByDeletingPathExtension];
        
        if (self.cancelling)
        {
            // user tapped Cancel button,
            // so cancel all work, and revert to the current document's data
            //
            self.sourceImage = self.document.note.image;
            self.sourceName = existingDocName;
            self.sourceNotes = self.document.note.notes;
        }
        else
        {
            // is the document name on disk match what the user entered
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
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:message
                                                                    message:@"Please choose a different name."
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil];
                    [alert show];
                    
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
                                   self.title = [[renamedDocumentURL lastPathComponent] stringByDeletingPathExtension];
                                   
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
                // user has finished and wants to "commit all changes to disk
                //
                Note *note = self.document.note;
                note.image = self.imageView.image;
                note.notes = self.textView.text;
                
                // update our interim data source (to be reflected in our table cells)
                self.sourceImage = self.imageView.image;
                self.sourceName = self.textField.text;
                self.sourceNotes = self.textView.text;
                
                // trigger autosave of this document bump the change count
                [self.document updateChangeCount:UIDocumentChangeDone];
            }
        }
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
        
        // update the image cell indicator to reflect the edit state
        NSIndexPath *imageCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:kDocImageSection];
        UITableViewCell *imageCell = [self.tableView cellForRowAtIndexPath:imageCellIndexPath];
        imageCell.textLabel.text = editing ? @"Add or Edit" : @"";
        
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

// refresh the three sections in this table
- (void)refreshTableSections
{
    // force an update of these 3 table rows (more efficient than calling reloadData)
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:kDocNameSection],
                                             [NSIndexPath indexPathForRow:0 inSection:kDocImageSection],
                                             [NSIndexPath indexPathForRow:0 inSection:kDocNotesSection]]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
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
    
    // since the user cancelled the edit session, restore our table view to it's previous state
    [self refreshTableSections];
    
    // re-enable the "Edit" button since the user cancelled the last edit
    self.navigationItem.rightBarButtonItem.enabled = YES;
}


#pragma mark - UIImagePickerControllerDelegate

- (UIImage *)normalizedImage:(UIImage *)image
{
    UIImage *returnImage = nil;
    if (image != nil)
    {
        if (image.imageOrientation == UIImageOrientationUp) { return image; }
        
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        [image drawInRect:(CGRect){0, 0, image.size}];
        returnImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return returnImage;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	// use the uncropped - uneditied image
    UIImage *originalImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    if (originalImage)
    {
        // adjust its orientation if necesary
        self.sourceImage = [self normalizedImage:originalImage];
        
        // update just our image cell in the table
        NSIndexPath *imageCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:kDocImageSection];
        [self.tableView reloadRowsAtIndexPaths:@[imageCellIndexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [self dismissViewControllerAnimated:YES completion:^ {
         // picker finished closing
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


#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    if ([textView respondsToSelector:@selector(setTextContainerInset:)])
    {
        // keep scrolling to the end, if necessary
        [textView layoutIfNeeded];
        CGRect caretRect = [textView caretRectForPosition:textView.selectedTextRange.end];
        caretRect.size.height += textView.textContainerInset.bottom;
        [textView scrollRectToVisible:caretRect animated:NO];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;   // document name, image, and notes
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    switch (section)
    {
        case kDocNameSection:
            title = @"Name";
            break;
        case kDocImageSection:
            title = @"Image";
            break;
        case kDocNotesSection:
            title = @"Notes";
            break;
    }
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;
    
    switch (indexPath.section)
    {
        case kDocNameSection:
        {
            // the document name edit field
            cell = [self.tableView dequeueReusableCellWithIdentifier:TextFieldCellID forIndexPath:indexPath];
            _textField = (UITextField *)[cell viewWithTag:kTextFieldViewTag];
            self.textField.text = self.sourceName;
            break;
        }
            
        case kDocImageSection:
        {
            // the document image
            cell = [self.tableView dequeueReusableCellWithIdentifier:ImageViewCellID forIndexPath:indexPath];
            _imageView = cell.imageView;
            cell.imageView.image = self.sourceImage;
            break;
        }
            
        case kDocNotesSection:
        {
            // the document notes
            cell = [self.tableView dequeueReusableCellWithIdentifier:TextViewCellID forIndexPath:indexPath];
            _textView = (UITextView *)[cell viewWithTag:kTextViewViewTag];
            self.textView.text = self.sourceNotes;
            break;
        }
    }

    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = [self.tableView rowHeight];
    
    switch (indexPath.section)
    {
        case kDocImageSection:
            height = 90.0;      // image section row is bigger
            break;
        case kDocNotesSection:
            height = 167.0;     // notes section row is bigger
            break;
    }
    return height;
}

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
            // when in edit more, open the image picker
            if (self.imagePickerController == nil)
            {
                _imagePickerController = [[UIImagePickerController alloc] init];
                self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                self.imagePickerController.delegate = self;
                self.imagePickerController.allowsEditing = NO;
            }
            
            [self.navigationController presentViewController:self.imagePickerController animated:YES completion:^ {
                // image picker is done presenting
            }];
        }
        else if (self.imageView.image != nil)
        {
            // when not in edit mode, just display the image
            ImageViewController *imageViewController =
                [self.storyboard instantiateViewControllerWithIdentifier:@"imageViewController"];
            imageViewController.image = self.imageView.image;
            imageViewController.title = @"Image";
            
            [self.navigationController pushViewController:imageViewController animated:YES];
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

