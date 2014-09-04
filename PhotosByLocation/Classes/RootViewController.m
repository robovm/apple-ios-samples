/*
     File: RootViewController.m 
 Abstract: n/a 
  Version: 1.2 
  
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
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
*/

#import "AssetsDataIsInaccessibleViewController.h"
#import "AssetsList.h"
#import "FavoriteAssets.h"
#import "MapViewController.h"
#import "RootViewController.h"

@interface RootViewController ()
- (void)loadGroups;
@end


@implementation RootViewController


#pragma mark -
#pragma mark View lifecycle

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryChanged:) name:ALAssetsLibraryChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(favoriteAssetsChanged:) name:kFavoriteAssetsChanged object:nil];
    
    [self loadGroups];
}

- (void)loadGroups {
    
    if (!assetsLibrary) {
        assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    if (!groups) {
        groups = [[NSMutableArray alloc] init];
    } else {
        [groups removeAllObjects];
    }
    
    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        
        if (group) {
            [groups addObject:group];
        } else {
            // Add the favorites group if it has any elements
            if (!favoriteAssets) {
                favoriteAssets = [[FavoriteAssets alloc] init];
            }
            if ([favoriteAssets count] > 0) {
                [groups addObject:favoriteAssets];
            }
            
            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        }
    };
    
    
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        AssetsDataIsInaccessibleViewController *assetsDataInaccessibleViewController = [[AssetsDataIsInaccessibleViewController alloc] initWithNibName:@"AssetsDataIsInaccessibleViewController" bundle:nil];
        
        NSString *errorMessage = nil;
        switch ([error code]) {
            case ALAssetsLibraryAccessUserDeniedError:
            case ALAssetsLibraryAccessGloballyDeniedError:
                errorMessage = @"The user has declined access to it.";
                break;
            default:
                errorMessage = @"Reason unknown.";
                break;
        }
        
        assetsDataInaccessibleViewController.explanation = errorMessage;
        [self presentViewController:assetsDataInaccessibleViewController animated:NO completion:nil];
        [assetsDataInaccessibleViewController release];
    };
    
    NSUInteger groupTypes = ALAssetsGroupAlbum | ALAssetsGroupEvent;
    [assetsLibrary enumerateGroupsWithTypes:groupTypes usingBlock:listGroupBlock failureBlock:failureBlock];
    
}


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ceil((float)groups.count / 2);
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    AssetsGroupsTableViewCell *cell = (AssetsGroupsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"AssetsGroupsTableViewCell" owner:self options:nil];
        cell = tmpCell;
        tmpCell = nil;
    }
    
    cell.rowNumber = indexPath.row;
    cell.selectionDelegate = self;
    
	// Configure the cell.
    NSUInteger leftGroupIndex = indexPath.row * 2;
    NSUInteger rightGroupIndex = leftGroupIndex + 1;
    
    ALAssetsGroup *leftGroup = [groups objectAtIndex:leftGroupIndex];
    ALAssetsGroup *rightGroup = (rightGroupIndex < groups.count) ? [groups objectAtIndex:rightGroupIndex] : nil;
    
    if (leftGroup) {
        CGImageRef posterImageRef = [leftGroup posterImage];
        UIImage *posterImage = [UIImage imageWithCGImage:posterImageRef];
        [cell setLeftPosterImage:posterImage];
        [cell setLeftLabelText:[leftGroup valueForProperty:ALAssetsGroupPropertyName]];
    }
    if (rightGroup) {
        CGImageRef posterImageRef = [rightGroup posterImage];
        UIImage *posterImage = [UIImage imageWithCGImage:posterImageRef];
        [cell setRightPosterImage:posterImage];
        [cell setRightLabelText:[rightGroup valueForProperty:ALAssetsGroupPropertyName]];
        [cell rightPosterImageView].userInteractionEnabled = YES;
    } else {
        [cell setRightLabelText:@""];
        [cell setRightPosterImage:nil];
        [cell rightPosterImageView].userInteractionEnabled = NO;
    }
    
    return cell;
}

#pragma mark -
#pragma mark AssetsGroupsTableViewCellSelectionDelegate
- (void)assetsGroupsTableViewCell:(AssetsGroupsTableViewCell *)cell selectedGroupAtIndex:(NSUInteger)index {
    
    MapViewController *mapViewController = [[MapViewController alloc] initWithNibName:@"MapViewController" bundle:nil];
    
    id objectAtRow = [groups objectAtIndex:(cell.rowNumber * 2) + index];
    AssetsList *assetsList = [objectAtRow assetsList];
    mapViewController.assetsList = assetsList;
    mapViewController.favoriteAssets = favoriteAssets;
    
    [[self navigationController] pushViewController:mapViewController animated:YES];
    [mapViewController release];
    
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewWillDisappear:(BOOL)animated {
    [groups removeAllObjects];
        
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFavoriteAssetsChanged object:nil];
    
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [assetsLibrary release];
    [groups release];
    [favoriteAssets release];

    [super dealloc];
}


#pragma mark -
#pragma mark Change Notifications handlers

- (void)assetsLibraryChanged:(NSNotification *)notification {
    [self loadGroups];
}

- (void)favoriteAssetsChanged:(NSNotification *)notification {
    [self loadGroups];
}

@end

