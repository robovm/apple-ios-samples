/*
    File:       PostController.m

    Contains:   Manages the POST tab.

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

#import "PostController.h"

#import "NetworkManager.h"

#include <sys/socket.h>
#include <unistd.h>

#include <CFNetwork/CFNetwork.h>

#pragma mark * Utilities

static void CFStreamCreateBoundPairCompat(
    CFAllocatorRef      alloc, 
    CFReadStreamRef *   readStreamPtr, 
    CFWriteStreamRef *  writeStreamPtr, 
    CFIndex             transferBufferSize
)
    // This is a drop-in replacement for CFStreamCreateBoundPair that is necessary because that 
    // code is broken on iOS versions prior to iOS 5.0 <rdar://problem/7027394> <rdar://problem/7027406>.  
    // This emulates a bound pair by creating a pair of UNIX domain sockets and wrapper each end in a 
    // CFSocketStream.  This won't give great performance, but it doesn't crash!
{
    #pragma unused(transferBufferSize)
    int                 err;
    Boolean             success;
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;
    int                 fds[2];
    
    assert(readStreamPtr != NULL);
    assert(writeStreamPtr != NULL);
    
    readStream = NULL;
    writeStream = NULL;
    
    // Create the UNIX domain socket pair.
    
    err = socketpair(AF_UNIX, SOCK_STREAM, 0, fds);
    if (err == 0) {
        CFStreamCreatePairWithSocket(alloc, fds[0], &readStream,  NULL);
        CFStreamCreatePairWithSocket(alloc, fds[1], NULL, &writeStream);
        
        // If we failed to create one of the streams, ignore them both.
        
        if ( (readStream == NULL) || (writeStream == NULL) ) {
            if (readStream != NULL) {
                CFRelease(readStream);
                readStream = NULL;
            }
            if (writeStream != NULL) {
                CFRelease(writeStream);
                writeStream = NULL;
            }
        }
        assert( (readStream == NULL) == (writeStream == NULL) );
        
        // Make sure that the sockets get closed (by us in the case of an error, 
        // or by the stream if we managed to create them successfull).
        
        if (readStream == NULL) {
            err = close(fds[0]);
            assert(err == 0);
            err = close(fds[1]);
            assert(err == 0);
        } else {
            success = CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            assert(success);
            success = CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            assert(success);
        }
    }
    
    *readStreamPtr = readStream;
    *writeStreamPtr = writeStream;
}

// A category on NSStream that provides a nice, Objective-C friendly way to create 
// bound pairs of streams.

@interface NSStream (BoundPairAdditions)
+ (void)createBoundInputStream:(NSInputStream **)inputStreamPtr outputStream:(NSOutputStream **)outputStreamPtr bufferSize:(NSUInteger)bufferSize;
@end

@implementation NSStream (BoundPairAdditions)

+ (void)createBoundInputStream:(NSInputStream **)inputStreamPtr outputStream:(NSOutputStream **)outputStreamPtr bufferSize:(NSUInteger)bufferSize
{
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;

    assert( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) );

    readStream = NULL;
    writeStream = NULL;

    #if defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && (__MAC_OS_X_VERSION_MIN_REQUIRED < 1070)
        #error If you support Mac OS X prior to 10.7, you must re-enable CFStreamCreateBoundPairCompat.
    #endif
    #if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && (__IPHONE_OS_VERSION_MIN_REQUIRED < 50000)
        #error If you support iOS prior to 5.0, you must re-enable CFStreamCreateBoundPairCompat.
    #endif

    if (NO) {
        CFStreamCreateBoundPairCompat(
            NULL, 
            ((inputStreamPtr  != nil) ? &readStream : NULL),
            ((outputStreamPtr != nil) ? &writeStream : NULL), 
            (CFIndex) bufferSize
        );
    } else {
        CFStreamCreateBoundPair(
            NULL, 
            ((inputStreamPtr  != nil) ? &readStream : NULL),
            ((outputStreamPtr != nil) ? &writeStream : NULL), 
            (CFIndex) bufferSize
        );
    }
    
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = CFBridgingRelease(readStream);
    }
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = CFBridgingRelease(writeStream);
    }
}

@end
        
#pragma mark * PostController

enum {
    kPostBufferSize = 32768
};

#if TARGET_IPHONE_SIMULATOR
    static NSString * kDefaultPostURLText = @"http://localhost:9000/cgi-bin/PostIt.py";
#else
    static NSString * kDefaultPostURLText = @"";
#endif

@interface PostController () <UITextFieldDelegate, NSStreamDelegate>

@property (nonatomic, strong, readwrite) IBOutlet UITextField *               urlText;
@property (nonatomic, strong, readwrite) IBOutlet UILabel *                   statusLabel;
@property (nonatomic, strong, readwrite) IBOutlet UIActivityIndicatorView *   activityIndicator;
@property (nonatomic, strong, readwrite) IBOutlet UIBarButtonItem *           cancelButton;

- (IBAction)sendAction:(UIView *)sender;
- (IBAction)cancelAction:(id)sender;

// Properties that don't need to be seen by the outside world.

@property (nonatomic, assign, readonly ) BOOL               isSending;
@property (nonatomic, strong, readwrite) NSURLConnection *  connection;
@property (nonatomic, copy,   readwrite) NSData *           bodyPrefixData;
@property (nonatomic, strong, readwrite) NSInputStream *    fileStream;
@property (nonatomic, copy,   readwrite) NSData *           bodySuffixData;
@property (nonatomic, strong, readwrite) NSOutputStream *   producerStream;
@property (nonatomic, strong, readwrite) NSInputStream *    consumerStream;
@property (nonatomic, assign, readwrite) const uint8_t *    buffer;
@property (nonatomic, assign, readwrite) uint8_t *          bufferOnHeap;
@property (nonatomic, assign, readwrite) size_t             bufferOffset;
@property (nonatomic, assign, readwrite) size_t             bufferLimit;

@end

@implementation PostController

@synthesize connection      = _connection;
@synthesize bodyPrefixData  = _bodyPrefixData;
@synthesize fileStream      = _fileStream;
@synthesize bodySuffixData  = _bodySuffixData;
@synthesize producerStream  = _producerStream;
@synthesize consumerStream  = _consumerStream;
@synthesize buffer          = _buffer;
@synthesize bufferOnHeap    = _bufferOnHeap;
@synthesize bufferOffset    = _bufferOffset;
@synthesize bufferLimit     = _bufferLimit;

@synthesize urlText           = _urlText;
@synthesize statusLabel       = _statusLabel;
@synthesize activityIndicator = _activityIndicator;
@synthesize cancelButton      = _cancelButton;

#pragma mark * Status management

// These methods are used by the core transfer code to update the UI.

- (void)sendDidStart
{
    self.statusLabel.text = @"Sending";
    self.cancelButton.enabled = YES;
    [self.activityIndicator startAnimating];
    [[NetworkManager sharedInstance] didStartNetworkOperation];
}

- (void)sendDidStopWithStatus:(NSString *)statusString
{
    if (statusString == nil) {
        statusString = @"POST succeeded";
    }
    self.statusLabel.text = statusString;
    self.cancelButton.enabled = NO;
    [self.activityIndicator stopAnimating];
    [[NetworkManager sharedInstance] didStopNetworkOperation];
}

#pragma mark * Core transfer code

// This is the code that actually does the networking.

- (BOOL)isSending
{
    return (self.connection != nil);
}

- (NSString *)generateBoundaryString
{
    CFUUIDRef       uuid;
    CFStringRef     uuidStr;
    NSString *      result;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFUUIDCreateString(NULL, uuid);
    assert(uuidStr != NULL);
    
    result = [NSString stringWithFormat:@"Boundary-%@", uuidStr];
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    
    return result;
}

- (void)startSend:(NSString *)filePath
{
    BOOL                    success;
    NSURL *                 url;
    NSMutableURLRequest *   request;
    NSString *              boundaryStr;
    NSString *              contentType;
    NSString *              bodyPrefixStr;
    NSString *              bodySuffixStr;
    NSNumber *              fileLengthNum;
    unsigned long long      bodyLength;
    NSInputStream *         consStream;
    NSOutputStream *        prodStream;
    
    assert(filePath != nil);
    assert([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
    assert( [filePath.pathExtension isEqual:@"png"] || [filePath.pathExtension isEqual:@"jpg"] );
    
    assert(self.connection == nil);         // don't tap send twice in a row!
    assert(self.bodyPrefixData == nil);     // ditto
    assert(self.fileStream == nil);         // ditto
    assert(self.bodySuffixData == nil);     // ditto
    assert(self.consumerStream == nil);     // ditto
    assert(self.producerStream == nil);     // ditto
    assert(self.buffer == NULL);            // ditto
    assert(self.bufferOnHeap == NULL);      // ditto

    // First get and check the URL.
    
    url = [[NetworkManager sharedInstance] smartURLForString:self.urlText.text];
    success = (url != nil);

    // If the URL is bogus, let the user know.  Otherwise kick off the connection.

    if ( ! success) {
        self.statusLabel.text = @"Invalid URL";
    } else {
        // Determine the MIME type of the file.
        
        if ( [filePath.pathExtension isEqual:@"png"] ) {
            contentType = @"image/png";
        } else if ( [filePath.pathExtension isEqual:@"jpg"] ) {
            contentType = @"image/jpeg";
        } else if ( [filePath.pathExtension isEqual:@"gif"] ) {
            contentType = @"image/gif";
        } else {
            assert(NO);
            contentType = nil;          // quieten a warning
        }

        // Calculate the multipart/form-data body.  For more information about the 
        // format of the prefix and suffix, see:
        //
        // o HTML 4.01 Specification
        //   Forms
        //   <http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4>
        //
        // o RFC 2388 "Returning Values from Forms: multipart/form-data"
        //   <http://www.ietf.org/rfc/rfc2388.txt>
        
        boundaryStr = [self generateBoundaryString];
        assert(boundaryStr != nil);

        bodyPrefixStr = [NSString stringWithFormat:
            @
            // empty preamble
            "\r\n"
            "--%@\r\n"
            "Content-Disposition: form-data; name=\"fileContents\"; filename=\"%@\"\r\n"
            "Content-Type: %@\r\n"
            "\r\n",
            boundaryStr,
            [filePath lastPathComponent],       // +++ very broken for non-ASCII
            contentType
        ];
        assert(bodyPrefixStr != nil);

        bodySuffixStr = [NSString stringWithFormat:
            @
            "\r\n"
            "--%@\r\n"
            "Content-Disposition: form-data; name=\"uploadButton\"\r\n"
            "\r\n"
            "Upload File\r\n"
            "--%@--\r\n" 
            "\r\n"
            //empty epilogue
            ,
            boundaryStr, 
            boundaryStr
        ];
        assert(bodySuffixStr != nil);

        self.bodyPrefixData = [bodyPrefixStr dataUsingEncoding:NSASCIIStringEncoding];
        assert(self.bodyPrefixData != nil);
        self.bodySuffixData = [bodySuffixStr dataUsingEncoding:NSASCIIStringEncoding];
        assert(self.bodySuffixData != nil);

        fileLengthNum = (NSNumber *) [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL] objectForKey:NSFileSize];
        assert( [fileLengthNum isKindOfClass:[NSNumber class]] );

        bodyLength =
              (unsigned long long) [self.bodyPrefixData length]
            + [fileLengthNum unsignedLongLongValue]
            + (unsigned long long) [self.bodySuffixData length];
        
        // Open a stream for the file we're going to send.  We open this stream 
        // straight away because there's no need to delay.
        
        self.fileStream = [NSInputStream inputStreamWithFileAtPath:filePath];
        assert(self.fileStream != nil);
        
        [self.fileStream open];
        
        // Open producer/consumer streams.  We open the producerStream straight 
        // away.  We leave the consumerStream alone; NSURLConnection will deal 
        // with it.
        
        [NSStream createBoundInputStream:&consStream outputStream:&prodStream bufferSize:32768];
        assert(consStream != nil);
        assert(prodStream != nil);
        self.consumerStream = consStream;
        self.producerStream = prodStream;
        
        self.producerStream.delegate = self;
        [self.producerStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.producerStream open];
        
        // Set up our state to send the body prefix first.
        
        self.buffer      = [self.bodyPrefixData bytes];
        self.bufferLimit = [self.bodyPrefixData length];
        
        // Open a connection for the URL, configured to POST the file.

        request = [NSMutableURLRequest requestWithURL:url];
        assert(request != nil);
        
        [request setHTTPMethod:@"POST"];
        [request setHTTPBodyStream:self.consumerStream];
        
        [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=\"%@\"", boundaryStr] forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%llu", bodyLength] forHTTPHeaderField:@"Content-Length"];
        
        self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
        assert(self.connection != nil);
        
        // Tell the UI we're sending.
        
        [self sendDidStart];
    }
}

- (void)stopSendWithStatus:(NSString *)statusString
{
    if (self.bufferOnHeap) {
        free(self.bufferOnHeap);
        self.bufferOnHeap = NULL;
    }
    self.buffer = NULL;
    self.bufferOffset = 0;
    self.bufferLimit  = 0;
    if (self.connection != nil) {
        [self.connection cancel];
        self.connection = nil;
    }
    self.bodyPrefixData = nil;
    if (self.producerStream != nil) {
        self.producerStream.delegate = nil;
        [self.producerStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.producerStream close];
        self.producerStream = nil;
    }
    self.consumerStream = nil;
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
    self.bodySuffixData = nil;
    [self sendDidStopWithStatus:statusString];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
    // An NSStream delegate callback that's called when events happen on our 
    // network stream.
{
    #pragma unused(aStream)
    assert(aStream == self.producerStream);

    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            // NSLog(@"producer stream opened");
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            // Check to see if we've run off the end of our buffer.  If we have, 
            // work out the next buffer of data to send.
            
            if (self.bufferOffset == self.bufferLimit) {

                // See if we're transitioning from the prefix to the file data.
                // If so, allocate a file buffer.
                
                if (self.bodyPrefixData != nil) {
                    self.bodyPrefixData = nil;

                    assert(self.bufferOnHeap == NULL);
                    self.bufferOnHeap = malloc(kPostBufferSize);
                    assert(self.bufferOnHeap != NULL);
                    self.buffer = self.bufferOnHeap;
                    
                    self.bufferOffset = 0;
                    self.bufferLimit  = 0;
                }
                
                // If we still have file data to send, read the next chunk. 
                
                if (self.fileStream != nil) {
                    NSInteger   bytesRead;
                    
                    bytesRead = [self.fileStream read:self.bufferOnHeap maxLength:kPostBufferSize];
                    
                    if (bytesRead == -1) {
                        [self stopSendWithStatus:@"File read error"];
                    } else if (bytesRead != 0) {
                        self.bufferOffset = 0;
                        self.bufferLimit  = bytesRead;
                    } else {
                        // If we hit the end of the file, transition to sending the 
                        // suffix.

                        [self.fileStream close];
                        self.fileStream = nil;
                        
                        assert(self.bufferOnHeap != NULL);
                        free(self.bufferOnHeap);
                        self.bufferOnHeap = NULL;
                        self.buffer       = [self.bodySuffixData bytes];

                        self.bufferOffset = 0;
                        self.bufferLimit  = [self.bodySuffixData length];
                    }
                }
                
                // If we've failed to produce any more data, we close the stream 
                // to indicate to NSURLConnection that we're all done.  We only do 
                // this if producerStream is still valid to avoid running it in the 
                // file read error case.
                
                if ( (self.bufferOffset == self.bufferLimit) && (self.producerStream != nil) ) {
                    // We set our delegate callback to nil because we don't want to 
                    // be called anymore for this stream.  However, we can't 
                    // remove the stream from the runloop (doing so prevents the 
                    // URL from ever completing) and nor can we nil out our 
                    // stream reference (that causes all sorts of wacky crashes). 
                    //
                    // +++ Need bug numbers for these problems.
                    self.producerStream.delegate = nil;
                    // [self.producerStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                    [self.producerStream close];
                    // self.producerStream = nil;
                }
            }
            
            // Send the next chunk of data in our buffer.
            
            if (self.bufferOffset != self.bufferLimit) {
                NSInteger   bytesWritten;
                bytesWritten = [self.producerStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
                if (bytesWritten <= 0) {
                    [self stopSendWithStatus:@"Network write error"];
                } else {
                    self.bufferOffset += bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
            NSLog(@"producer stream error %@", [aStream streamError]);
            [self stopSendWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            assert(NO);     // should never happen for the output stream
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSURLResponse *)response
    // A delegate method called by the NSURLConnection when the request/response 
    // exchange is complete.  We look at the response to check that the HTTP 
    // status code is 2xx.  If it isn't, we fail right now.
{
    #pragma unused(theConnection)
    NSHTTPURLResponse * httpResponse;

    assert(theConnection == self.connection);
    
    httpResponse = (NSHTTPURLResponse *) response;
    assert( [httpResponse isKindOfClass:[NSHTTPURLResponse class]] );
    
    if ((httpResponse.statusCode / 100) != 2) {
        [self stopSendWithStatus:[NSString stringWithFormat:@"HTTP error %zd", (ssize_t) httpResponse.statusCode]];
    } else {
        self.statusLabel.text = @"Response OK.";
    }    
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)data
    // A delegate method called by the NSURLConnection as data arrives.  The 
    // response data for a POST is only for useful for debugging purposes, 
    // so we just drop it on the floor.
{
    #pragma unused(theConnection)
    #pragma unused(data)

    assert(theConnection == self.connection);

    // do nothing
}

- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error
    // A delegate method called by the NSURLConnection if the connection fails. 
    // We shut down the connection and display the failure.  Production quality code 
    // would either display or log the actual error.
{
    #pragma unused(theConnection)
    #pragma unused(error)
    assert(theConnection == self.connection);
    
    [self stopSendWithStatus:@"Connection failed"];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection
    // A delegate method called by the NSURLConnection when the connection has been 
    // done successfully.  We shut down the connection with a nil status, which 
    // causes the image to be displayed.
{
    #pragma unused(theConnection)
    assert(theConnection == self.connection);
    
    [self stopSendWithStatus:nil];
}

#pragma mark * Actions

- (IBAction)sendAction:(UIView *)sender
{
    assert( [sender isKindOfClass:[UIView class]] );

    if ( ! self.isSending ) {
        NSString *  filePath;
        
        // User the tag on the UIButton to determine which image to send.
        
        filePath = [[NetworkManager sharedInstance] pathForTestImage:sender.tag];
        assert(filePath != nil);
        
        [self startSend:filePath];
    }
}

- (IBAction)cancelAction:(id)sender
{
    #pragma unused(sender)
    [self stopSendWithStatus:@"Cancelled"];
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
    oldValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"PostURLText"];

    // Save the URL text if there is no pre-existing setting and it's not our 
    // default value, or if there is a pre-existing default and the new value 
    // is different.
    
    if (   ((oldValue == nil) && ! [newValue isEqual:kDefaultPostURLText] ) 
        || ((oldValue != nil) && ! [newValue isEqual:oldValue] ) ) {
        [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:@"PostURLText"];
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
    NSString *  currentURLText;
    
    [super viewDidLoad];
    assert(self.urlText != nil);
    assert(self.statusLabel != nil);
    assert(self.activityIndicator != nil);
    assert(self.cancelButton != nil);

    // Set up the URL field to be the last value we saved (or the default value 
    // if we have none).
    
    currentURLText = [[NSUserDefaults standardUserDefaults] stringForKey:@"PostURLText"];
    if (currentURLText == nil) {
        currentURLText = kDefaultPostURLText;
    }
    self.urlText.text = currentURLText;
    
    self.activityIndicator.hidden = YES;
    self.statusLabel.text = @"Tap a picture to start the POST";
    self.cancelButton.enabled = NO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.urlText = nil;
    self.statusLabel = nil;
    self.activityIndicator = nil;
    self.cancelButton = nil;
}

- (void)dealloc
{
    // Because NSURLConnection retains its delegate until the connection finishes, and 
    // any time the connection finishes we call -stopSendWithStatus: to clean everything 
    // up, we can't be deallocated with a connection in progress.
    assert(self->_connection == nil);
}

@end
