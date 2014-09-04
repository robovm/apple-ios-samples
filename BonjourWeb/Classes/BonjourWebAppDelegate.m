/*
 
    File: BonjourWebAppDelegate.m 
Abstract:  The application delegate.
It creates the BonjourBrowser (a navigation controller) and is the delgate for
that BonjourBrowser.
When it gets the delegate callback, it constructs a URL and launches that URL
in Safari.
 
 Version: 2.9 
 
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
 
Copyright (C) 2010 Apple Inc. All Rights Reserved. 
 
 
*/

#import "BonjourWebAppDelegate.h"
#import "BonjourBrowser.h"


#define kWebServiceType @"_http._tcp"
#define kInitialDomain  @"local"


@implementation BonjourWebAppDelegate

@synthesize window;
@synthesize browser;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
	// Create the Bonjour Browser for Web services
	BonjourBrowser *aBrowser = [[BonjourBrowser alloc] initForType:kWebServiceType
														  inDomain:kInitialDomain
												  customDomains:nil // we won't save any additional domains added by the user
									   showDisclosureIndicators:NO
											   showCancelButton:NO];
	self.browser = aBrowser;
	[aBrowser release];

	self.browser.delegate = self;
    
    // We want to let the user know that the services list is dynamic and always updating, even when there are no
    // services currently found.
    self.browser.searchingForServicesString = NSLocalizedString(@"Searching for web services", @"Searching for web services string");

	// Add the controller's view as a subview of the window
	[self.window addSubview:[self.browser view]];
}


- (void)dealloc {
	[browser release];
	[window release];
	[super dealloc];
}


- (NSString *)copyStringFromTXTDict:(NSDictionary *)dict which:(NSString*)which {
	// Helper for getting information from the TXT data
	NSData* data = [dict objectForKey:which];
	NSString *resultString = nil;
	if (data) {
		resultString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}
	return resultString;
}


- (void) bonjourBrowser:(BonjourBrowser*)browser didResolveInstance:(NSNetService*)service {
	// Construct the URL including the port number
	// Also use the path, username and password fields that can be in the TXT record
	NSDictionary* dict = [[NSNetService dictionaryFromTXTRecordData:[service TXTRecordData]] retain];
	NSString *host = [service hostName];
	
	NSString* user = [self copyStringFromTXTDict:dict which:@"u"];
	NSString* pass = [self copyStringFromTXTDict:dict which:@"p"];
	
	NSString* portStr = @"";
	
	// Note that [NSNetService port:] returns an NSInteger in host byte order
	NSInteger port = [service port];
	if (port != 0 && port != 80)
			portStr = [[NSString alloc] initWithFormat:@":%d",port];
	
	NSString* path = [self copyStringFromTXTDict:dict which:@"path"];
	if (!path || [path length]==0) {
			[path release];
			path = [[NSString alloc] initWithString:@"/"];
	} else if (![[path substringToIndex:1] isEqual:@"/"]) {
			NSString *tempPath = [[NSString alloc] initWithFormat:@"/%@",path];
			[path release];
			path = tempPath;
	}
	
	NSString* string = [[NSString alloc] initWithFormat:@"http://%@%@%@%@%@%@%@",
												user?user:@"",
												pass?@":":@"",
												pass?pass:@"",
												(user||pass)?@"@":@"",
												host,
												portStr,
												path];
	
	NSURL *url = [[NSURL alloc] initWithString:string];
	[[UIApplication sharedApplication] openURL:url];
	
	[url release];
	[string release];
	[portStr release];
	[pass release];
	[user release];
	[dict release];
	[path release];
}

@end
