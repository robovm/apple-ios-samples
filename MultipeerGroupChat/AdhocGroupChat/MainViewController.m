/*
     File: MainViewController.m
 Abstract: 
 This is the main view controller of the application.  It manages a iOS Messages like table view.  There are buttons for browsing for nearby peers and showing the a utility page. The table view data source is an array of Transcript objects which are created when sending or receving data (or image resources) via the MultipeerConnectivity data APIs.
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

@import MultipeerConnectivity;

#import "MainViewController.h"
#import "SessionContainer.h"
#import "SettingsViewController.h"
#import "Transcript.h"
#import "MessageView.h"
#import "ImageView.h"
#import "ProgressView.h"

// Constants for save/restore NSUserDefaults for the user entered display name and service type.
NSString * const kNSDefaultDisplayName = @"displayNameKey";
NSString * const kNSDefaultServiceType = @"serviceTypeKey";

@interface MainViewController () <MCBrowserViewControllerDelegate, SettingsViewControllerDelegate, UITextFieldDelegate, SessionContainerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

// Display name for local MCPeerID
@property (copy, nonatomic) NSString *displayName;
// Service type for discovery
@property (copy, nonatomic) NSString *serviceType;
// MC Session for managing peer state and send/receive data between peers
@property (retain, nonatomic) SessionContainer *sessionContainer;
// TableView Data source for managing sent/received messagesz
@property (retain, nonatomic) NSMutableArray *transcripts;
// Map of resource names to transcripts array index
@property (retain, nonatomic) NSMutableDictionary *imageNameIndex;
// Text field used for typing text messages to send to peers
@property (retain, nonatomic) IBOutlet UITextField *messageComposeTextField;
// Button for executing the message send.
@property (retain, nonatomic) IBOutlet UIBarButtonItem *sendMessageButton;

@end

@implementation MainViewController

#pragma mark - Override super class methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Init transcripts array to use as table view data source
    _transcripts = [NSMutableArray new];
    _imageNameIndex = [NSMutableDictionary new];
    
    // Get the display name and service type from the previous session (if any)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.displayName = [defaults objectForKey:kNSDefaultDisplayName];
    self.serviceType = [defaults objectForKey:kNSDefaultServiceType];

    if (self.displayName && self.serviceType) {
        // Show the service type (room name) as a title
        self.navigationItem.title = self.serviceType;
        // create the session
        [self createSession];
    }
    else {
        // first time running the application.  user needs to create the group chat service
        [self performSegueWithIdentifier:@"Room Create" sender:self];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Listen for will show/hide notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Stop listening for keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Room Create"]) {
        // Prepare the settings view where the user inputs the 'serviceType' and local peer 'displayName'
        UINavigationController *navController = segue.destinationViewController;
        SettingsViewController *viewController = (SettingsViewController *)navController.topViewController;
        viewController.delegate = self;
        // Pass the existing properties (if any) so the user can edit them.
        viewController.displayName = self.displayName;
        viewController.serviceType = self.serviceType;
    }
} 

#pragma mark - SettingsViewControllerDelegate methods

// Delegate method implementation handling return from the "Create Chat Room" pages
- (void)controller:(SettingsViewController *)controller didCreateChatRoomWithDisplayName:(NSString *)displayName serviceType:(NSString *)serviceType
{
    // Dismiss the modal view controller
    [self dismissViewControllerAnimated:YES completion:nil];

    // Cache these for MC session creation and changing later via the "info" button
    self.displayName = displayName;
    self.serviceType = serviceType;

    // Save these for subsequent app launches
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:displayName forKey:kNSDefaultDisplayName];
    [defaults setObject:serviceType forKey:kNSDefaultServiceType];
    [defaults synchronize];

    // Set the service type (aka Room Name) as the view controller title
    self.navigationItem.title = serviceType;

    // Create the session
    [self createSession];
}

#pragma mark - MCBrowserViewControllerDelegate methods

// Override this method to filter out peers based on application specific needs
- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController shouldPresentNearbyPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    return YES;
}

// Override this to know when the user has pressed the "done" button in the MCBrowserViewController
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

// Override this to know when the user has pressed the "cancel" button in the MCBrowserViewController
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SessionContainerDelegate

- (void)receivedTranscript:(Transcript *)transcript
{
    // Add to table view data source and update on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
		[self insertTranscript:transcript];
    });
}

- (void)updateTranscript:(Transcript *)transcript
{
    // Find the data source index of the progress transcript
    NSNumber *index = [_imageNameIndex objectForKey:transcript.imageName];
    NSUInteger idx = [index unsignedLongValue];
    // Replace the progress transcript with the image transcript
    [_transcripts replaceObjectAtIndex:idx withObject:transcript];

    // Reload this particular table view row on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

#pragma mark - private methods

// Private helper method for the Multipeer Connectivity local peerID, session, and advertiser.  This makes the application discoverable and ready to accept invitations
- (void)createSession
{
    // Create the SessionContainer for managing session related functionality.
    self.sessionContainer = [[SessionContainer alloc] initWithDisplayName:self.displayName serviceType:self.serviceType];
    // Set this view controller as the SessionContainer delegate so we can display incoming Transcripts and session state changes in our table view.
    _sessionContainer.delegate = self;
}

// Helper method for inserting a sent/received message into the data source and reload the view.
// Make sure you call this on the main thread
- (void)insertTranscript:(Transcript *)transcript
{
    // Add to the data source
    [_transcripts addObject:transcript];

    // If this is a progress transcript add it's index to the map with image name as the key
    if (nil != transcript.progress) {
        NSNumber *transcriptIndex = [NSNumber numberWithUnsignedLong:(_transcripts.count - 1)];
        [_imageNameIndex setObject:transcriptIndex forKey:transcript.imageName];
    }

    // Update the table view
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:([self.transcripts count] - 1) inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];

    // Scroll to the bottom so we focus on the latest message
    NSUInteger numberOfRows = [self.tableView numberOfRowsInSection:0];
    if (numberOfRows) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(numberOfRows - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma mark - Table view data source

// Only one section in this example
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
// The numer of rows is based on the count in the transcripts arrays
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.transcripts.count;
}

// The individual cells depend on the type of Transcript at a given row.  We have 3 row types (i.e. 3 custom cells) for text string messages, resource transfer progress, and completed image resources
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get the transcript for this row
    Transcript *transcript = [self.transcripts objectAtIndex:indexPath.row];

    // Check if it's an image progress, completed image, or text message
    UITableViewCell *cell;
    if (nil != transcript.imageUrl) {
        // It's a completed image
        cell = [tableView dequeueReusableCellWithIdentifier:@"Image Cell" forIndexPath:indexPath];
        // Get the image view
        ImageView *imageView = (ImageView *)[cell viewWithTag:IMAGE_VIEW_TAG];
        // Set up the image view for this transcript
        imageView.transcript = transcript;
    }
    else if (nil != transcript.progress) {
        // It's a resource transfer in progress
        cell = [tableView dequeueReusableCellWithIdentifier:@"Progress Cell" forIndexPath:indexPath];
        ProgressView *progressView = (ProgressView *)[cell viewWithTag:PROGRESS_VIEW_TAG];
        // Set up the progress view for this transcript
        progressView.transcript = transcript;
    }
    else {
        // Get the associated cell type for messages
        cell = [tableView dequeueReusableCellWithIdentifier:@"Message Cell" forIndexPath:indexPath];
        // Get the message view
        MessageView *messageView = (MessageView *)[cell viewWithTag:MESSAGE_VIEW_TAG];
        // Set up the message view for this transcript
        messageView.transcript = transcript;
    }
    return cell;
}

// Return the height of the row based on the type of transfer and custom view it contains
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Dynamically compute the label size based on cell type (image, image progress, or text message)
    Transcript *transcript = [self.transcripts objectAtIndex:indexPath.row];
    if (nil != transcript.imageUrl) {
        return [ImageView viewHeightForTranscript:transcript];
    }
    else if (nil != transcript.progress) {
        return [ProgressView viewHeightForTranscript:transcript];
    }
    else {
        return [MessageView viewHeightForTranscript:transcript];
    }
}

#pragma mark - IBAction methods

// Action method when pressing the "browse" (search icon).  It presents the MCBrowserViewController: a framework UI which enables users to invite and connect to other peers with the same room name (aka service type).
- (IBAction)browseForPeers:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Instantiate and present the MCBrowserViewController
    MCBrowserViewController *browserViewController = [[MCBrowserViewController alloc] initWithServiceType:self.serviceType session:self.sessionContainer.session];
                                                      
	browserViewController.delegate = self;
    browserViewController.minimumNumberOfPeers = kMCSessionMinimumNumberOfPeers;
    browserViewController.maximumNumberOfPeers = kMCSessionMaximumNumberOfPeers;

    [self presentViewController:browserViewController animated:YES completion:nil];
}

// Action method when user presses "send"
- (IBAction)sendMessageTapped:(id)sender
{    
    // Dismiss the keyboard.  Message will be actually sent when the keyboard resigns.
    [self.messageComposeTextField resignFirstResponder];
}

// Action method when user presses the "camera" photo icon.
- (IBAction)photoButtonTapped:(id)sender
{
    // Preset an action sheet which enables the user to take a new picture or select and existing one.
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"  destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose Existing", nil];
    
    // Show the action sheet
    [sheet showFromToolbar:self.navigationController.toolbar];
}

#pragma mark - UIActionSheetDelegate methods

// Override this method to know if user wants to take a new photo or select from the photo library
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];

    if (imagePicker) {
        // set the delegate and source type, and present the image picker
        imagePicker.delegate = self;
        if (0 == buttonIndex) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        }
        else if (1 == buttonIndex) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    else {
        // Problem with camera, alert user
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Camera" message:@"Please use a camera enabled device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - UIImagePickerViewControllerDelegate

// For responding to the user tapping Cancel.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

// Override this delegate method to get the image that the user has selected and send it view Multipeer Connectivity to the connected peers.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];

    // Don't block the UI when writing the image to documents
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // We only handle a still image
        UIImage *imageToSave = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];

        // Save the new image to the documents directory
        NSData *pngData = UIImageJPEGRepresentation(imageToSave, 1.0);

        // Create a unique file name
        NSDateFormatter *inFormat = [NSDateFormatter new];
        [inFormat setDateFormat:@"yyMMdd-HHmmss"];
        NSString *imageName = [NSString stringWithFormat:@"image-%@.JPG", [inFormat stringFromDate:[NSDate date]]];
        // Create a file path to our documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];
        [pngData writeToFile:filePath atomically:YES]; // Write the file
        // Get a URL for this file resource
        NSURL *imageUrl = [NSURL fileURLWithPath:filePath];

        // Send the resource to the remote peers and get the resulting progress transcript
        Transcript *transcript = [self.sessionContainer sendImage:imageUrl];

        // Add the transcript to the data source and reload
        dispatch_async(dispatch_get_main_queue(), ^{
            [self insertTranscript:transcript];
        });
    });
}


#pragma mark - UITextFieldDelegate methods

// Override to dynamically enable/disable the send button based on user typing
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger length = self.messageComposeTextField.text.length - range.length + string.length;
    if (length > 0) {
        self.sendMessageButton.enabled = YES;
    }
    else {
        self.sendMessageButton.enabled = NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField endEditing:YES];
    return YES;
}

// Delegate method called when the message text field is resigned. 
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Check if there is any message to send
    if (self.messageComposeTextField.text.length) {
        // Resign the keyboard
        [textField resignFirstResponder];
        
        // Send the message
        Transcript *transcript = [self.sessionContainer sendMessage:self.messageComposeTextField.text];

        if (transcript) {
            // Add the transcript to the table view data source and reload
            [self insertTranscript:transcript];
        }
        
        // Clear the textField and disable the send button
        self.messageComposeTextField.text = @"";
        self.sendMessageButton.enabled = NO;
    }
}

#pragma mark - Toolbar animation helpers

// Helper method for moving the toolbar frame based on user action
- (void)moveToolBarUp:(BOOL)up forKeyboardNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];

    // Get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];

    // Animate up or down
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];

    [self.navigationController.toolbar setFrame:CGRectMake(self.navigationController.toolbar.frame.origin.x, self.navigationController.toolbar.frame.origin.y + (keyboardFrame.size.height * (up ? -1 : 1)), self.navigationController.toolbar.frame.size.width, self.navigationController.toolbar.frame.size.height)];
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    // move the toolbar frame up as keyboard animates into view
    [self moveToolBarUp:YES forKeyboardNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // move the toolbar frame down as keyboard animates into view
    [self moveToolBarUp:NO forKeyboardNotification:notification];
}

@end
