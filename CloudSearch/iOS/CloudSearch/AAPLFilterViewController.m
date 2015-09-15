/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Table view for choosing the file extension to filter.
 */

#import "AAPLFilterViewController.h"

@interface AAPLFilterViewController ()

@property (nonatomic, strong) NSArray *filterItems;

@end


#pragma mark -

@implementation AAPLFilterViewController

//----------------------------------------------------------------------------------------
// viewDidLoad
//----------------------------------------------------------------------------------------
- (void)viewDidLoad
{
	[super viewDidLoad];
    
    _filterItems = @[@"TEXT", @"JPEG", @"PDF", @"HTML", @"None"];
    
    // filter by 'txt' by default
    if (self.extensionToFilter == nil)
    {
        // client has not asked for an extension to filter by
        _extensionToFilter = [NSIndexPath indexPathForRow:0 inSection:0];
    }
}

//----------------------------------------------------------------------------------------
// doneAction:sender
//----------------------------------------------------------------------------------------
- (IBAction)doneAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        
        // call our delegate to filter by chosen extension
        [self.filterDelegate filterViewController:self didSelectExtension:self.extensionToFilter];
    }];
}


#pragma mark - UITableViewDataSource

//----------------------------------------------------------------------------------------
// numberOfRowsInSection:section
//----------------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filterItems.count;
}

//----------------------------------------------------------------------------------------
// cellForRowAtIndexPath:indexPath
//----------------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    cell.textLabel.text = self.filterItems[indexPath.row];
    if (self.extensionToFilter.row == indexPath.row)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}


#pragma mark - UITableViewDelegate

//----------------------------------------------------------------------------------------
// didSelectRowAtIndexPath:indexPath
//----------------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // uncheck the previous cell
    UITableViewCell *previouslySelectedCell = [tableView cellForRowAtIndexPath:self.extensionToFilter];
    previouslySelectedCell.accessoryType = UITableViewCellAccessoryNone;
    
    // check the new cell
    _extensionToFilter = indexPath;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
