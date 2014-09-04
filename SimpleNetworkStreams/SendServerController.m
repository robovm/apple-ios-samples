/*
    File:       ServerController.m

    Contains:   Manages the send server tab.

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

#import "SendServerController.h"

#import "NetworkManager.h"

#include <CFNetwork/CFNetwork.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

enum {
    kSendBufferSize = 32768
};

@interface SendServerController () <NSStreamDelegate, NSNetServiceDelegate>

// stuff for IB

@property (nonatomic, strong, readwrite) IBOutlet UILabel *                   statusLabel;
@property (nonatomic, strong, readwrite) IBOutlet UIActivityIndicatorView *   activityIndicator;
@property (nonatomic, strong, readwrite) IBOutlet UIButton *                  startOrStopButton;

- (IBAction)startOrStopAction:(id)sender;

// private properties

@property (nonatomic, assign, readonly ) BOOL               isStarted;
@property (nonatomic, assign, readonly ) BOOL               isSending;
@property (nonatomic, strong, readwrite) NSNetService *     netService;
@property (nonatomic, assign, readwrite) CFSocketRef        listeningSocket;
@property (nonatomic, assign, readwrite) NSUInteger         currentImageNumber;
@property (nonatomic, strong, readwrite) NSOutputStream *   networkStream;
@property (nonatomic, strong, readwrite) NSInputStream *    fileStream;
@property (nonatomic, assign, readonly ) uint8_t *          buffer;
@property (nonatomic, assign, readwrite) size_t             bufferOffset;
@property (nonatomic, assign, readwrite) size_t             bufferLimit;

// forward declarations

- (void)stopServer:(NSString *)reason;

@end

@implementation SendServerController
{
    uint8_t                     _buffer[kSendBufferSize];
}

@synthesize currentImageNumber = _currentImageNumber;

@synthesize netService      = _netService;
@synthesize networkStream   = _networkStream;
@synthesize listeningSocket = _listeningSocket;
@synthesize fileStream      = _fileStream;
@synthesize bufferOffset    = _bufferOffset;
@synthesize bufferLimit     = _bufferLimit;

@synthesize statusLabel       = _statusLabel;
@synthesize activityIndicator = _activityIndicator;
@synthesize startOrStopButton = _startOrStopButton;

#pragma mark * Status management

// These methods are used by the core transfer code to update the UI.

- (void)dimImagesExceptOneTaggedWith:(NSInteger)theTag
{
    // If theTag is NSNotFound we end up dimming all images.
    
    assert( (theTag == NSNotFound) || ((theTag >= 1) && (theTag <= 4)) );
    
    for (UIView * view in self.view.subviews) {
        if ( [view isKindOfClass:[UIImageView class]] ) {
            if (view.tag == theTag) {
                view.alpha = 1.0f;
            } else {
                view.alpha = 0.25f;
            }
        }
    }
}

- (void)serverDidStartOnPort:(NSUInteger)port
{
    assert( (port != 0) && (port < 65536) );
    self.statusLabel.text = [NSString stringWithFormat:@"Started on port %zu", (size_t) port];
    [self.startOrStopButton setTitle:@"Stop" forState:UIControlStateNormal];
    self.tabBarItem.image = [UIImage imageNamed:@"sendserverOn.png"];
}

- (void)serverDidStopWithReason:(NSString *)reason
{
    if (reason == nil) {
        reason = @"Stopped";
    }
    self.statusLabel.text = reason;
    [self.startOrStopButton setTitle:@"Start" forState:UIControlStateNormal];
    self.tabBarItem.image = [UIImage imageNamed:@"sendserverOff.png"];
}

- (void)sendDidStart
{
    self.statusLabel.text = @"Sending";
    [self dimImagesExceptOneTaggedWith:self.currentImageNumber];
    [self.activityIndicator startAnimating];
    [[NetworkManager sharedInstance] didStartNetworkOperation];
}

- (void)updateStatus:(NSString *)statusString
{
    assert(statusString != nil);
    self.statusLabel.text = statusString;
}

- (void)sendDidStopWithStatus:(NSString *)statusString
{
    if (statusString == nil) {
        statusString = @"Send succeeded";
    }
    self.statusLabel.text = statusString;
    [self dimImagesExceptOneTaggedWith:NSNotFound];
    [self.activityIndicator stopAnimating];
    [[NetworkManager sharedInstance] didStopNetworkOperation];

    // The next send should use a different image.
    
    self.currentImageNumber += 1;
    if (self.currentImageNumber > 4) {
        self.currentImageNumber = 1;
    }
}

#pragma mark * Core transfer code

// This is the code that actually does the networking.

// Because buffer is declared as an array, you have to use a custom getter.  
// A synthesised getter doesn't compile.

- (uint8_t *)buffer
{
    return self->_buffer;
}

- (BOOL)isStarted
{
    return (self.netService != nil);
}

- (BOOL)isSending
{
    return (self.networkStream != nil);
}

- (void)startSend:(int)fd
{
    NSString *          filePath;
    CFWriteStreamRef    writeStream;

    assert(fd >= 0);

    assert(self.networkStream == nil);      // can't already be sending
    assert(self.fileStream == nil);         // ditto

    // Open a stream for the file we're going to send.

    filePath = [[NetworkManager sharedInstance] pathForTestImage:self.currentImageNumber];
    assert(filePath != nil);

    self.fileStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    assert(self.fileStream != nil);
    
    [self.fileStream open];

    // Open a stream based on the existing socket file descriptor.  Then configure 
    // the stream for async operation.

    CFStreamCreatePairWithSocket(NULL, fd, NULL, &writeStream);
    assert(writeStream != NULL);
    
    self.networkStream = (__bridge NSOutputStream *) writeStream;
    
    CFRelease(writeStream);

    [self.networkStream setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];

    self.networkStream.delegate = self;
    [self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.networkStream open];

    // Tell the UI we're sending.
    
    [self sendDidStart];
}

- (void)stopSendWithStatus:(NSString *)statusString
{
    if (self.networkStream != nil) {
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
    self.bufferOffset = 0;
    self.bufferLimit  = 0;
    [self sendDidStopWithStatus:statusString];
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
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            [self updateStatus:@"Sending"];

            // If we don't have any data buffered, go read the next chunk of data.
            
            if (self.bufferOffset == self.bufferLimit) {
                NSInteger   bytesRead;
                
                bytesRead = [self.fileStream read:self.buffer maxLength:kSendBufferSize];
                if (bytesRead == -1) {
                    [self stopSendWithStatus:@"File read error"];
                } else if (bytesRead == 0) {
                    [self stopSendWithStatus:nil];
                } else {
                    self.bufferOffset = 0;
                    self.bufferLimit  = bytesRead;
                }
            }

            // If we're not out of data completely, send the next chunk.
            
            if (self.bufferOffset != self.bufferLimit) {
                NSInteger   bytesWritten;

                bytesWritten = [self.networkStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
                assert(bytesWritten != 0);
                if (bytesWritten == -1) {
                    [self stopSendWithStatus:@"Network write error"];
                } else {
                    self.bufferOffset += bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
            [self stopSendWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)acceptConnection:(int)fd
{
    int     junk;

    assert(fd >= 0);

    // If we already have a connection, reject this new one.  This is one the 
    // big simplifying assumptions in this code.  A real server should handle 
    // multiple simultaneous connections.
    
    if ( self.isSending ) {
        junk = close(fd);
        assert(junk == 0);
    } else {
        [self startSend:fd];
    }
}

static void AcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
    // Called by CFSocket when someone connects to our listening socket.  
    // This implementation just bounces the request up to Objective-C.
{
    SendServerController *  obj;
    
    #pragma unused(type)
    assert(type == kCFSocketAcceptCallBack);
    #pragma unused(address)
    // assert(address == NULL);
    assert(data != NULL);
    
    obj = (__bridge SendServerController *) info;
    assert(obj != nil);

    assert(s == obj->_listeningSocket);
    #pragma unused(s)
    
    [obj acceptConnection:*(int *)data];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
    // A NSNetService delegate callback that's called if our Bonjour registration 
    // fails.  We respond by shutting down the server.
    //
    // This is another of the big simplifying assumptions in this sample. 
    // A real server would use the real name of the device for registrations, 
    // and handle automatically renaming the service on conflicts.  A real 
    // client would allow the user to browse for services.  To simplify things 
    // we just hard-wire the service name in the client and, in the server, fail 
    // if there's a service name conflict.
{
    #pragma unused(sender)
    assert(sender == self.netService);
    #pragma unused(errorDict)
    
    [self stopServer:@"Registration failed"];
}

- (void)startServer
{
    BOOL                success;
    int                 err;
    int                 fd;
    int                 junk;
    struct sockaddr_in  addr;
    NSUInteger          port;
    
    // Create a listening socket and use CFSocket to integrate it into our 
    // runloop.  We bind to port 0, which causes the kernel to give us 
    // any free port, then use getsockname to find out what port number we 
    // actually got.
    
    port = 0;
    
    fd = socket(AF_INET, SOCK_STREAM, 0);
    success = (fd != -1);
    if (success) {
        memset(&addr, 0, sizeof(addr));
        addr.sin_len    = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_port   = 0;
        addr.sin_addr.s_addr = INADDR_ANY;
        err = bind(fd, (const struct sockaddr *) &addr, sizeof(addr));
        success = (err == 0);
    }
    if (success) {
        err = listen(fd, 5);
        success = (err == 0);
    }
    if (success) {
        socklen_t   addrLen;

        addrLen = sizeof(addr);
        err = getsockname(fd, (struct sockaddr *) &addr, &addrLen);
        success = (err == 0);
        
        if (success) {
            assert(addrLen == sizeof(addr));
            port = ntohs(addr.sin_port);
        }
    }
    if (success) {
        CFSocketContext context = { 0, (__bridge void *) self, NULL, NULL, NULL };
        
        assert(self->_listeningSocket == NULL);
        self->_listeningSocket = CFSocketCreateWithNative(
            NULL, 
            fd, 
            kCFSocketAcceptCallBack, 
            AcceptCallback, 
            &context
        );
        success = (self->_listeningSocket != NULL);
        
        if (success) {
            CFRunLoopSourceRef  rls;
            
            fd = -1;        // listeningSocket is now responsible for closing fd

            rls = CFSocketCreateRunLoopSource(NULL, self.listeningSocket, 0);
            assert(rls != NULL);
            
            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
            
            CFRelease(rls);
        }
    }
    
    // Now register our service with Bonjour.  See the comments in -netService:didNotPublish: 
    // for more info about this simplifying assumption.
    
    if (success) {
        self.netService = [[NSNetService alloc] initWithDomain:@"local." type:@"_x-SNSDownload._tcp." name:@"Test" port:port];
        success = (self.netService != nil);
    }
    if (success) {
        self.netService.delegate = self;
        
        [self.netService publishWithOptions:NSNetServiceNoAutoRename];
        
        // continues in -netServiceDidPublish: or -netService:didNotPublish: ...
    }
    
    // Clean up after failure.
    
    if ( success ) {
        assert(port != 0);
        [self serverDidStartOnPort:port];
    } else {
        [self stopServer:@"Start failed"];
        if (fd != -1) {
            junk = close(fd);
            assert(junk == 0);
        }
    }
}

- (void)stopServer:(NSString *)reason
{
    if (self.isSending) {
        [self stopSendWithStatus:@"Cancelled"];
    }
    if (self.netService != nil) {
        [self.netService stop];
        self.netService = nil;
    }
    if (self.listeningSocket != NULL) {
        CFSocketInvalidate(self.listeningSocket);
        CFRelease(self->_listeningSocket);
        self->_listeningSocket = NULL;
    }
    [self serverDidStopWithReason:reason];
}


#pragma mark * Actions

- (IBAction)startOrStopAction:(id)sender
{
    #pragma unused(sender)
    if (self.isStarted) {
        [self stopServer:nil];
    } else {
        [self startServer];
    }
}

#pragma mark * View controller boilerplate

- (void)viewDidLoad
{
    [super viewDidLoad];
    assert(self.statusLabel != nil);
    assert(self.activityIndicator != nil);
    assert(self.startOrStopButton != nil);
    
    self.currentImageNumber = 1;
    [self dimImagesExceptOneTaggedWith:NSNotFound];
    self.activityIndicator.hidden = YES;
    self.statusLabel.text = @"Tap Start to start the server";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.statusLabel = nil;
    self.activityIndicator = nil;
    self.startOrStopButton = nil;
}

- (void)dealloc
{
    [self stopServer:nil];
}

@end
