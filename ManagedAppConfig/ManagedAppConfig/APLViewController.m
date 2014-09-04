/*
     File: APLViewController.m
 Abstract: The sample's primary view controller. The sample app configuration and feedback code resides in this view controller.
 
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


#import "APLViewController.h"


NS_ENUM(NSUInteger, LoadingState) {
    kLoadingStateIdle,
    kLoadingStateBusy
} ;


@interface APLViewController () <UIGestureRecognizerDelegate, UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *serverURLUILabel;
@property (weak, nonatomic) IBOutlet UIButton *goButton;
@property (weak, nonatomic) IBOutlet UILabel *successUILabel;
@property (weak, nonatomic) IBOutlet UILabel *failureUILabel;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UISwitch *cloudDocumentSyncEnabledSwitch;

@property (nonatomic, assign) NSUInteger successCount;
@property (nonatomic, assign) NSUInteger failureCount;
@property (nonatomic, assign) enum LoadingState loadingState;

@end



@implementation APLViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.webView.layer.borderWidth = 1.0;

    // Add Notification Center observer to be alerted of any change to NSUserDefaults.
    // Managed app configuration changes pushed down from an MDM server appear in NSUSerDefaults.
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self readDefaultsValues];
                                                  }];

    // Call readDefaultsValues to make sure default values are read at least once.
    [self readDefaultsValues];
}



// The Managed app configuration dictionary pushed down from an MDM server are stored in this key.
static NSString * const kConfigurationKey = @"com.apple.configuration.managed";

// This sample application allows for a server url and cloud document switch to be configured via MDM
// Application developers should document feedback dictionary keys, including data types and valid value ranges.
static NSString * const kConfigurationServerURLKey = @"serverURL";
static NSString * const kConfigurationDisableCloudDocumentSyncKey = @"disableCloudDocumentSync";

// The dictionary that is sent back to the MDM server as feedback must be stored in this key.
static NSString * const kFeedbackKey = @"com.apple.feedback.managed";

// This sample application tracks a success and failure count for the loading of a UIWebView.
// Application developers should document feedback dictionary keys including data types to expect for feedback queries
static NSString * const kFeedbackSuccessCountKey = @"successCount";
static NSString * const kFeedbackFailureCountKey = @"failureCount";


- (void)readDefaultsValues {
    
    NSDictionary *serverConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kConfigurationKey];
    NSString *serverURLString = serverConfig[kConfigurationServerURLKey];
    
    // Data coming from MDM server should be validated before use.
    // If validation fails, be sure to set a sensible default value as a fallback, even if it is nil.
    if (serverURLString && [serverURLString isKindOfClass:[NSString class]]) {
        self.serverURLUILabel.text = serverURLString;
    } else {
        self.serverURLUILabel.text = @"http://foo.bar";
    }
    
    NSNumber *disableCloudDocumentSync = serverConfig[kConfigurationDisableCloudDocumentSyncKey];

    if (disableCloudDocumentSync && [disableCloudDocumentSync isKindOfClass:[NSNumber class]]) {
        self.cloudDocumentSyncEnabledSwitch.on = ![disableCloudDocumentSync boolValue];
    } else {
        self.cloudDocumentSyncEnabledSwitch.on = YES;
    }
    
    // Fetch the success and failure count values from NSUserDefaults to display.
    // Data validation for feedback values is a good idea, in case the application wrote out an unexpected value.
    NSDictionary *feedback = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kFeedbackKey];
    
    NSNumber *successCount = feedback[kFeedbackSuccessCountKey];
    if (successCount && [successCount isKindOfClass:[NSNumber class]]) {
        self.successCount = [successCount unsignedIntegerValue];
    } else {
        self.successCount = 0;
    }
    
    self.successUILabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.successCount];
    
    NSNumber *failureCount = feedback[kFeedbackFailureCountKey];
    if (failureCount && [failureCount isKindOfClass:[NSNumber class]]) {
        self.failureCount = [failureCount unsignedIntegerValue];
    } else {
        self.failureCount = 0;
    }
    
    self.failureUILabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.failureCount];
}


- (IBAction)go:(id)sender {
    if (self.loadingState == kLoadingStateIdle) {
        self.loadingState = kLoadingStateBusy;
        self.goButton.enabled = NO;
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.serverURLUILabel.text]]];
    }
}


- (void)incrementSuccessCount {
    self.successCount += 1;
    self.successUILabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.successCount];

    // Write the updated value into the feedback dictionary each time it changes.
    NSMutableDictionary *feedback = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kFeedbackKey] mutableCopy];
    if (!feedback) {
        feedback = [NSMutableDictionary dictionary];
    }
    feedback[kFeedbackSuccessCountKey] = @(self.successCount);
    [[NSUserDefaults standardUserDefaults] setObject:feedback forKey:kFeedbackKey];
}


- (void)incrementFailureCount {
    self.failureCount += 1;
    self.failureUILabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.failureCount];

    // Write the updated value into the feedback dictionary each time it changes.
    NSMutableDictionary *feedback = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kFeedbackKey] mutableCopy];
    if (!feedback) feedback = [NSMutableDictionary dictionary];
    feedback[kFeedbackFailureCountKey] = @(self.failureCount);
    [[NSUserDefaults standardUserDefaults] setObject:feedback forKey:kFeedbackKey];
}


#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (self.loadingState == kLoadingStateBusy) {
        self.loadingState = kLoadingStateIdle;
        self.goButton.enabled = YES;
        [self incrementSuccessCount];
    }
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (self.loadingState == kLoadingStateBusy) {
        self.loadingState = kLoadingStateIdle;
        self.goButton.enabled = YES;
        [self incrementFailureCount];
    }
}


@end
