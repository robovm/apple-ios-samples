/*
    File:       QLogViewer.m

    Contains:   Displays in-memory QLog entries, with options to copy and mail the log.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "QLogViewer.h"

#import "QLog.h"

#import <MessageUI/MessageUI.h>

#include "zlib.h"

@interface QLogViewer () <UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

// private properties

@property (nonatomic, retain, readwrite) UIActionSheet *    actionSheet;
@property (nonatomic, retain, readwrite) UIAlertView *      alertView;

// forward declarations

- (void)dismissActionsAndAlerts;

@end

@implementation QLogViewer

- (id)init
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self != nil) {
        [[QLog log] addObserver:self forKeyPath:@"logEntries" options:0 context:&self->_logEntriesDummy];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }
    // You can enable the following to test how the QLog subsystem responds to entries being added; 
    // this is useful in situations where no entries are being added by other code.
    if (NO) {
        [NSTimer scheduledTimerWithTimeInterval:5.1 target:self selector:@selector(debugAddLogEntry) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)dealloc
{
    [[QLog log] removeObserver:self forKeyPath:@"logEntries"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    assert(self->_actionSheet == nil);          // should be gone at this point
    assert(self->_alertView == nil);            // should be gone at this point
    [super dealloc];
}

#pragma mark * General view controller stuff

- (void)willResignActive:(NSNotification *)note
    // Called in response to the UIApplicationWillResignActiveNotification. 
    // If an action sheet is up, dismiss it per the HI guidelines.
{
    #pragma unused(note)
    [self dismissActionsAndAlerts];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Configure the table view.
    
    self.tableView.allowsSelection = NO;
    self.tableView.rowHeight = 60.0f;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark * Updating

- (NSArray *)indexPathsForSection:(NSUInteger)section rowIndexSet:(NSIndexSet *)indexSet
    // Returns an array containing index path objects for each item in the 
    // index set, where the section of the index path is as specified by the 
    // parameter and the row of the index path is the index from the index set.
{
    NSMutableArray *    indexPaths;
    NSUInteger          currentIndex;

    assert(indexSet != nil);

    indexPaths = [NSMutableArray array];
    assert(indexPaths != nil);
    currentIndex = [indexSet firstIndex];
    while (currentIndex != NSNotFound) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:currentIndex inSection:section]];
        currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    return indexPaths;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &self->_logEntriesDummy) {
    
        // Respond to changes in the logEntries property of the QLog.
    
        assert([keyPath isEqual:@"logEntries"]);
        assert(object = [QLog log]);
        assert(change != nil);

        if (self.isViewLoaded) {
            NSIndexSet *    indexes;
            
            indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
            assert( (indexes == nil) || [indexes isKindOfClass:[NSIndexSet class]] );
            
            assert([change objectForKey:NSKeyValueChangeKindKey] != nil);
            switch ( [[change objectForKey:NSKeyValueChangeKindKey] intValue] ) {
                default:
                    assert(NO);
                case NSKeyValueChangeSetting: {
                    [self.tableView reloadData];
                } break;
                case NSKeyValueChangeInsertion: {
                    assert(indexes != nil);
                    [self.tableView insertRowsAtIndexPaths:[self indexPathsForSection:0 rowIndexSet:indexes] withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView flashScrollIndicators];
                } break;
                case NSKeyValueChangeRemoval: {
                    assert(indexes != nil);
                    [self.tableView deleteRowsAtIndexPaths:[self indexPathsForSection:0 rowIndexSet:indexes] withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView flashScrollIndicators];
                } break;
                case NSKeyValueChangeReplacement: {
                    assert(indexes != nil);
                    [self.tableView reloadRowsAtIndexPaths:[self indexPathsForSection:0 rowIndexSet:indexes] withRowAnimation:UITableViewRowAnimationNone];
                } break;
            }
        }
    } else if (NO) {   // Disabled because the super class does nothing useful with it.
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark * Table view callbacks

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tv)
    #pragma unused(section)
    assert(tv == self.tableView);
    assert(section == 0);

    return [[QLog log].logEntries count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)
    UITableViewCell *	cell;

    assert(tv == self.tableView);
    assert(indexPath != NULL);
    assert(indexPath.section == 0);
    assert(indexPath.row < [[QLog log].logEntries count]);

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"] autorelease];
        assert(cell != nil);
        
        cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
        cell.textLabel.numberOfLines = 3;
        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        
        // In the long term I'd like to have another view that lets you see a complete 
        // log entry.  But right now I've skipped that to save time.
        //
        // cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = [[QLog log].logEntries objectAtIndex:indexPath.row];

    return cell;
}

#pragma mark * Presentation

- (void)presentModallyOn:(UIViewController *)controller animated:(BOOL)animated
    // See comment in header.
{
    UINavigationController *    navController;
    
    navController = [[[UINavigationController alloc] initWithRootViewController:self] autorelease];
    assert(navController != nil);

    self.navigationItem.title = @"Log";
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionAction:)] autorelease];
    self.navigationItem.leftBarButtonItem  = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone   target:self action:@selector(doneAction:)  ] autorelease];

    [controller presentModalViewController:navController animated:animated];
}

#pragma mark * Log Wrangling

static BOOL gzwrite_all(gzFile file, const uint8_t * buffer, size_t bytesToWrite)
    // A wrapper around gzwrite that handles short writes.
{
    size_t  bytesWritten;
    int     byteWrittenThisTime;
    
    bytesWritten = 0;
    while (bytesWritten != bytesToWrite) {
        byteWrittenThisTime = gzwrite(file, &buffer[bytesWritten], bytesToWrite - bytesWritten);
        if (byteWrittenThisTime <= 0) {
            break;
        } else {
            bytesWritten += byteWrittenThisTime;
        }
    }
    
    return (bytesWritten == bytesToWrite);
}

- (NSData *)dataWithCompressedLog
    // Returns a data object that holds the gz compressed contents of the log.  The resulting 
    // data object is memory mapped to minimise the memory impact.
{
    NSData *        result;
    NSInputStream * logStream;
    off_t           logStreamLength;
    BOOL            success;
    int             err;
    NSString *      compressedLogPath;
    gzFile          compressedLogFile;
    off_t           bytesRemaining;
    
    result = nil;

    // Create the compressed file and get the uncompressed stream.
    
    compressedLogPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"CompressedLog.gz"];
    assert(compressedLogPath != NULL);
    
    logStream = [[QLog log] streamForLogValidToLength:&logStreamLength];
    success = (logStream != nil);
    
    if (success) {
        compressedLogFile = gzopen([compressedLogPath UTF8String], "wb");
        success = (compressedLogFile != NULL);
    }
    
    // Copy data from one to the other.
    
    if (success) {
        [logStream open];

        bytesRemaining = logStreamLength;
        while (bytesRemaining != 0) {
            uint8_t     buffer[32768];
            size_t      bytesToReadThisTime;
            NSInteger   bytesReadThisTime;

            if (bytesRemaining < sizeof(buffer)) {
                bytesToReadThisTime = (size_t) bytesRemaining;
            } else {
                bytesToReadThisTime = sizeof(buffer);
            }
            bytesReadThisTime = [logStream read:buffer maxLength:bytesToReadThisTime];
            if (bytesReadThisTime <= 0) {
                success = NO;
                break;
            }
            bytesRemaining -= bytesReadThisTime;
            
            success = gzwrite_all(compressedLogFile, buffer, bytesReadThisTime);
            if ( ! success ) {
                break;
            }
        }
        
        // Clean up.
        
        err = gzclose(compressedLogFile);
        success = success && (err == 0);

        [logStream close];
    }
    
    // Map the resulting file.  Once we've mapped the file we can remove it from the file system 
    // namespace; this avoids use having to give it a unique name.
    
    if (success) {
        result = [NSData dataWithContentsOfMappedFile:compressedLogPath];
        
        (void) [[NSFileManager defaultManager] removeItemAtPath:compressedLogPath error:NULL];
    }
    
    return result;
}

- (void)printLog
    // Prints the log to stderr.
{
    BOOL            success;
    NSInputStream * logStream;
    off_t           logStreamLength;
    off_t           bytesRemaining;
    
    // Get a stream to the log data.
    
    logStream = [[QLog log] streamForLogValidToLength:&logStreamLength];
    success = (logStream != nil);
    
    // Read the stream and write it to stderr.
    
    if (success) {
        [logStream open];

        bytesRemaining = logStreamLength;
        while (bytesRemaining != 0) {
            uint8_t     buffer[32768];
            size_t      bytesToReadThisTime;
            NSInteger   bytesReadThisTime;

            if (bytesRemaining < sizeof(buffer)) {
                bytesToReadThisTime = (size_t) bytesRemaining;
            } else {
                bytesToReadThisTime = sizeof(buffer);
            }
            bytesReadThisTime = [logStream read:buffer maxLength:bytesToReadThisTime];
            if (bytesReadThisTime <= 0) {
                success = NO;
                break;
            }
            bytesRemaining -= bytesReadThisTime;
            
            // We ignore any errors from fwrite.
            
            (void) fwrite(buffer, bytesReadThisTime, 1, stderr);
        }
        assert(success);
        
        [logStream close];
    }
}

#pragma mark * Actions

@synthesize actionSheet = _actionSheet;
@synthesize alertView   = _alertView;

- (void)dismissActionsAndAlerts
    // Cancel any visible action sheet or alert view.  Note that we only cancel an alert view 
    // if it has more than one button; a single button alert is informational and the user 
    // probably wants to see that info eventually.  OTOH, for alert views that have more than one 
    // button, we take the safe pass and choose the Cancel button.
{
    if (self.actionSheet != nil) {
        [self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:NO];
        assert(self.actionSheet == nil);
    }
    if ( (self.alertView != nil) && (self.alertView.numberOfButtons != 1) ) {
        [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:NO];
        assert(self.alertView == nil);
    }
}

- (void)showErrorMessage:(NSString *)message
    // Shows an alert view containing the specified error message.
{
    assert(self.alertView == nil);
    self.alertView = [[[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Drat!", nil] autorelease];
    assert(self.alertView != nil);
    
    self.alertView.cancelButtonIndex = 0;
    self.alertView.delegate = self;
    
    [self.alertView show];
}

enum {
    kActionSheetButtonIndexClear  = 0,
    kActionSheetButtonIndexCopy   = 1,
    kActionSheetButtonIndexPrint  = 2,
    kActionSheetButtonIndexMail   = 3,
    kActionSheetButtonIndexCancel = 4,
};

- (IBAction)actionAction:(id)sender
    // Called in response to the user tapping the Action button.  This puts up an 
    // alert sheet that lets the user choose what they'd like to do.
{
    #pragma unused(sender)
    NSString *          mailTitle;

    // Only include a "Mail Compressed Log" button if the device has Mail configured.
    
    if ([MFMailComposeViewController canSendMail]) {
        mailTitle = @"Mail Compressed Log";
    } else {
        mailTitle = nil;
    }
    assert(self.actionSheet == nil);
    self.actionSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clear" otherButtonTitles:@"Copy", @"Print to StdErr", mailTitle, nil] autorelease];
    assert(self.actionSheet != nil);

    [self.actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
    // Called when the action sheet goes away, where buttonIndex denotes the option 
    // chosen by the user.
{
    #pragma unused(actionSheet)
    assert(actionSheet == self.actionSheet);
    
    switch (buttonIndex) {
        case kActionSheetButtonIndexClear: {

            // The user tapped Clear; put up an alert view to confirm that.
            
            assert(self.alertView == nil);
            self.alertView = [[[UIAlertView alloc] initWithTitle:@"Clear Log?" message:@"Are you sure you want to clear the log completely?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Clear", nil] autorelease];
            assert(self.alertView != nil);
            
            self.alertView.delegate = self;
            
            [self.alertView show];
        } break;
        case kActionSheetButtonIndexCopy: {
            NSString *  logString;
            
            // The user tapped Copy; serialise the log to the pasteboard.
            
            logString = [[QLog log].logEntries componentsJoinedByString:@"\n"];
            assert(logString != nil);
            
            [UIPasteboard generalPasteboard].string = logString;
        } break;
        case kActionSheetButtonIndexPrint: {
        
            // The user tapped Print; print the log to stderr.
            
            [self printLog];
        } break;
        case kActionSheetButtonIndexMail: {     // actually equivalent to kActionSheetButtonIndexCancel if +canSendMail is NO
        
            // The user tapped Mail or, if mail is not availble, Cancel.  In the 
            // former case, put up the mail composer view.  In the latter case 
            // do nothing.
        
            if ([MFMailComposeViewController canSendMail]) {
                NSData *    logData;
            
                logData = [self dataWithCompressedLog];
                if (logData == nil) {
                    [self showErrorMessage:@"Could not create compressed log."];
                } else {
                    MFMailComposeViewController *   vc;
                    
                    vc = [[[MFMailComposeViewController alloc] init] autorelease];
                    assert(vc != nil);
                    
                    vc.mailComposeDelegate = self;
                    [vc setSubject:[NSString stringWithFormat:@"%@ Log", [[NSProcessInfo processInfo] processName]]];
                    [vc addAttachmentData:logData mimeType:@"application/x-gzip" fileName:[NSString stringWithFormat:@"%s.log.gz", getprogname()]];
                    
                    [self presentModalViewController:vc animated:YES];
                }
            }
        } break;
        default:
            assert(NO);
        case kActionSheetButtonIndexCancel: {
        
            // The user tapped Cancel; do nothing.
        } break;
    }
    
    self.actionSheet = nil;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
    // Called when an alert view is dismissed.  We have to handle one special case, described 
    // below.
{
    assert(alertView == self.alertView);
    #pragma unused(alertView)

    // There are two possible alert views, one that displays error messages and one 
    // that confirms the Clear action.  The former only has a Cancel button, so if we're 
    // dismissed with a button that's not the cancel button we clear the log.  Kinda 
    // yicky, but I'll live.
    
    if (buttonIndex != self.alertView.cancelButtonIndex) {
        [[QLog log] clear];
    }
    
    self.alertView = nil;
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
    // Called by the mail composer view when its done.  We report any errors and 
    // then dismiss the mail composer view.
{
    #pragma unused(controller)
    #pragma unused(error)
    
    switch (result) {
        default:
            assert(NO);
            // fall through
        case MFMailComposeResultCancelled:
        case MFMailComposeResultSaved:
        case MFMailComposeResultSent: {
            // do nothing
        } break;
        case MFMailComposeResultFailed: {
            [self showErrorMessage:@"Could not send mail."];
        } break;
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)doneAction:(id)sender
    // Called when the user taps Done in our navigation bar.  We just dismiss ourselves.
{
    #pragma unused(sender)
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)debugAddLogEntry
{
    static int sLogNumber;
    
    sLogNumber += 1;
    [[QLog log] logWithFormat:@"debugAddLogEntry blah blah blah %d", sLogNumber];
}

@end
