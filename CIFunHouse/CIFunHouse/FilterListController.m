/*
     File: FilterListController.m
 Abstract: The view controller of the active filter list table view
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "FilterListController.h"
#import "CIFilter+FHAdditions.h"
#import "FilterAttributesController.h"

@implementation FilterListController
@synthesize delegate = _delegate;
@synthesize filterStack = _filterStack;
@synthesize addFilterPopoverController = _addFilterPopoverController;
@synthesize addFilterNavigationController = _addFilterNavigationController;

@synthesize screenSize;

#pragma mark - View lifecycle

- (void)_dismissAction
{
    [self.delegate filterListEditorDidDismiss];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    AddFilterController *addFilterController = [[AddFilterController alloc] initWithStyle:UITableViewStylePlain];
    addFilterController.filterStack = _filterStack;
    addFilterController.delegate = self;
    addFilterController.contentSizeForViewInPopover = CGSizeMake(480.0, 320.0);
    self.addFilterNavigationController = [[UINavigationController alloc] initWithRootViewController:addFilterController];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        self.addFilterPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.addFilterNavigationController];

    
    _addFilterButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                         target:self
                                                                         action:@selector(addAction)];
    self.navigationItem.leftBarButtonItem = _addFilterButtonItem;
    
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone))
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(_dismissAction)];
    else
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.title = @"Filters";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // enable "Edit" button if there is one or more item in this list
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad))
        self.navigationItem.rightBarButtonItem.enabled = (_filterStack.activeFilters.count > 0);
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _filterStack.activeFilters.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    CIFilter *filter = [_filterStack.activeFilters objectAtIndex:indexPath.row];
    
    NSString *displayName = [[filter attributes] valueForKey:kCIAttributeFilterDisplayName];
    cell.textLabel.text = displayName;
    cell.detailTextLabel.text = [filter isSourceFilter] ? nil : [filter name];
    
    if ([filter onlyRequiresInputImages])
        cell.accessoryType = UITableViewCellAccessoryNone;
    else
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.showsReorderControl = NO;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // might be nice to have a yellow background color for the cell
    // if the item is not in use in the graph.
    // For example if the stack just contains two images.
    // The logic for this is a bit tricky though so it is left as an exercise.
    
//    CIFilter *filter = [_filterStack.activeFilters objectAtIndex:indexPath.row];
//    if (filter.isUnused)
//        cell.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.75 alpha:1.0];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Only allow the last filter to be edited
    return (indexPath.row == _filterStack.activeFilters.count - 1);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [_filterStack removeLastFilter]; // only the last filter is deletable
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        if (self.editing && _filterStack.activeFilters.count == 0)
        {
            self.editing = NO;
            self.editButtonItem.enabled = NO;
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CIFilter *filter = [_filterStack.activeFilters objectAtIndex:indexPath.row];
    
    if ([filter onlyRequiresInputImages])
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    FilterAttributesController *controller = [[FilterAttributesController alloc] initWithStyle:UITableViewStyleGrouped];
    controller.filter = filter;
    controller.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
    controller.screenSize = self.screenSize;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Private methods

- (void)addAction
{
    AddFilterController *controller = [[AddFilterController alloc] initWithStyle:UITableViewStylePlain];
    controller.filterStack = self.filterStack;
    controller.delegate = self;
    controller.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                withAnimation:UIStatusBarAnimationSlide];
        
        [self presentViewController:_addFilterNavigationController animated:YES completion:nil];
    }
    else
    {
        [_addFilterPopoverController presentPopoverFromBarButtonItem:_addFilterButtonItem
                                            permittedArrowDirections:UIPopoverArrowDirectionUp
                                                            animated:YES];
    }
}


#pragma mark - AddFilterController delegate method

- (void) didAddFilter:(CIFilter *)filter
{
    [self.tableView reloadData];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [_addFilterNavigationController dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        if ([_addFilterPopoverController isPopoverVisible])
            [_addFilterPopoverController dismissPopoverAnimated:YES];
    }
}

@end
