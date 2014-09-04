/*
    File:       GetController.m

    Contains:   Manages the GET tab.

    Written by: DTS

    Copyright:  Copyright (c) 2009-2012 Apple Inc. All Rights Reserved.

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

#import "GetController.h"

#import "NetworkManager.h"

#pragma mark * Utilities

#pragma mark * GetController

static NSString * kDefaultGetURLText = @"http://unpbook.com/small.gif";

@interface GetController () <UITextFieldDelegate>

@property (nonatomic, strong, readwrite) IBOutlet UITextField *             urlText;
@property (nonatomic, strong, readwrite) IBOutlet UIImageView *             imageView;
@property (nonatomic, strong, readwrite) IBOutlet UILabel *                 statusLabel;
@property (nonatomic, strong, readwrite) IBOutlet UIActivityIndicatorView * activityIndicator;
@property (nonatomic, strong, readwrite) IBOutlet UIBarButtonItem *         getOrCancelButton;

- (IBAction)getOrCancelAction:(id)sender;

// Properties that don't need to be seen by the outside world.

@property (nonatomic, assign, readonly ) BOOL                               isReceiving;
@property (nonatomic, strong, readwrite) NSURLConnection *                  connection;
@property (nonatomic, copy,   readwrite) NSString *                         filePath;
@property (nonatomic, strong, readwrite) NSOutputStream *                   fileStream;

@end

@implementation GetController

@synthesize connection    = _connection;
@synthesize filePath      = _filePath;
@synthesize fileStream    = _fileStream;

@synthesize urlText           = _urlText;
@synthesize imageView         = _imageView;
@synthesize statusLabel       = _statusLabel;
@synthesize activityIndicator = _activityIndicator;
@synthesize getOrCancelButton = _getOrCancelButton;

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

- (void)updateStatus:(NSString *)statusString
{
    assert(statusString != nil);
    self.statusLabel.text = statusString;
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
    // exchange is complete.  We look at the response to check that the HTTP 
    // status code is 2xx and that the Content-Type is acceptable.  If these checks 
    // fail, we give up on the transfer.
{
    #pragma unused(theConnection)
    NSHTTPURLResponse * httpResponse;
    NSString *          contentTypeHeader;

    assert(theConnection == self.connection);
    
    httpResponse = (NSHTTPURLResponse *) response;
    assert( [httpResponse isKindOfClass:[NSHTTPURLResponse class]] );
    
    if ((httpResponse.statusCode / 100) != 2) {
        [self stopReceiveWithStatus:[NSString stringWithFormat:@"HTTP error %zd", (ssize_t) httpResponse.statusCode]];
    } else {
        // -MIMEType strips any parameters, strips leading or trailer whitespace, and lower cases 
        // the string, so we can just use -isEqual: on the result.
        contentTypeHeader = [httpResponse MIMEType];
        if (contentTypeHeader == nil) {
            [self stopReceiveWithStatus:@"No Content-Type!"];
        } else if ( ! [contentTypeHeader isEqual:@"image/jpeg"] 
                 && ! [contentTypeHeader isEqual:@"image/png"] 
                 && ! [contentTypeHeader isEqual:@"image/gif"] ) {
            [self stopReceiveWithStatus:[NSString stringWithFormat:@"Unsupported Content-Type (%@)", contentTypeHeader]];
        } else {
            self.statusLabel.text = @"Response OK.";
        }
    }    
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)data
    // A delegate method called by the NSURLConnection as data arrives.  We just 
    // write the data to the file.
{
    #pragma unused(theConnection)
    NSInteger       dataLength;
    const uint8_t * dataBytes;
    NSInteger       bytesWritten;
    NSInteger       bytesWrittenSoFar;

    assert(theConnection == self.connection);
    
    dataLength = [data length];
    dataBytes  = [data bytes];

    bytesWrittenSoFar = 0;
    do {
        bytesWritten = [self.fileStream write:&dataBytes[bytesWrittenSoFar] maxLength:dataLength - bytesWrittenSoFar];
        assert(bytesWritten != 0);
        if (bytesWritten == -1) {
            [self stopReceiveWithStatus:@"File write error"];
            break;
        } else {
            bytesWrittenSoFar += bytesWritten;
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
    oldValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"GetURLText"];

    // Save the URL text if there is no pre-existing setting and it's not our 
    // default value, or if there is a pre-existing default and the new value 
    // is different.
    
    if (   ((oldValue == nil) && ! [newValue isEqual:kDefaultGetURLText] ) 
        || ((oldValue != nil) && ! [newValue isEqual:oldValue] ) ) {
        [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:@"GetURLText"];
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
    NSString *  defaultURLText;
    
    [super viewDidLoad];

    assert(self.urlText != nil);
    assert(self.imageView != nil);
    assert(self.statusLabel != nil);
    assert(self.activityIndicator != nil);
    assert(self.getOrCancelButton != nil);
    
    self.getOrCancelButton.possibleTitles = [NSSet setWithObjects:@"Get", @"Cancel", nil];

    // Set up the URL field to be the last value we saved (or the default value 
    // if we have none).
    
    defaultURLText = [[NSUserDefaults standardUserDefaults] stringForKey:@"GetURLText"];
    if (defaultURLText == nil) {
        defaultURLText = kDefaultGetURLText;
    }
    self.urlText.text = defaultURLText;
    
    self.activityIndicator.hidden = YES;
    self.statusLabel.text = @"Tap Get to start the GET";
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
    // Because NSURLConnection retains its delegate until the connection finishes, and 
    // any time the connection finishes we call -stopReceiveWithStatus: to clean everything 
    // up, we can't be deallocated with a connection in progress.
    assert(self->_connection == nil);
}

@end
