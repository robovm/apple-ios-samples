/*
     File: AppDelegate.m
 Abstract: Main app controller.
  Version: 1.1
 
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

#import "AppDelegate.h"

#import "WebViewController.h"

#import "CredentialsManager.h"

#import "CustomHTTPProtocol.h"

#import "ThreadInfo.h"

#include <pthread.h>            // for pthread_threadid_np

@interface AppDelegate () <UIApplicationDelegate, WebViewControllerDelegate, CustomHTTPProtocolDelegate>

@property (nonatomic, strong, readwrite) CredentialsManager *   credentialsManager;

/*! For threadInfoByThreadID, each key is an NSNumber holding a thread ID and each 
    value is a ThreadInfo object.  The dictionary is protected by @synchronized on 
    the app delegate object itself.
    
    In the debugger you can dump this info with:
    
    (lldb) po [[[UIApplication sharedApplication] delegate] threadInfoByThreadID]
 */

@property (atomic, strong, readwrite) NSMutableDictionary *     threadInfoByThreadID;
@property (atomic, assign, readwrite) NSUInteger                nextThreadNumber;           ///< Protected by @synchronized on the delegate object.

@end

@implementation AppDelegate

@synthesize window = _window;                   // synthesis required because property is declared in UIApplicationDelegate protocol

static BOOL sAppDelegateLoggingEnabled = YES;

static NSTimeInterval sAppStartTime;            // since reference date

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    #pragma unused(application)
    #pragma unused(launchOptions)
    WebViewController *   webViewController;
    
    assert(self.window != nil);
    
    sAppStartTime = [NSDate timeIntervalSinceReferenceDate];
    
    self.credentialsManager = [[CredentialsManager alloc] init];

    // Prepare the globals needed by our logging code.  The call to -threadInfoForCurrentThread 
    // sets up the main thread's thread info record and ensures it has a thread number of 0.

    self.threadInfoByThreadID = [[NSMutableDictionary alloc] init];
    (void) [self threadInfoForCurrentThread];
    
    // Start up the core code.  Change the if expression to NO to disable the CustomHTTPProtocol for 
    // comparative testing and so on.
    
    [CustomHTTPProtocol setDelegate:self];
    if (YES) {
        [CustomHTTPProtocol start];
    }
    
    // Create the web view controller and set up the UI.  We do this after setting 
    // up the core code in case this triggers any HTTP requests.
    // 
    // By default the Test button is not shown because this sample is focused on UIWebView.  
    // If you want to runs tests with NSURL{Session,Connection}, change the if expression to 
    // show the Test button and then configure the test by changing the code in -testAction:.
    
    webViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle bundleForClass:[self class]]] instantiateViewControllerWithIdentifier:@"webView"];
    assert(webViewController != nil);
    webViewController.delegate = self;
    if (NO) {
        webViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStyleBordered target:self action:@selector(testAction:)];
    }
    [((UINavigationController *) self.window.rootViewController) pushViewController:webViewController animated:NO];

	[self.window makeKeyAndVisible];
    
    return YES;
}

- (ThreadInfo *)threadInfoForCurrentThread
{
    int             junk;
    uint64_t        tid;
    NSNumber *      tidObj;
    ThreadInfo *    result;

    // Get the thread ID and box it for use as a dictionary key.
    
    junk = pthread_threadid_np(pthread_self(), &tid);
    #pragma unused(junk)            // quietens analyser in the Release build
    assert(junk == 0);
    tidObj = @(tid);
    
    // Look up the thread info using that key.
    
    @synchronized (self) {
        result = self.threadInfoByThreadID[tidObj];
    }
    
    // If we didn't find one, create it.  We drop the @synchronized while doing this because 
    // it might take a while; in theory no one else should be able to add this thread into 
    // the dictionary (because threads only add themselves) so we just assert that this 
    // hasn't happened.
    // 
    // Also note that, because self.nextThreadNumber accesses must be protected by the 
    // @synchronized, we actually created the ThreadInfo object inside the @synchronized 
    // block.  That shouldn't be a problem because -[ThreadInfo initXxx] is trivial.
    
    if (result == nil) {
        ThreadInfo *    newThreadInfo;
        char            threadName[256];
        NSString *      threadNameObj;

        if ( (pthread_getname_np(pthread_self(), threadName, sizeof(threadName)) == 0) && (threadName[0] != 0) ) {
            // We got a name and it's not empty.
            threadNameObj = [[NSString alloc] initWithUTF8String:threadName];
        } else if (pthread_main_np()) {
            threadNameObj = @"-main-";
        } else {
            threadNameObj = @"-unnamed-";
        }
        assert(threadNameObj != nil);

        @synchronized (self) {
            assert(self.threadInfoByThreadID[tidObj] == nil);

            newThreadInfo = [[ThreadInfo alloc] initWithThreadID:tid number:self.nextThreadNumber name:threadNameObj];
            self.nextThreadNumber += 1;

            self.threadInfoByThreadID[tidObj] = newThreadInfo;
            result = newThreadInfo;
        }
    }
    
    return result;
}

/*! Our logging core, called by various logging routines, each with a unique prefix. May be called 
 *  by any thread.
 *  \param prefix A prefix to to insert into the log; must not be nil; if non-empty, should include a trailing space.
 *  \param format A standard NSString-style format string.
 *  \param arguments Arguments for that format string.
 */

- (void)logWithPrefix:(NSString *)prefix format:(NSString *)format arguments:(va_list)arguments
{
    assert(prefix != nil);
    assert(format != nil);
    
    if (sAppDelegateLoggingEnabled) {
        NSTimeInterval  now;
        ThreadInfo *    threadInfo;
        NSString *      str;
        char            elapsedStr[16];

        now = [NSDate timeIntervalSinceReferenceDate];

        threadInfo = [self threadInfoForCurrentThread];
        
        str = [[NSString alloc] initWithFormat:format arguments:arguments];
        assert(str != nil);
        
        snprintf(elapsedStr, sizeof(elapsedStr), "+%.1f", (now - sAppStartTime));
        
        fprintf(stderr, "%3zu %s %s%s\n", (size_t) threadInfo.number, elapsedStr, [prefix UTF8String], [str UTF8String]);
    }
}

- (void)customHTTPProtocol:(CustomHTTPProtocol *)protocol logWithFormat:(NSString *)format arguments:(va_list)arguments
{
    NSString *  prefix;
    
    // protocol may be nil
    assert(format != nil);
    
    if (protocol == nil) {
        prefix = @"protocol ";
    } else {
        prefix = [NSString stringWithFormat:@"protocol %p ", protocol];
    }
    [self logWithPrefix:prefix format:format arguments:arguments];
}

- (BOOL)webViewController:(WebViewController *)controller addTrustedAnchor:(SecCertificateRef)anchor error:(NSError *__autoreleasing *)errorPtr
{
    #pragma unused(controller)
    assert(controller != nil);
    assert(anchor != NULL);
    // errorPtr may be NULL
    #pragma unused(errorPtr)
    assert([NSThread isMainThread]);
    
    [self.credentialsManager addTrustedAnchor:anchor];
    return YES;
}

- (void)webViewController:(WebViewController *)controller logWithFormat:(NSString *)format arguments:(va_list)arguments
{
    #pragma unused(controller)
    assert(controller != nil);
    assert(format != nil);
    assert([NSThread isMainThread]);
    
    [self logWithPrefix:@"web view " format:format arguments:arguments];
}

/*! Called by the test subsystem (see below) to log various bits of information. 
 *  Will be called on the main thread.
 *  \param format A standard NSString-style format string; will not be nil.
 */

- (void)testLogWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2)
{
    va_list     arguments;
    
    assert(format != nil);
    
    va_start(arguments, format);
    [self logWithPrefix:@"test " format:format arguments:arguments];
    va_end(arguments);
}

- (BOOL)customHTTPProtocol:(CustomHTTPProtocol *)protocol canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    assert(protocol != nil);
    #pragma unused(protocol)
    assert(protectionSpace != nil);
    
    // We accept any server trust authentication challenges.
    
    return [[protectionSpace authenticationMethod] isEqual:NSURLAuthenticationMethodServerTrust];
}

- (void)customHTTPProtocol:(CustomHTTPProtocol *)protocol didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    OSStatus            err;
    NSURLCredential *   credential;
    SecTrustRef         trust;
    SecTrustResultType  trustResult;

    // Given our implementation of -customHTTPProtocol:canAuthenticateAgainstProtectionSpace:, this method 
    // is only called to handle server trust authentication challenges.  It evaluates the trust based on 
    // both the global set of trusted anchors and the list of trusted anchors returned by the CredentialsManager.
    
    assert(protocol != nil);
    assert(challenge != nil);
    assert([[[challenge protectionSpace] authenticationMethod] isEqual:NSURLAuthenticationMethodServerTrust]);
    assert([NSThread isMainThread]);
    
    credential = nil;

    // Extract the SecTrust object from the challenge, apply our trusted anchors to that 
    // object, and then evaluate the trust.  If it's OK, create a credential and use 
    // that to resolve the authentication challenge.  If anything goes wrong, resolve 
    // the challenge with nil, which continues without a credential, which causes the 
    // connection to fail.
    
    trust = [[challenge protectionSpace] serverTrust];
    if (trust == NULL) {
        assert(NO);
    } else {
        err = SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef) self.credentialsManager.trustedAnchors);
        if (err != noErr) {
            assert(NO);
        } else {
            err = SecTrustSetAnchorCertificatesOnly(trust, false);
            if (err != noErr) {
                assert(NO);
            } else {
                err = SecTrustEvaluate(trust, &trustResult);
                if (err != noErr) {
                    assert(NO);
                } else {
                    if ( (trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified) ) {
                        credential = [NSURLCredential credentialForTrust:trust];
                        assert(credential != nil);
                    }
                }
            }
        }
    }
    
    [protocol resolveAuthenticationChallenge:challenge withCredential:credential];
}

// We don't need to implement -customHTTPProtocol:didCancelAuthenticationChallenge: because we always resolve 
// the challenge synchronously within -customHTTPProtocol:didReceiveAuthenticationChallenge:.

#pragma mark Test Button

/*! Called when the user taps of the (optional) Test button in the nav bar.  This kicks off a various 
 *  tests, selectable at compile time by changing the if expressions.
 *  \param sender The object that sent this action.
 */

- (void)testAction:(id)sender
{
    #pragma unused(sender)
    if (NO) {
        [self testNSURLConnection];
    }
    if (YES) {
        [self testNSURLSession];
    }
}

#pragma mark NSURLSession test

/*! This routine kicks off a vanilla NSURLSession task, as opposed to the UIWebView test shown by the 
 *  main app.  This is useful because UIWebView uses NSURLConnection (actually, the private CFNetwork 
 *  API that underlies NSURLConnection, CFURLConnection) in a unique way, so it's important to test 
 *  your code with both UIWebView and NSURLSession.
 */

- (void)testNSURLSession
{
    [self testLogWithFormat:@"start (NSURLSession)"];
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"https://www.apple.com/"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        #pragma unused(data)
        if (error != nil) {
            [self testLogWithFormat:@"error:%@ / %d", [error domain], (int) [error code]];
        } else {
            [self testLogWithFormat:@"success:%zd / %@", (ssize_t) [(NSHTTPURLResponse *) response statusCode], [response URL]];
        }
    }] resume];
}

#pragma mark NSURLConnection test

/*! This routine kicks off a vanilla NSURLConnection, as opposed to the UIWebView test shown by the 
 *  main app.  This is useful because UIWebView uses NSURLConnection (actually, the private CFNetwork 
 *  API that underlies NSURLConnection, CFURLConnection) in a unique way, so it's important to test 
 *  your code with both UIWebView and NSURLConnection.
 */

- (void)testNSURLConnection
{
    [self testLogWithFormat:@"start (NSURLConnection)"];
    (void) [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.apple.com/"]] delegate:self];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    #pragma unused(connection)
    [self testLogWithFormat:@"willSendRequest:%@ redirectResponse:%@", [request URL], [response URL]];
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    #pragma unused(connection)
    #pragma unused(response)
    [self testLogWithFormat:@"didReceiveResponse:%zd / %@", (ssize_t) [(NSHTTPURLResponse *) response statusCode], [response URL]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    #pragma unused(connection)
    #pragma unused(data)
    [self testLogWithFormat:@"didReceiveData:%zu", (size_t) [data length]];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    #pragma unused(connection)
    [self testLogWithFormat:@"willCacheResponse:%@", [[cachedResponse response] URL]];
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    #pragma unused(connection)
    [self testLogWithFormat:@"connectionDidFinishLoading"];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    #pragma unused(connection)
    #pragma unused(error)
    [self testLogWithFormat:@"didFailWithError:%@ / %d", [error domain], (int) [error code]];
}

@end
