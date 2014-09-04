/*
     File: MainViewController.m 
 Abstract: View controller for the interface.  Manages the filtered image view and list of filters. 
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

#import "MainViewController.h"

@implementation MainViewController

@synthesize filtersToApply = _filtersToApply;
@synthesize imageView = _imageView;
@synthesize tableView = _tableView;

//
// Action sent by the right navigation bar item.
// Removes all applied filters and updates the display.
- (IBAction)clearFilters:(id)sender
{
    [_filtersToApply removeAllObjects];
    
    // Instruct the filtered image view to refresh
    [_imageView reloadData];
    // Instruct the table to refresh.  This will remove
    // any checkmarks next to selected filters.
    [_tableView reloadData];
}

//
// Private method to add a filter given it's name.
// Creates a new instance of the named filter and adds
// it to the list of filters to be applied, then
// updates the display.
- (void)addFilter:(NSString*)name
{
    // Create a new filter with the given name.
    CIFilter *newFilter = [CIFilter filterWithName:name];
    // A nil value implies the filter is not available.
    if (!newFilter) return;
    
    // -setDefaults instructs the filter to configure its parameters
    // with their specified default values.
    [newFilter setDefaults];
    // Our filter configuration method will attempt to configure the
    // filter with random values.
    [MainViewController configureFilter:newFilter];
    
    [_filtersToApply addObject:newFilter];
    
    // Instruct the filtered image view to refresh
    [_imageView reloadData];
}

//
// Private method to add a filter given it's name.
// Updates the display when finished.
- (void)removeFilter:(NSString*)name
{
    NSUInteger filterIndex = NSNotFound;
    
    // Find the index named filter in the array.
    for (CIFilter *filter in _filtersToApply)
        if ([filter.name isEqualToString:name])
            filterIndex = [_filtersToApply indexOfObject:filter];
    
    // If it was found (which it always should be) remove it.
    if (filterIndex != NSNotFound)
        [_filtersToApply removeObjectAtIndex:filterIndex];
    
    // Instruct the filtered image view to refresh
    [_imageView reloadData];
}

#pragma mark - TableView

// Standard table view datasource/delegate code.
//
// Create a table view displaying all the filters named in the _availableFilters array.
// Only the names of the filters a stored in the _availableFilters array, the actual filter 
// is created on demand when the user chooses to add it to the list of applied filters.
//

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_availableFilters count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *filterCellID = @"filterCell";
    
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:filterCellID];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:filterCellID];
        
    cell.textLabel.text = [_availableFilters objectAtIndex:indexPath.row];
    
    // Check if the filter named in this row is currently applied to the image.  If it is,
    // give this row a checkmark.
    cell.accessoryType = UITableViewCellAccessoryNone;
    for (CIFilter *filter in _filtersToApply)
        if ([[filter name] isEqualToString:[_availableFilters objectAtIndex:indexPath.row]])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Select a Filter";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    // Determine if the filter is or is not currently applied.
    BOOL filterIsCurrentlyApplied = NO;
    for (CIFilter *filter in _filtersToApply)
        if ([[filter name] isEqualToString:selectedCell.textLabel.text])
            filterIsCurrentlyApplied = YES;
    
    // If the filter is currently being applied, remove it.
    if (filterIsCurrentlyApplied) {
        [self removeFilter:[_availableFilters objectAtIndex:indexPath.row]];
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
    } 
    // Otherwise, add it.
    else {
        [self addFilter:[_availableFilters objectAtIndex:indexPath.row]];
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    }
        
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    _filtersToApply = [[NSMutableArray alloc] init];
    
    _imageView.inputImage = [UIImage imageNamed:@"LakeDonPedro2.jpg"];
    
}

- (void)awakeFromNib
{
    _availableFilters = [NSArray arrayWithObjects:@"CIColorInvert", @"CIColorControls", @"CIGammaAdjust", @"CIHueAdjust", nil];
}

@end
