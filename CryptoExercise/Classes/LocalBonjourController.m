/*
 
 File: LocalBonjourController.m
 Abstract: Handles all of the Bonjour initialization code and back-end to the
 UIScrollView for browsing network service instances of this sample.
 
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

#import "LocalBonjourController.h"
#import "CryptoCommon.h"
#import "ServiceController.h"
#import "AppDelegate.h"
#import "CryptoServer.h"
#import "KeyGeneration.h"
#import "SecKeyWrapper.h"

@implementation LocalBonjourController

@synthesize netServiceBrowser, services, tableView, serviceController, cryptoServer, keyGenerationController;

- (void)viewDidLoad {
    NSMutableArray *anArray = [[NSMutableArray alloc] init];
    self.services = anArray;
    [anArray release];
	
	// Check to see if keys have been generated.
    if (	![[SecKeyWrapper sharedWrapper] getPublicKeyRef]		|| 
			![[SecKeyWrapper sharedWrapper] getPrivateKeyRef]		||
			![[SecKeyWrapper sharedWrapper] getSymmetricKeyBytes]) {
		
        [[SecKeyWrapper sharedWrapper] generateKeyPair:kAsymmetricSecKeyPairModulusSize];
		[[SecKeyWrapper sharedWrapper] generateSymmetricKey];
    }
	
	CryptoServer * thisServer = [[CryptoServer alloc] init];
	self.cryptoServer = thisServer;
	[self.cryptoServer run];
	[thisServer release];
}

- (KeyGeneration *)keyGenerationController {
    if (keyGenerationController == nil) {
        self.keyGenerationController = [[[KeyGeneration alloc] initWithNibName:@"KeyGeneration" bundle:nil] autorelease];
    }
    return keyGenerationController;
}

- (ServiceController *)serviceController {
    if (serviceController == nil) {
        serviceController = [[ServiceController alloc] initWithNibName:@"ServiceView" bundle:nil];
    }
    return serviceController;
}

- (IBAction)regenerateKeys {
    KeyGeneration *controller = self.keyGenerationController;
    controller.server = cryptoServer;
    [self.navigationController presentModalViewController:controller animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Creates an NSNetServiceBrowser that searches for services of a particular type in a particular domain.
// If a service is currently being resolved, stop resolving it and stop the service browser from
// discovering other services.
- (BOOL)searchForCryptoServices {
	[self.netServiceBrowser stop];
	[self.services removeAllObjects];
	[tableView reloadData];
    
	NSNetServiceBrowser * aNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
	aNetServiceBrowser.delegate = self;
	self.netServiceBrowser = aNetServiceBrowser;
	[aNetServiceBrowser release];
    
	[self.netServiceBrowser searchForServicesOfType:kBonjourServiceType inDomain:@"local"];
    
	return YES;
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)service moreComing:(BOOL)moreComing {
	[self.services removeObject:service];
    if (!moreComing) [tableView reloadData];
}	

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didFindService:(NSNetService*)service moreComing:(BOOL)moreComing {
	
#ifndef ALLOW_TO_CONNECT_TO_SELF
	// Don't display our published record
    if (![[cryptoServer.netService name] isEqualToString:[service name]]) {
        // If a service came online, add it to the list and update the table view if no more events are queued.
        [self.services addObject:service];
        
	}
#else
	[self.services addObject:service];
#endif
	
    if (!moreComing) {
        [tableView reloadData];
    }
}	

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return services.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"MyCell"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MyCell"] autorelease];
    }
    cell.textLabel.text = [[services objectAtIndex:indexPath.row] name];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.serviceController.service = [self.services objectAtIndex:indexPath.row];
	[self.navigationController pushViewController:self.serviceController animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [self searchForCryptoServices];
}

- (void)dealloc {
	[netServiceBrowser release];
	[services release];
	[tableView release];
	[serviceController release];
	[keyGenerationController release];
	[cryptoServer release];
	[super dealloc];
}


@end
