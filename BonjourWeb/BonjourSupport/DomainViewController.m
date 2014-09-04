/*
 
    File: DomainViewController.m
Abstract:  View controller for the domain list.
This object manages a NSNetServiceBrowser configured to look for Bonjour
domains.
It has two arrays of NSString objects that are displayed in two sections of a
table view.
When the service browser reports that it has discovered a domain, that domain
is added to the first array.
When a domain goes away it is removed from the first array.
It allows the user to add/remove their own domains from the second array, which
is displayed in the second section of the table.
When an item in the table view is selected, the delegate is called with the
corresponding domain.

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

#import "DomainViewController.h"

#define kProgressIndicatorSize 20.0

@interface DomainViewController ()
@property(nonatomic, assign) BOOL showDisclosureIndicators;
@property(nonatomic, retain) NSMutableArray* domains;
@property(nonatomic, retain) NSMutableArray* customs;
@property(nonatomic, retain) NSString* customTitle;
@property(nonatomic, retain) NSString* addDomainTitle;
@property(nonatomic, retain) NSNetServiceBrowser* netServiceBrowser;
@property(nonatomic, assign) BOOL showCancelButton;

- (void)addButtons:(BOOL)editing;
- (void)addAction:(id)sender;
- (void)editAction:(id)sender;
@end

@implementation DomainViewController

@synthesize delegate = _delegate;
@synthesize showDisclosureIndicators = _showDisclosureIndicators;
@synthesize domains = _domains;
@synthesize customs = _customs;
@synthesize customTitle = _customTitle;
@synthesize addDomainTitle = _addDomainTitle;
@dynamic netServiceBrowser;
@synthesize showCancelButton = _showCancelButton;

// Initialization. BonjourBrowser invokes this during its initialization.
- (id)initWithTitle:(NSString*)title showDisclosureIndicators:(BOOL)show customsTitle:(NSString*)customsTitle customs:(NSMutableArray*)customs addDomainTitle:(NSString*)addDomainTitle showCancelButton:(BOOL)showCancelButton {
	if ((self = [super initWithStyle:UITableViewStylePlain])) {
		self.title = title;
		self.domains = [[[NSMutableArray alloc] init] autorelease];
		self.showDisclosureIndicators = show;
		self.customTitle = customsTitle;
		self.customs = customs ? customs : [NSMutableArray array];
		self.addDomainTitle = addDomainTitle;
		self.showCancelButton = showCancelButton;
		[self addButtons:self.tableView.editing];
	}

	return self;
}

// Stores newBrowser in the _netServiceBrowser instance variable. If _netServiceBrowser has already been set,
// this first sends it a -stop message before releasing it.
- (void)setNetServiceBrowser:(NSNetServiceBrowser*)newBrowser {
	[_netServiceBrowser stop];
	[newBrowser retain];
	[_netServiceBrowser release];
	_netServiceBrowser = newBrowser;
}


- (NSNetServiceBrowser*)netServiceBrowser {
	return _netServiceBrowser;
}


- (void)addAddButton:(BOOL)right {
	// add + button as the nav bar's custom right view
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
								  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction:)];
	if (right) self.navigationItem.rightBarButtonItem = addButton;
	else self.navigationItem.leftBarButtonItem = addButton;
	[addButton release];
}

- (void)addButtons:(BOOL)editing {
	if (editing) {
		// Add the "done" button to the navigation bar
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
									   initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
		
		self.navigationItem.leftBarButtonItem = doneButton;
		[doneButton release];

		[self addAddButton:YES];
	} else {
		if ([self.customs count]) {
			// Add the "edit" button to the navigation bar
			UIBarButtonItem *editButton = [[UIBarButtonItem alloc]
										   initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction:)];
			
			self.navigationItem.leftBarButtonItem = editButton;
			[editButton release];
		} else {
			[self addAddButton:NO];
		}
		
		if (self.showCancelButton) {
			// add Cancel button as the nav bar's custom right view
			UIBarButtonItem *addButton = [[UIBarButtonItem alloc]
										  initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
			self.navigationItem.rightBarButtonItem = addButton;
			[addButton release];
		} else {
			self.navigationItem.rightBarButtonItem = nil;
		}
	}
}

- (BOOL)commonSetup {
	self.netServiceBrowser = [[[NSNetServiceBrowser alloc] init] autorelease];
	if(!self.netServiceBrowser) {
		return NO;
	}
	
	[self.netServiceBrowser setDelegate:self];
	return YES;
}

// A cover method to -[NSNetServiceBrowser searchForBrowsableDomains].
- (BOOL)searchForBrowsableDomains {
	if (![self commonSetup]) return NO;
	[self.netServiceBrowser searchForBrowsableDomains];
	return YES;
}

// A cover method to -[NSNetServiceBrowser searchForRegistrationDomains].
- (BOOL)searchForRegistrationDomains {
	if (![self commonSetup]) return NO;
	[self.netServiceBrowser searchForRegistrationDomains];	
	return YES;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1 + ([self.customs count] ? 1 : 0);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [(section ? self.customs : self.domains) count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return section ? self.customTitle : @"Bonjour"; // Note that "Bonjour" is the proper name of the technology, therefore should not be localized
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"] autorelease];
	}
	
	// Set up the text for the cell
	cell.textLabel.text = [(indexPath.section ? self.customs : self.domains) objectAtIndex:indexPath.row];
	cell.textLabel.textColor = [UIColor blackColor];
	cell.accessoryType = self.showDisclosureIndicators ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section && tableView.editing;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.delegate domainViewController:self didSelectDomain:[(indexPath.section ? self.customs : self.domains) objectAtIndex:indexPath.row]];
}


- (void)updateUI {
	// Sort the domains by name, then modify the selection, as it may have moved
	[self.domains sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	[self.tableView reloadData];
}

/*
    The 'domain' parameter passed to netServiceBrowser:didRemoveDomain:moreComing: and netServiceBrowser:didFindDomain:moreComing: may contain escaped characters. This function unescapes them before they are added to or removed from the list that is displayed to the user.
*/
- (NSString*) transmogrify:(NSString*)aString {
	
	NSString* tmp = [NSString stringWithString:aString];
	const char *ostr = [tmp UTF8String];
	const char *cstr = ostr;
	char *ptr = (char*) ostr;
	
	while (*cstr) {
		char c = *cstr++;
		if (c == '\\')
		{
			c = *cstr++;
			if (isdigit(cstr[-1]) && isdigit(cstr[0]) && isdigit(cstr[1]))
			{
				NSInteger v0 = cstr[-1] - '0';						// then interpret as three-digit decimal
				NSInteger v1 = cstr[ 0] - '0';
				NSInteger v2 = cstr[ 1] - '0';
				NSInteger val = v0 * 100 + v1 * 10 + v2;
				if (val <= 255) { c = (char)val; cstr += 2; }	// If valid three-digit decimal value, use it
			}
		}
		*ptr++ = c;
	}
	ptr--;
	*ptr = 0;
	return [NSString stringWithUTF8String:ostr];
}


- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveDomain:(NSString*)domain moreComing:(BOOL)moreComing {
	[self.domains removeObject:[self transmogrify:domain]];
	
	// moreComing really means that there are no more messages in the queue from the Bonjour daemon, so we should update the UI.
	// When moreComing is set, we don't update the UI so that it doesn't 'flash'.
	if (!moreComing)
		[self updateUI];
}	


- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindDomain:(NSString*)domain moreComing:(BOOL)moreComing {
	NSString* tmp = [self transmogrify:domain];
	if (![self.domains containsObject:tmp]) [self.domains addObject:tmp];

	// moreComing really means that there are no more messages in the queue from the Bonjour daemon, so we should update the UI.
	// When moreComing is set, we don't update the UI so that it doesn't 'flash'.
	if (!moreComing)
		[self updateUI];
}	


- (void)doneAction:(id)sender {
	[self.tableView setEditing:NO animated:YES];
	[self addButtons:self.tableView.editing];
}


- (void)editAction:(id)sender {
	[self.tableView setEditing:YES animated:YES];
	[self addButtons:self.tableView.editing];
}


- (IBAction)cancelAction {
	[self.delegate domainViewController:self didSelectDomain:nil];
}


- (void)addAction:(id)sender {
	SimpleEditViewController* sevc = [[SimpleEditViewController alloc] initWithTitle:self.addDomainTitle currentText:nil];
	[sevc setDelegate:self];
	UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:sevc];
	[sevc release];
	[self.navigationController presentModalViewController:nc animated:YES];
	[nc release];
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	assert(editingStyle == UITableViewCellEditingStyleDelete);
	assert(indexPath.section == 1);
	[self.customs removeObjectAtIndex:indexPath.row];
	if (![self.customs count]) {
		[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationRight];
	} else {
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
	}
	[self addButtons:self.tableView.editing];
}


- (void) simpleEditViewController:(SimpleEditViewController*)sevc didGetText:(NSString*)text {
	[self.navigationController dismissModalViewControllerAnimated:YES];

	if (![text length])
		return;
	
	if (![self.customs containsObject:text]) {
		[self.customs addObject:text];
		[self.customs sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	}
	
	[self addButtons:self.tableView.editing];
	[self.tableView reloadData];
	NSUInteger ints[2] = {1,[self.customs indexOfObject:text]};
	NSIndexPath* indexPath = [NSIndexPath indexPathWithIndexes:ints length:2];
	[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
}


- (void)dealloc {
	[_domains release];
	[_customs release];
	[_customTitle release];
	[_addDomainTitle release];
	[_netServiceBrowser release];
	
	[super dealloc];
}

@end
