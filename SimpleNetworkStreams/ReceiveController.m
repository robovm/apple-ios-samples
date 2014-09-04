/*
    File:       ReceiveController.m

    Contains:   Manages the receive tab.

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

#import "ReceiveController.h"

#import "NetworkManager.h"
#import "QNetworkAdditions.h"

@interface ReceiveController () <NSStreamDelegate>

// stuff for IB

@property (nonatomic, strong, readwrite) IBOutlet UIImageView *             imageView;
@property (nonatomic, strong, readwrite) IBOutlet UILabel *                 statusLabel;
@property (nonatomic, strong, readwrite) IBOutlet UIActivityIndicatorView * activityIndicator;
@property (nonatomic, strong, readwrite) IBOutlet UIButton *                receiveOrCancelButton;

- (IBAction)receiveOrCancelAction:(id)sender;

// private properties

@property (nonatomic, assign, readonly ) BOOL               isReceiving;
@property (nonatomic, strong, readwrite) NSInputStream *    networkStream;
@property (nonatomic, copy,   readwrite) NSString *         filePath;
@property (nonatomic, strong, readwrite) NSOutputStream *   fileStream;

@end

@implementation ReceiveController

@synthesize networkStream = _networkStream;
@synthesize filePath      = _filePath;
@synthesize fileStream    = _fileStream;

@synthesize imageView             = _imageView;
@synthesize statusLabel           = _statusLabel;
@synthesize activityIndicator     = _activityIndicator;
@synthesize receiveOrCancelButton = _receiveOrCancelButton;

#pragma mark * Status management

// These methods are used by the core transfer code to update the UI.

- (void)receiveDidStart
{
    // Clear the current image so that we get a nice visual cue if the receive fails.
    self.imageView.image = [UIImage imageNamed:@"NoImage.png"];
    self.statusLabel.text = @"Receiving";
    [self.receiveOrCancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
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
        statusString = @"Receive succeeded";
    }
    self.statusLabel.text = statusString;
    [self.receiveOrCancelButton setTitle:@"Receive" forState:UIControlStateNormal];
    [self.activityIndicator stopAnimating];
    [[NetworkManager sharedInstance] didStopNetworkOperation];
}

#pragma mark * Core transfer code

// This is the code that actually does the networking.

- (BOOL)isReceiving
{
    return (self.networkStream != nil);
}

- (void)startReceive
{
    NSInputStream *     input;
    BOOL                success;
    NSNetService *      netService;
    
    assert(self.networkStream == nil);      // don't tap receive twice in a row!
    assert(self.fileStream == nil);         // ditto
    assert(self.filePath == nil);           // ditto

    // Open a stream for the file we're going to receive into.

    self.filePath = [[NetworkManager sharedInstance] pathForTemporaryFileWithPrefix:@"Receive"];
    assert(self.filePath != nil);
    
    self.fileStream = [NSOutputStream outputStreamToFileAtPath:self.filePath append:NO];
    assert(self.fileStream != nil);
    
    [self.fileStream open];

    // Open a stream to the server, finding the server via Bonjour.  Then configure 
    // the stream for async operation.

    netService = [[NSNetService alloc] initWithDomain:@"local." type:@"_x-SNSDownload._tcp." name:@"Test"];
    assert(netService != nil);

    // Until <rdar://problem/6868813> is fixed, we have to use our own code to open the streams 
    // rather than call -[NSNetService getInputStream:outputStream:].  See the comments in 
    // QNetworkAdditions.m for the details.

    success = [netService qNetworkAdditions_getInputStream:&input outputStream:NULL];
    assert(success);
    
    self.networkStream = input;
    self.networkStream.delegate = self;
    [self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.networkStream open];

    // Tell the UI we're receiving.
    
    [self receiveDidStart];
}

- (void)stopReceiveWithStatus:(NSString *)statusString
{
    if (self.networkStream != nil) {
        self.networkStream.delegate = nil;
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.networkStream close];
        self.networkStream = nil;
    }
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
    [self receiveDidStopWithStatus:statusString];
    self.filePath = nil;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
    // An NSStream delegate callback that's called when events happen on our 
    // network stream.
{
    assert(aStream == self.networkStream);
    #pragma unused(aStream)

    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self updateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSInteger       bytesRead;
            uint8_t         buffer[32768];

            [self updateStatus:@"Receiving"];
            
            // Pull some data off the network.
            
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead == -1) {
                [self stopReceiveWithStatus:@"Network read error"];
            } else if (bytesRead == 0) {
                [self stopReceiveWithStatus:nil];
            } else {
                NSInteger   bytesWritten;
                NSInteger   bytesWrittenSoFar;
                
                // Write to the file.
                
                bytesWrittenSoFar = 0;
                do {
                    bytesWritten = [self.fileStream write:&buffer[bytesWrittenSoFar] maxLength:bytesRead - bytesWrittenSoFar];
                    assert(bytesWritten != 0);
                    if (bytesWritten == -1) {
                        [self stopReceiveWithStatus:@"File write error"];
                        break;
                    } else {
                        bytesWrittenSoFar += bytesWritten;
                    }
                } while (bytesWrittenSoFar != bytesRead);
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventErrorOccurred: {
            [self stopReceiveWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

#pragma mark * Actions

- (IBAction)receiveOrCancelAction:(id)sender
{
    #pragma unused(sender)
    if (self.isReceiving) {
        [self stopReceiveWithStatus:@"Cancelled"];
    } else {
        [self startReceive];
    }
}

#pragma mark * View controller boilerplate

- (void)viewDidLoad
{
    [super viewDidLoad];
    assert(self.imageView != nil);
    assert(self.statusLabel != nil);
    assert(self.activityIndicator != nil);
    assert(self.receiveOrCancelButton != nil);
    
    self.activityIndicator.hidden = YES;
    self.statusLabel.text = @"Tap Receive to start receiving";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.imageView = nil;
    self.statusLabel = nil;
    self.activityIndicator = nil;
    self.receiveOrCancelButton = nil;
}

- (void)dealloc
{
    [self stopReceiveWithStatus:@"Stopped"];
}

@end
