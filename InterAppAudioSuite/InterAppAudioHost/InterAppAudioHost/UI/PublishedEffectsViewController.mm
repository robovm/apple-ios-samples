/*
     File: PublishedEffectsViewController.mm
 Abstract: 
  Version: 1.1.2
 
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

#import "PublishedEffectsViewController.h"
#import <CoreFoundation/CFNotificationCenter.h>

@implementation PublishedEffectsViewController
@synthesize delegate = _delegate;

#pragma mark - Initialization / Deallocation
- (void) viewDidLoad {
    [super viewDidLoad];
    
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserverForName:(NSString *)kAudioComponentRegistrationsChangedNotification  object:nil queue:nil usingBlock: ^(NSNotification *note) {
        [self refreshAUList];
        NSIndexSet *sections = [NSIndexSet indexSetWithIndex: 0];
        [publishedEffectsTable reloadSections: sections withRowAnimation: UITableViewRowAnimationAutomatic];
    }];
	
	_publishedEffects = [[NSMutableArray alloc] init];
	publishedEffectsTable.layer.borderWidth = 2;
	publishedEffectsTable.layer.borderColor = [[UIColor blackColor] CGColor];
	
	[self refreshAUList];
}

- (void) dealloc {
    [publishedEffectsTable release];
    [_publishedEffects release];
    [super dealloc];
}

- (void) refreshAUList {
	[_publishedEffects removeAllObjects];
	
	AudioComponentDescription searchDesc = { 0, 0, 0, 0, 0 };
	AudioComponent comp = NULL;
	while (true) {
		comp = AudioComponentFindNext(comp, &searchDesc);
		if (comp == NULL) break;
		
		AudioComponentDescription desc;
		if (AudioComponentGetDescription(comp, &desc)) continue;
		
		switch (desc.componentType) {
            case kAudioUnitType_RemoteEffect:
			{
				RemoteAU *rau = [[RemoteAU alloc] init];
				rau->_desc = desc;
				rau->_comp = comp;
                rau->_image = [AudioComponentGetIcon(comp, 32) retain];
				
				AudioComponentCopyName(comp, (CFStringRef *)&rau->_name);
                
				[_publishedEffects addObject: rau];
			}
                break;
		}
	}
}

#pragma mark - Actions
- (IBAction) toggleDone:(id) sender {
    [self.delegate closeView];
}

#pragma mark - Table view data source
- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
	return 1;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
     return [_publishedEffects count];
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    RemoteAU *rau = [_publishedEffects objectAtIndex: [indexPath indexAtPosition:1]];
    
	cell.imageView.image = rau->_image;
	cell.textLabel.text  = rau->_name;
    return cell;
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    RemoteAU *rau = [_publishedEffects objectAtIndex: [indexPath indexAtPosition:1]];
    [AUDIO_ENGINE addRemoteAU:rau];
    [self.delegate closeView];
}

@end
