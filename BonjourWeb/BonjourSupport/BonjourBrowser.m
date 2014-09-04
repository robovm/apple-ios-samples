/*
 
    File: BonjourBrowser.m 
Abstract:  A subclass of UINavigationController that handles the UI needed for a user to
browse for Bonjour services.
It contains list view controllers for domains and service instances.
It allows the user to add their own domains.
 
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

#import "BonjourBrowser.h"
#import "BrowserViewController.h"
#import "DomainViewController.h"


@interface BonjourBrowser ()
@property(nonatomic, retain, readwrite) BrowserViewController* bvc;
@property(nonatomic, retain, readwrite) DomainViewController* dvc;
@property(nonatomic, retain, readwrite) NSString* type;
@property(nonatomic, retain, readwrite) NSString* domain;
@property(nonatomic, assign, readwrite) BOOL showDisclosureIndicators;
@property(nonatomic, assign, readwrite) BOOL showCancelButton;
- (void) setupBrowser;
@end


@implementation BonjourBrowser


@synthesize bvc = _bvc;
@synthesize dvc = _dvc;
@synthesize type = _type;
@synthesize domain = _domain;
@synthesize showDisclosureIndicators = _showDisclosureIndicators;
@synthesize showCancelButton = _showCancelButton;


- (id) initForType:(NSString*)type inDomain:(NSString*)domain
	   customDomains:(NSMutableArray*)customDomains
	   showDisclosureIndicators:(BOOL)showDisclosureIndicators
	   showCancelButton:(BOOL)showCancelButton {
	
    // Create some strings that will be used in the DomainViewController.
	NSString *domainsTitle = NSLocalizedString(@"Domains", @"Domains title");
	NSString *domainLabel = NSLocalizedString(@"Added Domains", @"Added Domains label");
	NSString *addDomainTitle = NSLocalizedString(@"Add Domain", @"Add Domain title");
	NSString *searchingForServicesString = NSLocalizedString(@"Searching for services", @"Searching for services string");
    
    // Initialize the DomainViewController, which uses a NSNetServiceBrowser to look for Bonjour domains.
	DomainViewController* dvc = [[DomainViewController alloc] initWithTitle:domainsTitle showDisclosureIndicators:YES customsTitle:domainLabel customs:customDomains addDomainTitle:addDomainTitle showCancelButton:showCancelButton];
	
	if (dvc && (self = [super initWithRootViewController:dvc])) {
		self.type = type;
		self.showDisclosureIndicators = showDisclosureIndicators;
		self.showCancelButton = showCancelButton;
		self.searchingForServicesString	= searchingForServicesString;
		self.dvc = dvc;
		[self.dvc setDelegate:self];
		[self.dvc searchForBrowsableDomains]; // Tells the DomainViewController's NSNetServiceBrowser to start a search for domains that are browsable via Bonjour and the computer's network configuration.

		if ([domain length]) {
			self.domain = domain;
			[self setupBrowser]; // Initiate a search for Bonjour services of the type self.type.
			[self pushViewController:self.bvc animated:NO];
		}
	}
	
	[dvc release];
	
	return self;
}

- (NSString*) searchingForServicesString {
	return _searchingForServicesString;
}

// This property holds a string that displays the status of the service search to the user.
- (void) setSearchingForServicesString:(NSString*)searchingForServicesString {
	if (_searchingForServicesString != searchingForServicesString) {
		[_searchingForServicesString release];
		_searchingForServicesString = [searchingForServicesString copy];

		if (self.bvc) {
			self.bvc.searchingForServicesString = _searchingForServicesString;
		}
	}
}

- (void) setDelegate:(id<BonjourBrowserDelegate>)delegate {
	__delegate = delegate;
	super.delegate = delegate;
}


- (id<BonjourBrowserDelegate>) delegate {
	assert(__delegate == super.delegate);
	return __delegate;
}


- (BOOL) showTitleInNavigationBar {
	return _showTitleInNavigationBar;
}


- (void) setShowTitleInNavigationBar:(BOOL)show {
	_showTitleInNavigationBar = show;
	if (show) {
		self.bvc.navigationItem.prompt = self.title;
		self.dvc.navigationItem.prompt = self.title;
	} else {
		self.bvc.navigationItem.prompt = nil;
		self.dvc.navigationItem.prompt = nil;
	}
}


- (void) browserViewController:(BrowserViewController*)bvc didResolveInstance:(NSNetService*)service {
	assert(bvc == self.bvc);
	[self.delegate bonjourBrowser:self didResolveInstance:service];
}

// Create a BrowserViewController, which manages a NSNetServiceBrowser configured to look for Bonjour services.
- (void) setupBrowser {
	BrowserViewController* aBvc = [[BrowserViewController alloc] initWithTitle:self.domain showDisclosureIndicators:self.showDisclosureIndicators showCancelButton:self.showCancelButton];
    aBvc.searchingForServicesString = self.searchingForServicesString;
	aBvc.delegate = self;
    // Calls -[NSNetServiceBrowser searchForServicesOfType:inDomain:].
	[aBvc searchForServicesOfType:self.type inDomain:self.domain];

    // Store the BrowerViewController in an instance variable.
	self.bvc = aBvc;
	[aBvc release];
	if (self.showTitleInNavigationBar)
		self.bvc.navigationItem.prompt = self.title;
}

// This method will be invoked when the user selects one of the domains from the list.
// The domain parameter will be the selected domain or nil if the user taps the 'Cancel' button (if shown).
- (void) domainViewController:(DomainViewController*)dvc didSelectDomain:(NSString*)domain {
	if (!domain) {
		// Cancel
		[self.delegate bonjourBrowser:self didResolveInstance:nil];
		return;
	}

	self.domain = domain;
	[self setupBrowser];
	[self pushViewController:self.bvc animated:YES];
}


- (void) dealloc {
	[_dvc release];
	[_bvc release];
	[_type release];
	[_domain release];
	[_searchingForServicesString release];
	[super dealloc];
}

@end
