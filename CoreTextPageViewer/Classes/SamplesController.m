
/*
     File: SamplesController.m
 Abstract: A table view controller to manage and display a list file names of sample layouts to draw.
 The view controller manages one array:
 * samplesForDisplay is the array that corresponds to the full set samples the app can show.
 
 The table view displays the contents of the samplesForDisplay array.
 
 The view controller has a delegate that it notifies if row in the table view is selected.
 
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

#import "SamplesController.h"

@implementation SamplesController

@synthesize delegate, samplesForDisplay, selectedSample;

// Utility helper method to extract list of sample document filenames from bundle
// used to present list of samples for user selection in UI.
- (NSArray*)copySamplesInBundle {
	
	NSMutableArray* result = [[NSMutableArray alloc] init];
	NSArray* filesInBundle = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[NSBundle mainBundle] bundlePath] error:NULL];	
	for (NSString* fileName in filesInBundle) {
		if ([fileName hasSuffix:@".xml"]) {
			// remove file extension for UI
			[result addObject:[fileName stringByDeletingPathExtension]];
		}
	}
	return result;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Samples";
    self.contentSizeForViewInPopover = CGSizeMake(300.0, 280.0);

	// Get list of samples to show in UI 
    samplesForDisplay = [self copySamplesInBundle];	
	// Initially, there is no active sample (RootViewController will specify this)
	selectedSample = @"";
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [samplesForDisplay count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	// Set the tableview cell text to the name of the sample at the given index
	NSString *cellSampleName = [samplesForDisplay objectAtIndex:indexPath.row];
    cell.textLabel.text = cellSampleName; 
	if ([selectedSample isEqual:cellSampleName]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellSampleName = [samplesForDisplay objectAtIndex:indexPath.row];
    // Notify the delegate if a row is selected (adding back file extension for delegate)
	if (delegate && [delegate respondsToSelector:@selector(samplesController:didSelectString:)]) {
		[delegate samplesController:self didSelectString:[cellSampleName stringByAppendingPathExtension:@"xml"]];
	}
	self.selectedSample = cellSampleName;
	[self.tableView reloadData]; // refresh tableView cells for selection state change
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [samplesForDisplay release];
    [super dealloc];
}


@end

