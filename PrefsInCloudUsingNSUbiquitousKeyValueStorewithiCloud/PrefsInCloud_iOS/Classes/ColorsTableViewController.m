/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The modal table view controller used to pick a preferred background color.
 */

#import "ColorsTableViewController.h"

@implementation ColorsTableViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // check mark the current background color
    assert(self.selectedColor != nil);
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.selectedColor];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.colors.count;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.textColor = [UIColor grayColor];
    header.textLabel.font = [UIFont boldSystemFontOfSize:12];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Available Background Colors:", @"");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    cell.textLabel.text = self.colors[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // clean out the old checkmark state
    for (NSUInteger row = 0; row < self.colors.count; row++)
    {
        NSIndexPath *rowIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [tableView cellForRowAtIndexPath:rowIndexPath].accessoryType = UITableViewCellAccessoryNone;
    }
    
    // apply the new checkmark state
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    _selectedColor = indexPath;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

