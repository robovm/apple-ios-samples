/*
     File: WebViewController.h
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

@import UIKit;

@protocol WebViewControllerDelegate;

/*! A view controller to run a web view.  The implementation includes a number 
 *  of interesting features, including:
 *
 *  - a Sites button, to display a pre-configured list of web sites (from "root.html")
 *  
 *  - the ability to download and install (via a delegate callback) a custom 
 *    root certificate (trusted anchor)
 */

@interface WebViewController : UIViewController

@property (nonatomic, weak,   readwrite) id<WebViewControllerDelegate>  delegate;           ///< The controller delegate.

@end

/*! The protocol for the WebViewController delegate.
 */

@protocol WebViewControllerDelegate <NSObject>

@optional

/*! Called by the WebViewController to add a certificate as a trusted anchor.
 *  Will be called on the main thread.
 *  \param controller The controller instance; will not be nil.
 *  \param anchor The certificate to add; will not be NULL.
 *  \param errorPtr If not NULL then, on error, set *errorPtr to the actual error.
 *  \returns Return YES for success, NO for failure.
 */

- (BOOL)webViewController:(WebViewController *)controller addTrustedAnchor:(SecCertificateRef)anchor error:(NSError **)errorPtr;

/*! Called by the WebViewController to log various actions. 
 *  Will be called on the main thread.
 *  \param controller The controller instance; will not be nil.
 *  \param format A standard NSString-style format string; will not be nil.
 *  \param arguments Arguments for that format string.
 */

- (void)webViewController:(WebViewController *)controller logWithFormat:(NSString *)format arguments:(va_list)arguments;

@end
