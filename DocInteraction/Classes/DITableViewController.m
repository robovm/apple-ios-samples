/* 
     File: DITableViewController.m
 Abstract: The table view that display docs of different types.
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

#import "DITableViewController.h"

static NSString* documents[] =
{   @"Text Document.txt",
    @"Image Document.jpg",
    @"PDF Document.pdf",
    @"HTML Document.html"
};

#define NUM_DOCS 4
#define kRowHeight 58.0f

#pragma mark -

@interface DITableViewController () <QLPreviewControllerDataSource,
QLPreviewControllerDelegate,
DirectoryWatcherDelegate,
UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) DirectoryWatcher *docWatcher;
@property (nonatomic, strong) NSMutableArray *documentURLs;
@property (nonatomic, strong) UIDocumentInteractionController *docInteractionController;

@end

#pragma mark -

@implementation DITableViewController

- (void)setupDocumentControllerWithURL:(NSURL *)url
{
    //checks if docInteractionController has been initialized with the URL
    if (self.docInteractionController == nil)
    {
        self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
        self.docInteractionController.delegate = self;
    }
    else
    {
        self.docInteractionController.URL = url;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // start monitoring the document directory…
    self.docWatcher = [DirectoryWatcher watchFolderWithPath:[self applicationDocumentsDirectory] delegate:self];
    
    self.documentURLs = [NSMutableArray array];
    
    // scan for existing documents
    [self directoryDidChange:self.docWatcher];
}

- (void)viewDidUnload
{
    self.documentURLs = nil;
    self.docWatcher = nil;
}

// if we installed a custom UIGestureRecognizer (i.e. long-hold), then this would be called
//
- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressGesture
{
    if (longPressGesture.state == UIGestureRecognizerStateBegan)
    {
        NSIndexPath *cellIndexPath = [self.tableView indexPathForRowAtPoint:[longPressGesture locationInView:self.tableView]];
        
		NSURL *fileURL;
		if (cellIndexPath.section == 0)
        {
            // for section 0, we preview the docs built into our app
            fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:documents[cellIndexPath.row] ofType:nil]];
		}
        else
        {
            // for secton 1, we preview the docs found in the Documents folder
            fileURL = [self.documentURLs objectAtIndex:cellIndexPath.row];
		}
        self.docInteractionController.URL = fileURL;
		
		[self.docInteractionController presentOptionsMenuFromRect:longPressGesture.view.frame
                                                           inView:longPressGesture.view
                                                         animated:YES];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Initializing each section with a set of rows
    if (section == 0)
    {
        return NUM_DOCS;
    }
    else
    {
        return self.documentURLs.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    // setting headers for each section
    if (section == 0)
    {
        title = @"Example Documents";
    }
    else
    {
        if (self.documentURLs.count > 0)
            title = @"Documents folder";
    }
    
    return title;
}

- (UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSURL *fileURL;
    if (indexPath.section == 0)
    {
        // first section is our build-in documents
		fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:documents[indexPath.row] ofType:nil]];
    }
    else
    {
        // second section is the contents of the Documents folder
		fileURL = [self.documentURLs objectAtIndex:indexPath.row];
    }
	[self setupDocumentControllerWithURL:fileURL];
	
    // layout the cell
    cell.textLabel.text = [[fileURL path] lastPathComponent];
    NSInteger iconCount = [self.docInteractionController.icons count];
    if (iconCount > 0)
    {
        cell.imageView.image = [self.docInteractionController.icons objectAtIndex:iconCount - 1];
    }
    
    NSString *fileURLString = [self.docInteractionController.URL path];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURLString error:nil];
    NSInteger fileSize = [[fileAttributes objectForKey:NSFileSize] intValue];
    NSString *fileSizeStr = [NSByteCountFormatter stringFromByteCount:fileSize
                                                           countStyle:NSByteCountFormatterCountStyleFile];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", fileSizeStr, self.docInteractionController.UTI];
    
    // attach to our view any gesture recognizers that the UIDocumentInteractionController provides
    //cell.imageView.userInteractionEnabled = YES;
    //cell.contentView.gestureRecognizers = self.docInteractionController.gestureRecognizers;
    //
    // or
    // add a custom gesture recognizer in lieu of using the canned ones
    //
    UILongPressGestureRecognizer *longPressGesture =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [cell.imageView addGestureRecognizer:longPressGesture];
    cell.imageView.userInteractionEnabled = YES;    // this is by default NO, so we need to turn it on
    
    return cell;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kRowHeight;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // three ways to present a preview:
    // 1. Don't implement this method and simply attach the canned gestureRecognizers to the cell
    //
    // 2. Don't use canned gesture recognizers and simply use UIDocumentInteractionController's
    //      presentPreviewAnimated: to get a preview for the document associated with this cell
    //
    // 3. Use the QLPreviewController to give the user preview access to the document associated
    //      with this cell and all the other documents as well.
    
    // for case 2 use this, allowing UIDocumentInteractionController to handle the preview:
    /*
     NSURL *fileURL;
     if (indexPath.section == 0)
     {
     fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:documents[indexPath.row] ofType:nil]];
     }
     else
     {
     fileURL = [self.documentURLs objectAtIndex:indexPath.row];
     }
     [self setupDocumentControllerWithURL:fileURL];
     [self.docInteractionController presentPreviewAnimated:YES];
     */
    
    // for case 3 we use the QuickLook APIs directly to preview the document -
    QLPreviewController *previewController = [[QLPreviewController alloc] init];
    previewController.dataSource = self;
    previewController.delegate = self;
    
    // start previewing the document at the current section index
    previewController.currentPreviewItemIndex = indexPath.row;
    [[self navigationController] pushViewController:previewController animated:YES];
}


#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController
{
    return self;
}


#pragma mark - QLPreviewControllerDataSource

// Returns the number of items that the preview controller should preview
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController
{
    NSInteger numToPreview = 0;
    
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath.section == 0)
        numToPreview = NUM_DOCS;
    else
        numToPreview = self.documentURLs.count;
    
    return numToPreview;
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    // if the preview dismissed (done button touched), use this method to post-process previews
}

// returns the item that the preview controller should preview
- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx
{
    NSURL *fileURL = nil;
    
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath.section == 0)
    {
        fileURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:documents[idx] ofType:nil]];
    }
    else
    {
        fileURL = [self.documentURLs objectAtIndex:idx];
    }
    
    return fileURL;
}


#pragma mark - File system support

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
	[self.documentURLs removeAllObjects];    // clear out the old docs and start over
	
	NSString *documentsDirectoryPath = [self applicationDocumentsDirectory];
	
	NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath
                                                                                              error:NULL];
    
	for (NSString* curFileName in [documentsDirectoryContents objectEnumerator])
	{
		NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:curFileName];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		
		BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
		
        // proceed to add the document URL to our list (ignore the "Inbox" folder)
        if (!(isDirectory && [curFileName isEqualToString:@"Inbox"]))
        {
            [self.documentURLs addObject:fileURL];
        }
	}
	
	[self.tableView reloadData];
}

@end
