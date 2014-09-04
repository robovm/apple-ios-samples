/*
     File: WebViewController.m
 Abstract: Main web view controller.
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

#import "WebViewController.h"

@import Security;

@interface WebViewController () <UIWebViewDelegate>

// stuff for IB

@property (nonatomic, strong, readwrite) IBOutlet UIWebView *   webView;

// private properties

@property (nonatomic, strong, readwrite) NSURLSessionDataTask * installDataTask;

@end

@implementation WebViewController

- (void)dealloc
{
    // All of these should be nil because the connection retains its delegate (that is, us) 
    // until it completes, and we clean these up when the connection completes.
    
    assert(self->_installDataTask == nil);
}

/*! Called when the user taps on the Sites button. This tells the web view to load our start 
 *  page ("root.html").
 *  \param sender The object that sent this action.
 */

- (IBAction)sitesAction:(id)sender
{
    #pragma unused(sender)

    // If we're currently downloading an anchor to install, stop that now.
    
    if (self.installDataTask != nil) {
        [self installStopWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
    }
    
    // Display the list of sites that the user can choose from.
    
    [self displaySites];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    assert(self.webView != nil);
    assert(self.webView.delegate == self);
    [self displaySites];
}

/*! Called to log various bits of information.  Will be called on the main thread.
 *  \param format A standard NSString-style format string; will not be nil.
 */

- (void)logWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2)
{
    id<WebViewControllerDelegate>   strongDelegate;

    assert(format != nil);
    
    strongDelegate = self.delegate;
    if ([strongDelegate respondsToSelector:@selector(webViewController:logWithFormat:arguments:)]) {
        va_list     arguments;
        
        va_start(arguments, format);
        [strongDelegate webViewController:self logWithFormat:format arguments:arguments];
        va_end(arguments);
    }
}

#pragma mark * Web view delegate callbacks

// When we want to display the anchor install UI, we point the web view at some HTML 
// (derived from "anchorInstall.html") that contains a HTML form.  When the user taps the 
// Install button, the form posts to a URL.  We then catch that URL in 
// -webView:shouldStartLoadWithRequest:navigationType: and start the install.  We give 
// that URL a special prefix, kAnchorInstallSchemePrefix, to make it easy to recognise. 
// For example, if we display the install UI for <http://www.cacert.org/certs/root.der>, 
// the URL that gets POSTed is <x-anchor-install-http://www.cacert.org/certs/root.der>. 
//
// Note that we use a prefix rather than a custom scheme so as to preserver the previous 
// scheme, which might be important (for example, "http" vs "https", or perhaps even 
// "ftp").

static NSString * kAnchorInstallSchemePrefix = @"x-anchor-install-";

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *          navigationName;
    BOOL                allowLoad;
    NSMutableString *   installURLString;
    NSURL *             installURL;
    
    assert(webView == self.webView);
    #pragma unused(webView)
    assert(request != nil);

    // Log the operation.
    
    static NSDictionary * sNavigationNames;
    if (sNavigationNames == nil) {
        sNavigationNames = @{
            @(UIWebViewNavigationTypeLinkClicked):     @"clicked", 
            @(UIWebViewNavigationTypeFormSubmitted):   @"form submitted", 
            @(UIWebViewNavigationTypeBackForward):     @"back/forward", 
            @(UIWebViewNavigationTypeReload):          @"reload", 
            @(UIWebViewNavigationTypeFormResubmitted): @"form resubmitted", 
            @(UIWebViewNavigationTypeOther):           @"other"
        };
    }
    navigationName = sNavigationNames[@(navigationType)];
    if (navigationName == nil) {
        navigationName = @"unknown";
    }
    [self logWithFormat:@"should load %@ reason %@", [request URL], navigationName];
    
    // We detect the web view trying to load one of our anchor install URLs and start loading 
    // it directly via NSURLSession.  In that case we also tell the web view to display the 
    // "Installing..." UI.
    
    if ( [[[[request URL] scheme] lowercaseString] hasPrefix:kAnchorInstallSchemePrefix] ) {

        // Start downloading the anchor using NSURLSession.  Before we call the install 
        // code (-installTrustedAnchorFromURL:) we have to calculate the install URL by 
        // stripping the prefix off the request URL.

        installURLString = [[[request URL] absoluteString] mutableCopy];
        assert(installURLString != nil);
        
        [installURLString replaceCharactersInRange:NSMakeRange(0, [kAnchorInstallSchemePrefix length]) withString:@""];

        installURL = [NSURL URLWithString:installURLString];
        assert(installURL != nil);
        
        [self installTrustedAnchorFromURL:installURL];
        
        allowLoad = NO;
    } else {
        allowLoad = YES;
    }

    return allowLoad;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSURL *     failingURL;
    NSString *  domain;
    NSInteger   code;
    BOOL        handled;
    
    assert(webView == self.webView);
    #pragma unused(webView)
    assert(error != nil);

    handled = NO;
    
    // Extract information from the error.
    
    domain  = [error domain];
    code    = [error code];
    failingURL = [self failingURLForError:error];

    assert(domain != nil);

    // If we get an error from WebKit saying that the user navigated to a resource 
    // that it can't display (WebKitErrorFrameLoadInterruptedByPolicyChange) and the 
    // URL looks like a certificate, kick off the anchor install UI.
    
    if ( [domain isEqual:@"WebKitErrorDomain"] && (code == 102) && (failingURL != nil) ) {
        NSString *          failingURLExtension;
        NSString *          anchorInstallPath;
        NSString *          anchorInstallTemplate;
        NSMutableString *   installURLString;
        NSURL *             installURL;

        assert([failingURL scheme] != nil);     // If the URL has no scheme, adding kAnchorInstallSchemePrefix would be 
                                                // completely bogus.  This shouldn't never happen, but the assert makes sure.
    
        failingURLExtension = [[[[failingURL absoluteString] lastPathComponent] pathExtension] lowercaseString];
        if ( (failingURLExtension != nil) && ([failingURLExtension isEqual:@"cer"] || [failingURLExtension isEqual:@"der"]) ) {
        
            // Get the contents of "anchorInstall.html" and substitute the failing URL and the 
            // install URL into the text.  Simple substitution like this is fine in this case 
            // because the incoming texts are known good URLs, and thus don't need any form 
            // of quoting.
            
            anchorInstallPath = [[NSBundle mainBundle] pathForResource:@"anchorInstall" ofType:@"html"];
            assert(anchorInstallPath != nil);
            
            anchorInstallTemplate  = [NSString stringWithContentsOfFile:anchorInstallPath usedEncoding:NULL error:NULL];
            assert(anchorInstallTemplate != nil);

            // Calculate installURL, that is, the failing URL without the prefix 
            // (kAnchorInstallSchemePrefix).

            installURLString = [[failingURL absoluteString] mutableCopy];
            assert(installURLString != nil);
            
            [installURLString replaceCharactersInRange:NSMakeRange(0, 0) withString:kAnchorInstallSchemePrefix];

            installURL = [NSURL URLWithString:installURLString];
            assert(installURL != nil);

            assert(failingURL != nil);
            
            // Get the web view to load the anchor install UI.  Make sure that we give it a 
            // valid base URL so that page-relative URLs within the page work properly.
            
            [self.webView loadHTMLString:[NSString stringWithFormat:anchorInstallTemplate, failingURL, installURL] baseURL:[NSURL fileURLWithPath:anchorInstallPath]];
            handled = YES;
        }
    } else if ( [domain isEqual:NSURLErrorDomain] && (code == NSURLErrorCancelled) ) {
        // UIWebView sends us NSURLErrorCancelled errors when things fail that aren't critical, so for the moment 
        // we just ignore them.
        handled = YES;
    }
    
    // If we didn't handle the error as a special case, point the web view at our error page.
    
    if ( ! handled) {
        [self logWithFormat:@"did fail with error %@ / %zd", domain, (ssize_t) code];

        [self displayError:error];
    }    
}

#pragma mark * Web view utilities

/*! Tells the web view to load "root.html", our initial start page.
 */

- (void)displaySites
{
    NSURL *     rootURL;

    rootURL = [[NSBundle mainBundle] URLForResource:@"root" withExtension:@"html"];
    assert(rootURL != nil);
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:rootURL]];
}

/*! Tell the anchor install page that we've started installing an anchor.  It responds by 
 *  display its "Installing..." UI.
 */

- (void)didStartInstall
{
    (void) [self.webView stringByEvaluatingJavaScriptFromString:@"didStartInstall()"];
}

/*! Tell the anchor install page that we've successfully installed an anchor.  
 *  It responds by display its "Installed" UI.  Note that there's equivalent 
 *  error notification; errors result in a redirect to our error page (see 
 *  the -displayError: method).
 */

- (void)didFinishInstall
{
    (void) [self.webView stringByEvaluatingJavaScriptFromString:@"didFinishInstall()"];
}

/*! Tells the web view to load "error.html", our standard error page, parameterising it 
 *  with the error domain, code and failing URL.
 */

- (void)displayError:(NSError *)error
{
    NSURL *     failingURL;
    NSString *  failingURLString;
    NSString *  errorPath;
    NSString *  errorTemplate;
    
    assert(error != nil);

    failingURL = [self failingURLForError:error];
    if (failingURL == nil) {
        failingURLString = @"n/a";
    } else {
        assert([failingURL isKindOfClass:[NSURL class]]);
        assert([failingURL scheme] != nil);
        failingURLString = [failingURL absoluteString];
        assert(failingURLString != nil);
    }

    errorPath = [[NSBundle mainBundle] pathForResource:@"error" ofType:@"html"];
    assert(errorPath != nil);

    errorTemplate = [NSString stringWithContentsOfFile:errorPath usedEncoding:NULL error:NULL];
    assert(errorTemplate != nil);
    
    [self.webView loadHTMLString:[NSString stringWithFormat:errorTemplate, failingURLString, [error domain], (size_t) [error code]] baseURL:[NSURL fileURLWithPath:errorPath]];
}

#pragma mark * Error utilities

/*! The error domain used by our installation error codes.
 */

static NSString * WebViewControllerInstallErrorDomain = @"WebViewControllerInstallErrorDomain";

/*! Our installation error codes.  Note that (positive) HTTP status codes are also possible.
 */

enum WebViewControllerInstallErrorCode {
    // positive numbers are HTTP status codes
    WebViewControllerInstallErrorUnsupportedMIMEType   = -1, 
    WebViewControllerInstallErrorCertificateDataTooBig = -2,
    WebViewControllerInstallErrorCertificateDataBad    = -3, 
    WebViewControllerInstallErrorNowhereToInstall      = -4
};

/*! Returns an error object in the domain WebViewControllerInstallErrorDomain with 
 *  the specified error code and the failing URL set from the current install data task's 
 *  URL.
 *  \param code The code to use for the error.
 */

- (NSError *)constructInstallErrorWithCode:(NSInteger)code
{
    NSURL *                 url;
    NSString *              urlStr;
    NSMutableDictionary *   userInfo;
    
    assert(code != 0);

    url = [self.installDataTask.originalRequest URL];
    urlStr = nil;
    if (url != nil) {
        urlStr = [url absoluteString];
    }

    if ( (url == nil) && (urlStr == nil) ) {
        userInfo = nil;
    } else {
        userInfo = [NSMutableDictionary dictionary];
        assert(userInfo != nil);
        
        if (url != nil) {
            userInfo[NSURLErrorFailingURLErrorKey] = url;
        }
        if (urlStr != nil) {
            userInfo[NSURLErrorFailingURLStringErrorKey] = urlStr;
        }
    }

    return [NSError errorWithDomain:WebViewControllerInstallErrorDomain code:code userInfo:userInfo];
}

/*! Extracts the failing URL from an NSError by way of the NSURLErrorFailingURLErrorKey 
 *  and NSURLErrorFailingURLStringErrorKey values in the error's user info dictionary.
 *  \param error The error to extract info from.
 */

- (NSURL *)failingURLForError:(NSError *)error
{
    NSURL *         result;
    NSDictionary *  userInfo;
    
    assert(error != nil);
    
    result = nil;
    
    userInfo = [error userInfo];
    if (userInfo != nil) {
        result = userInfo[NSURLErrorFailingURLErrorKey];
        assert( (result == nil) || [result isKindOfClass:[NSURL class]] );
        
        if (result == nil) {
            NSString *  urlStr;
            
            urlStr = userInfo[NSURLErrorFailingURLStringErrorKey];
            assert( (urlStr == nil) || [urlStr isKindOfClass:[NSString class]] );
            if (urlStr != nil) {
                assert([urlStr isKindOfClass:[NSString class]]);
                
                result = [NSURL URLWithString:urlStr];
            }
        }
    }
    
    return result;
}

#pragma mark * Anchor certificate fetch and install

/*! Starts the process to download and install an anchor certificate.
 *  \param url The URL to download from.
 */

- (void)installTrustedAnchorFromURL:(NSURL *)url
{
    assert(url != nil);

    [self logWithFormat:@"start trusted anchor install %@", url];
    
    if (self.installDataTask == nil) {
        
        // Start the connection to download and install the anchor certificate.
        
        self.installDataTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if ( (error != nil) && [[error domain] isEqual:NSURLErrorDomain] && ([error code] == NSURLErrorCancelled) ) {
                // Do nothing.  We get here if the user cancels the install request.  If that's case then the 
                // cancellation code ends up calling -installStopWithError: directly so there's no need to call 
                // it here (which is what happens, indirectly, when we call -installDataTaskDidCompleteWithData:response:error:).  
                // Moreover if we do call through we end doing the wrong thing as one error ends up overwriting the other.
            } else {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self installDataTaskDidCompleteWithData:data response:response error:error];
                }];
            }
        }];
        assert(self.installDataTask != nil);

        [self didStartInstall];
        
        [self.installDataTask resume];
    } else {
        assert(NO);     // We shouldn't be able to get a second install going until the first is complete.
    }
}

/*! Checks whether the install data task's response looks good.
 *  \param response The response to check; must not be nil.
 *  \param errorPtr If not NULL then, on error, *errorPtr will be the actual error.
 *  \returns Returns YES on success, NO on failure.
 */

- (BOOL)isValidInstallDataTaskResponse:(NSURLResponse *)response error:(__autoreleasing NSError **)errorPtr
{
    NSError *   error;
    
    assert(response != nil);
    // errorPtr may be NULL
    assert([NSThread isMainThread]);
    
    // Check the HTTP status code of the response.
    
    error = nil;
    if ( [response isKindOfClass:[NSHTTPURLResponse class]] ) {
        NSHTTPURLResponse * httpResponse;
        
        httpResponse = (NSHTTPURLResponse *) response;
        
        if ( ([httpResponse statusCode] / 100) != 2) {
            error = [self constructInstallErrorWithCode:[httpResponse statusCode]];
        }
    }

    // Check the content type of the response.

    if (error == nil) {
        static NSSet * sSupportedMIMETypes;

        if (sSupportedMIMETypes == nil) {
            sSupportedMIMETypes = [[NSSet alloc] initWithObjects:@"application/x-x509-ca-cert", @"application/pkix-cert", nil];
        }
        if ( ! [sSupportedMIMETypes containsObject:[response MIMEType]] ) {
            error = [self constructInstallErrorWithCode:WebViewControllerInstallErrorUnsupportedMIMEType];
        }
    }

    // Clean up.
    
    if ( (error != nil) && (errorPtr != NULL) ) {
        *errorPtr = error;
    }

    return (error == nil);
}

/*! Create and installs a certificate from the data returned by the install data task.
 *  \param data The data returned by the install data task; must not be nil.
 *  \param errorPtr If not NULL then, on error, *errorPtr will be the actual error.
 *  \returns Returns YES on success, NO on failure.
 */

- (BOOL)parseAndInstallCertificateData:(NSData *)data error:(__autoreleasing NSError **)errorPtr
{
    NSError *           error;
    SecCertificateRef   anchor;

    assert(data != nil);
    // errorPtr may be NULL
    assert([NSThread isMainThread]);
    
    // Try to create a certificate from the data we downloaded.  If that 
    // succeeds, tell our delegate.
    
    error = nil;
    anchor = SecCertificateCreateWithData(NULL, (__bridge CFDataRef) data);
    if (anchor == nil) {
        error = [self constructInstallErrorWithCode:WebViewControllerInstallErrorCertificateDataBad];
    }
    if (error == nil) {
        id<WebViewControllerDelegate>   strongDelegate;
        
        strongDelegate = self.delegate;
        if ( ! [strongDelegate respondsToSelector:@selector(webViewController:addTrustedAnchor:error:)] ) {
            error = [self constructInstallErrorWithCode:WebViewControllerInstallErrorNowhereToInstall];
        } else {
            BOOL                            success;
            NSError *                       delegateError;

            success = [strongDelegate webViewController:self addTrustedAnchor:anchor error:&delegateError];
            if ( ! success ) {
                error = delegateError;
            }
        }
    }

    // Clean up.
    
    if (anchor != NULL) {
        CFRelease(anchor);
    }
    if ( (error != nil) && (errorPtr != NULL) ) {
        *errorPtr = error;
    }
    
    return (error == nil);
}

/*! Called when the install data task completes; checks the response and then processes the certificate data.
 *  \param data The data returned by the install data task; nil on error.
 *  \param response The response to check; nil on error.
 *  \param error nil on success; non-nil on error.
 */

- (void)installDataTaskDidCompleteWithData:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error
{
    BOOL        success;

    assert( (error != nil) || (data     != nil) );
    assert( (error != nil) || (response != nil) );

    assert([NSThread isMainThread]);

    // Check for three different ways to fail.
    
    success = (error == nil);
    if (success) {
        success = [self isValidInstallDataTaskResponse:response error:&error];
    }
    if (success) {
        success = [self parseAndInstallCertificateData:data error:&error];
    }
    #pragma unused(success)         // quietens analyser in the Release build
    assert(success == (error == nil));

    // Clean up the installation.  For debugging purposes only (specifically, to make it 
    // easy to see the download animation UI), you can enable a delay.  You shouldn't do anything 
    // like this in production code because it creates a new state that the cancellation code 
    // isn't prepared to handle.

    if (NO) {
        [self performSelector:@selector(installStopWithError:) withObject:error afterDelay:5.0];
    } else {
        [self installStopWithError:error];
    }
}

/*! Stops and cleans up the install process and:
 *  
 *  - if there's no error, tells the anchor install page currently being displayed 
 *    by the web view to switch to the "Installed" UI
 *  
 *  - if there's an error, tells the web view to display it
 *  \param error The actual error or nil if there's no error.
 */

- (void)installStopWithError:(NSError *)error
{
    assert([NSThread isMainThread]);
    
    [self.installDataTask cancel];
    self.installDataTask = nil;
    
    if (error == nil) {
        [self logWithFormat:@"trusted anchor install did finish"];

        [self didFinishInstall];
    } else {
        [self logWithFormat:@"trusted anchor install did fail with error %@ / %zd", [error domain], (ssize_t) [error code]];

        [self displayError:error];
    }
}

@end
