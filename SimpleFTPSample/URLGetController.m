/*
     File: URLGetController.m
 Abstract: Manages the URL Get tab.
  Version: 1.4
 
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

#import "URLGetController.h"

#import "NetworkManager.h"

#pragma mark * URLGetController

@interface URLGetController () <UITextFieldDelegate, NSURLConnectionDataDelegate>

// things for IB

@property (nonatomic, strong, readwrite) IBOutlet UITextField *               urlText;
@property (nonatomic, strong, readwrite) IBOutlet UIImageView *               imageView;
@property (nonatomic, strong, readwrite) IBOutlet UILabel *                   statusLabel;
@property (nonatomic, strong, readwrite) IBOutlet UIActivityIndicatorView *   activityIndicator;
@property (nonatomic, strong, readwrite) IBOutlet UIBarButtonItem *           getOrCancelButton;

- (IBAction)getOrCancelAction:(id)sender;

// Properties that don't need to be seen by the outside world.

@property (nonatomic, assign, readonly ) BOOL              isReceiving;
@property (nonatomic, strong, readwrite) NSURLConnection * connection;
@property (nonatomic, copy,   readwrite) NSString *        filePath;
@property (nonatomic, strong, readwrite) NSOutputStream *  fileStream;

@end

@implementation URLGetController

#pragma mark * Status management

// These methods are used by the core transfer code to update the UI.

- (void)receiveDidStart
{
    // Clear the current image so that we get a nice visual cue if the receive fails.
    self.imageView.image = [UIImage imageNamed:@"NoImage.png"];
    self.statusLabel.text = @"Receiving";
    self.getOrCancelButton.title = @"Cancel";
    [self.activityIndicator startAnimating];
    [[NetworkManager sharedInstance] didStartNetworkOperation];
}

- (void)receiveDidStopWithStatus:(NSString *)statusString
{
    if (statusString == nil) {
        assert(self.filePath != nil);
        self.imageView.image = [UIImage imageWithContentsOfFile:self.filePath];
        statusString = @"GET succeeded";
    }
    self.statusLabel.text = statusString;
    self.getOrCancelButton.title = @"Get";
    [self.activityIndicator stopAnimating];
    [[NetworkManager sharedInstance] didStopNetworkOperation];
}

#pragma mark * Core transfer code

// This is the code that actually does the networking.

- (BOOL)isReceiving
{
    return (self.connection != nil);
}

- (void)startReceive
    // Starts a connection to download the current URL.
{
    BOOL                success;
    NSURL *             url;
    NSURLRequest *      request;
    
    assert(self.connection == nil);         // don't tap receive twice in a row!
    assert(self.fileStream == nil);         // ditto
    assert(self.filePath == nil);           // ditto

    // First get and check the URL.
    
    url = [[NetworkManager sharedInstance] smartURLForString:self.urlText.text];
    success = (url != nil);

    // If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
        self.statusLabel.text = @"Invalid URL";
    } else if ( ! [[NetworkManager sharedInstance] isImageURL:url] ) {
        self.statusLabel.text = @"Can only get images";
    } else {

        // Open a stream for the file we're going to receive into.

        self.filePath = [[NetworkManager sharedInstance] pathForTemporaryFileWithPrefix:@"Get"];
        assert(self.filePath != nil);
        
        self.fileStream = [NSOutputStream outputStreamToFileAtPath:self.filePath append:NO];
        assert(self.fileStream != nil);
        
        [self.fileStream open];

        // Open a connection for the URL.

        request = [NSURLRequest requestWithURL:url];
        assert(request != nil);
        
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
        assert(self.connection != nil);

        // Tell the UI we're receiving.
        
        [self receiveDidStart];
    }
}

- (void)stopReceiveWithStatus:(NSString *)statusString
    // Shuts down the connection and displays the result (statusString == nil) 
    // or the error status (otherwise).
{
    if (self.connection != nil) {
        [self.connection cancel];
        self.connection = nil;
    }
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
    [self receiveDidStopWithStatus:statusString];
    self.filePath = nil;
}

- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSURLResponse *)response
    // A delegate method called by the NSURLConnection when the request/response 
    // exchange is complete.
    //
    // For an HTTP request you would check [response statusCode] and [response MIMEType] to 
    // verify that this is acceptable data, but for an FTP request there is no status code 
    // and the type value is derived from the extension so you might as well pre-flight that.
    //
    // You could, use this opportunity to get [response expectedContentLength] and 
    // [response suggestedFilename], but I don't need either of these values for 
    // this sample.
{
    #pragma unused(theConnection)
    #pragma unused(response)

    assert(theConnection == self.connection);
    assert(response != nil);
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)data
    // A delegate method called by the NSURLConnection as data arrives.  We just 
    // write the data to the file.
{
    #pragma unused(theConnection)
    NSUInteger      dataLength;
    const uint8_t * dataBytes;
    NSInteger       bytesWritten;
    NSUInteger      bytesWrittenSoFar;

    assert(theConnection == self.connection);
    
    dataLength = [data length];
    dataBytes  = [data bytes];

    bytesWrittenSoFar = 0;
    do {
        bytesWritten = [self.fileStream write:&dataBytes[bytesWrittenSoFar] maxLength:dataLength - bytesWrittenSoFar];
        assert(bytesWritten != 0);
        if (bytesWritten <= 0) {
            [self stopReceiveWithStatus:@"File write error"];
            break;
        } else {
            bytesWrittenSoFar += (NSUInteger) bytesWritten;
        }
    } while (bytesWrittenSoFar != dataLength);
}

- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error
    // A delegate method called by the NSURLConnection if the connection fails. 
    // We shut down the connection and display the failure.  Production quality code 
    // would either display or log the actual error.
{
    #pragma unused(theConnection)
    #pragma unused(error)
    assert(theConnection == self.connection);
    
    [self stopReceiveWithStatus:@"Connection failed"];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection
    // A delegate method called by the NSURLConnection when the connection has been 
    // done successfully.  We shut down the connection with a nil status, which 
    // causes the image to be displayed.
{
    #pragma unused(theConnection)
    assert(theConnection == self.connection);
    
    [self stopReceiveWithStatus:nil];
}

#pragma mark * UI Actions

- (IBAction)getOrCancelAction:(id)sender
{
    #pragma unused(sender)
    if (self.isReceiving) {
        [self stopReceiveWithStatus:@"Cancelled"];
    } else {
        [self startReceive];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
    // A delegate method called by the URL text field when the editing is complete. 
    // We save the current value of the field in our settings.
{
    #pragma unused(textField)
    NSString *  newValue;
    NSString *  oldValue;
    
    assert(textField == self.urlText);

    newValue = self.urlText.text;
    oldValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"URLGetURLText"];

    // Save the URL text if it's changed.
    
    assert(newValue != nil);        // what is UITextField thinking!?!
    assert(oldValue != nil);        // because we registered a default
    
    if ( ! [newValue isEqual:oldValue] ) {
        [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:@"URLGetURLText"];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
    // A delegate method called by the URL text field when the user taps the Return 
    // key.  We just dismiss the keyboard.
{
    #pragma unused(textField)
    assert(textField == self.urlText);
    [self.urlText resignFirstResponder];
    return NO;
}

#pragma mark * View controller boilerplate

- (void)viewDidLoad
{
    [super viewDidLoad];

    assert(self.urlText != nil);
    assert(self.imageView != nil);
    assert(self.statusLabel != nil);
    assert(self.activityIndicator != nil);
    assert(self.getOrCancelButton != nil);
    
    self.getOrCancelButton.possibleTitles = [NSSet setWithObjects:@"Get", @"Cancel", nil];

    self.urlText.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"URLGetURLText"];
    
    self.activityIndicator.hidden = YES;
    self.statusLabel.text = @"Tap Get to start getting";
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.urlText = nil;
    self.imageView = nil;
    self.statusLabel = nil;
    self.activityIndicator = nil;
    self.getOrCancelButton = nil;
}

- (void)dealloc
{
    [self stopReceiveWithStatus:@"Stopped"];
}

@end
