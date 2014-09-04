/*
 
 File: AppDelegate.m
 Abstract: Main controller that houses the operation queue and 
 initializes the LocalBonjour Controller.
 
 Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2008-2009 Apple Inc. All Rights Reserved.
 
 */

#import "AppDelegate.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

@implementation AppDelegate

@synthesize window, navController, cryptoQueue;

- (BOOL)isNetworkAvailableFlags:(SCNetworkReachabilityFlags *)outFlags {
	SCNetworkReachabilityRef	defaultRouteReachability;
	struct sockaddr_in			zeroAddress;
	
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
	
	defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
	
	SCNetworkReachabilityFlags flags;
	BOOL gotFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
	if (!gotFlags) {
        return NO;
    }
    
    // kSCNetworkReachabilityFlagsReachable indicates that the specified nodename or address can
	// be reached using the current network configuration.
	BOOL isReachable = flags & kSCNetworkReachabilityFlagsReachable;
	
	// This flag indicates that the specified nodename or address can
	// be reached using the current network configuration, but a
	// connection must first be established.
	//
	// If the flag is false, we don't have a connection. But because CFNetwork
    // automatically attempts to bring up a WWAN connection, if the WWAN reachability
    // flag is present, a connection is not required.
	BOOL noConnectionRequired = !(flags & kSCNetworkReachabilityFlagsConnectionRequired);
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN)) {
		noConnectionRequired = YES;
	}
	
	// Callers of this method might want to use the reachability flags, so if an 'out' parameter
	// was passed in, assign the reachability flags to it.
	if (outFlags) {
		*outFlags = flags;
	}
	
	return isReachable && noConnectionRequired;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	// Is WiFi network available? That's necessary to use Bonjour.
	if ([self isNetworkAvailableFlags:NULL] == NO) {
		// open an alert with just an OK button
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No WiFi network available." 
														message:@"Exit this app and enable WiFi using the Settings application."
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles: nil];
		[alert show];	
		[alert release];
	}
	else {	
		// Add the controller's view as a subview of the window
		[self.window addSubview:navController.view]; 
		
		NSOperationQueue * theQueue = [[NSOperationQueue alloc] init];
		self.cryptoQueue = theQueue;
		[theQueue release];
	}
}

- (void)dealloc {
    [cryptoQueue release];
	[navController release];
	[window release];
	[super dealloc];
}

@end
