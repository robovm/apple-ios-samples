/*
     File: AssetViewController.m
 Abstract: Table view controller that manages displaying a single asset. Shows movie, track and metadata information. Allows the metadata to be edited, and the movie to be exported. Also displays export preset options.
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */


#import "AssetItem.h"
#import "AssetViewController.h"
#import "TrackViewController.h"
#import "MetadataViewController.h"
#import "NewMetadataViewController.h"
#import "ExportProgressViewController.h"
#import "PresetViewController.h"

enum AssetSections {
	movieSection,
	trackSection,
	metadataSection,
	settingsSection,
	metadataReplaceSection,
	exportSection
};

@implementation AssetViewController

@synthesize assetItem = _assetItem;


#pragma mark - UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)viewDidLoad
{
	self.title = @"Movie";
	self.navigationItem.rightBarButtonItem = [self editButtonItem];
	
	__unsafe_unretained __block AssetViewController *weakSelf = (AssetViewController *)self;
	[self.assetItem loadMetadataWithCompletionHandler:^{
		[weakSelf.tableView reloadData];
	}];
	
	[self.assetItem loadTracksWithCompletionHandler:^{
		[weakSelf.tableView reloadData];
	}];
	
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:settingsSection]] 
						  withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger row = indexPath.row;
	NSInteger section = indexPath.section;
	
	// If the track is selected, show information about the track
	if (section == trackSection && self.assetItem.tracks.count > 0)
	{
		AVAssetTrack *track = [self.assetItem.tracks objectAtIndex:row];
		TrackViewController *trackViewController = [[TrackViewController alloc] initWithStyle:UITableViewStyleGrouped];
		trackViewController.assetTrack = track;
		[self.navigationController pushViewController:trackViewController animated:YES];
	}
	// If the metadata is selected then show information about that metadata
	else if(section == metadataSection && self.assetItem.metadata.count > 0)
	{
		AVMetadataItem *metadataItem = [self.assetItem.metadata objectAtIndex:row];
		MetadataViewController *metadataViewController = [[MetadataViewController alloc] initWithStyle:UITableViewStyleGrouped];
		metadataViewController.metadataItem = metadataItem;
		[self.navigationController pushViewController:metadataViewController animated:YES];
	}
	else if (section == settingsSection && row == 0)
	{
		PresetViewController *presetViewController = [[PresetViewController alloc] initWithStyle:UITableViewStyleGrouped];
		presetViewController.assetItem = self.assetItem;
		[self.navigationController pushViewController:presetViewController animated:YES];
	}
	else if (section == metadataReplaceSection)
	{
		// Set the new metadata keys and values through a modal popup. Insert the items when the modal is dismissed.
		NewMetadataViewController *newMetadataViewController = [[NewMetadataViewController alloc] initWithNibName:nil bundle:nil];
		newMetadataViewController.delegate = self;
		
		UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:newMetadataViewController];
		controller.modalPresentationStyle = UIModalPresentationFormSheet;
		[self.navigationController presentModalViewController:controller animated:YES];
	}
	// Use the last section to start exporting
	else if(section == exportSection)
	{
		ExportProgressViewController *progressViewController = [[ExportProgressViewController alloc] initWithNibName:@"ExportView" bundle:nil];
		progressViewController.assetItem = self.assetItem;
		UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:progressViewController];
		controller.modalPresentationStyle = UIModalPresentationFormSheet;
		[self.navigationController presentModalViewController:controller animated:YES];
		
		[self.assetItem exportAssetWithCompletionHandler:^(NSError *error){
			dispatch_async(dispatch_get_main_queue(), ^{
				if (error != nil)
				{
					UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
																		message:[error localizedFailureReason] delegate:self
															  cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
					[alertView show];
				}
			});
		}];
		
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:exportSection];
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger numRows = 0;
	if (section == movieSection || section == exportSection || section == metadataReplaceSection)
		numRows = 1;
	else if (section == settingsSection)
		numRows = 2;
	else if (section == trackSection)
		numRows = self.assetItem.tracks.count;
	else if (section == metadataSection)
		numRows = self.assetItem.metadata.count;
	
	return numRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{	
	NSString *title = nil;
	
	if (section == movieSection)
		title = @"Movie";
	else if (section == trackSection)
		title = @"Tracks";
	else if (section == metadataSection)
		title = @"Metadata";
	else if (section == settingsSection)
		title = @"Settings";
	else if (section == exportSection || section == metadataReplaceSection)
		title = @"";
	
	return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *BoolCellIdentifier = @"BoolCell";
	static NSString *OtherCellIdentifier = @"OtherCell";
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	BOOL indexPathIsForBoolSetting = section == settingsSection && row == 1;
	NSString *cellID = indexPathIsForBoolSetting ? BoolCellIdentifier : OtherCellIdentifier;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) 
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		
		// Add a UISwitch for the shouldOptimizeForNetworkUsage option
		if (indexPathIsForBoolSetting) 
		{
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			UISwitch *toggleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
			toggleSwitch.backgroundColor = [UIColor whiteColor];
			toggleSwitch.opaque = YES;
			toggleSwitch.on = self.assetItem.exportSession.shouldOptimizeForNetworkUse;
			[toggleSwitch addTarget:self action:@selector(updateFromSwitch:) forControlEvents:UIControlEventValueChanged];
			cell.accessoryView = toggleSwitch;
		}
		else
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
    }
	
	cell.textLabel.lineBreakMode = UILineBreakModeHeadTruncation;
	cell.imageView.image = nil;
    
    if (section == movieSection)
	{
		__unsafe_unretained __block AssetViewController *weakSelf = (AssetViewController *)self;
		cell.textLabel.text = [self.assetItem loadTitleWithCompletionHandler:^{
			UITableViewCell *thumbnailCell = [tableView cellForRowAtIndexPath:indexPath];
			thumbnailCell.textLabel.text = weakSelf.assetItem.title;
			[thumbnailCell setNeedsLayout];
		}];
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else if (section == trackSection)
	{
		cell.textLabel.text = [self.assetItem trackLabelAtIndex:row];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if (section == metadataSection)
	{
		cell.textLabel.text = [self.assetItem metadataLabelAtIndex:row];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.textLabel.textAlignment = UITextAlignmentLeft;
	}
	else if (section == settingsSection)
	{
		if (row == 0)
		{
			cell.textLabel.text = NSLocalizedString([self.assetItem preset], nil);
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		else if (row == 1)
		{
			cell.textLabel.text = @"Optimize For Network Use";
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
		}
	}
	else if (section == metadataReplaceSection)
	{
		cell.textLabel.text = @"Replace Metadata";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	else if (section == exportSection)
	{
		cell.textLabel.text = @"Export";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    
    return cell;
}

// Only allow deleting/insertion of metadata when editing
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return indexPath.section == metadataSection;
}

// When editing is finished, either delete or insert new metadata items
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
	
	// Delete metadata from the assetItem and the table view
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		[self.assetItem.metadata removeObjectAtIndex:indexPath.row];
		[[self tableView] deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

#pragma mark - Callbacks

// Respond to UISwitch changes
- (void)updateFromSwitch:(id)sender
{
	UISwitch *toggleSwitch = (UISwitch *)sender;
	self.assetItem.exportSession.shouldOptimizeForNetworkUse = toggleSwitch.on;
}

#pragma mark - NewMetadataProtocol

- (void)finishedCreatingMetadataItem:(NSArray *)newMetadataItems
{
	[self.tableView beginUpdates];
	
	[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:metadataSection] withRowAnimation:UITableViewRowAnimationAutomatic];
	self.assetItem.metadata = [newMetadataItems mutableCopy];
	[self.tableView insertSections:[NSIndexSet indexSetWithIndex:metadataSection] withRowAnimation:UITableViewRowAnimationAutomatic];
							
	[self.tableView endUpdates];
	
	[self dismissModalViewControllerAnimated:YES];
}

@end
