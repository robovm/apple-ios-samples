/*
     File: RootViewController.m
 Abstract: Table view controller that manages displaying the video assets.
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


#import <AssetsLibrary/ALAssetsLibrary.h>

#import "RootViewController.h"
#import "AssetViewController.h"
#import "AssetItem.h"

@interface RootViewController ()

@property(readonly, strong) VideoLibrary *videoLibrary;

@end

@implementation RootViewController

@synthesize videoLibrary = _videoLibrary;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		__unsafe_unretained __block RootViewController *weakSelf = (RootViewController *)self;
		_videoLibrary = [[VideoLibrary alloc] initWithLibraryChangedHandler:^{
			[weakSelf.tableView reloadData];
		}];
	}
	
	return self;
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)viewDidLoad
{
	self.title = @"AVMovieExporter";
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
	__unsafe_unretained __block RootViewController *weakSelf = (RootViewController *)self;
	[self.videoLibrary loadLibraryWithCompletionBlock:^{
		[weakSelf.tableView reloadData];
	}];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	AssetItem *assetItem = nil;
	NSInteger row = indexPath.row;
	
	assetItem = [self.videoLibrary.assetItems objectAtIndex:row];
	[assetItem resetExport];
	
	// Load the asset when it is tapped on
	AssetViewController *assetViewController = [[AssetViewController alloc] initWithStyle:UITableViewStyleGrouped];
	assetViewController.assetItem = assetItem;
	[self.navigationController pushViewController:assetViewController animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.videoLibrary.assetItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	AssetItem *asset = nil;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	
	asset = [self.videoLibrary.assetItems objectAtIndex:indexPath.row];
	
	// Set and load the movie title if available
	cell.textLabel.text = [asset loadTitleWithCompletionHandler:^{
		UITableViewCell *thumbnailCell = [tableView cellForRowAtIndexPath:indexPath];
		thumbnailCell.textLabel.text = asset.title;
		[thumbnailCell setNeedsLayout];
	}];
	
	// Set and load the movie thumbnail if available
	cell.imageView.image = [asset loadThumbnailWithCompletionHandler:^{
		UITableViewCell *thumbnailCell = [tableView cellForRowAtIndexPath:indexPath];
		thumbnailCell.imageView.image = asset.thumbnail;
		[thumbnailCell setNeedsLayout];
	}];
	
	return cell;
}

@end
