/*
     File: CustomAccessoryViewController.m
 Abstract: The table view controller for the Custom Accessory tab.  It Manages
 a table view where each cell contains a checkbox control on the left side
 of a custom table view cell.
 
  Version: 1.4
 
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

#import "CustomAccessoryViewController.h"
#import "CustomCell.h"
#import "DetailViewController.h"

@interface CustomAccessoryViewController ()
//! Product listings from the TableData plist file.
@property (nonatomic, strong) NSMutableArray *dataArray;
@end


@implementation CustomAccessoryViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Load our data from a plist file inside our app bundle.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TableData" ofType:@"plist"];
    self.dataArray = [NSMutableArray arrayWithContentsOfFile:path];
}


//| ----------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Reload the table when we return to the screen.  The "checked" property of
    // an item may have been altered by the DetailViewController.
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark UITableViewDataSource

//| ----------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return (NSInteger)[self.dataArray count];
}


//| ----------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kCustomCellID = @"CustomCell";
	
	CustomCell *cell = (CustomCell *)[tableView dequeueReusableCellWithIdentifier:kCustomCellID];
	
	NSDictionary *item = self.dataArray[(NSUInteger)indexPath.row];
    
	cell.titleLabel.text = item[@"text"];
	cell.checkBox.checked = [item[@"checked"] boolValue];
    
    // Accessibility
    [self updateAccessibilityForCell:cell];
    
	return cell;
}

#pragma mark - 
#pragma mark UITableViewDelegate

//| ----------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Find the cell being touched and update its checked/unchecked image.
	CustomCell *targetCustomCell = (CustomCell *)[tableView cellForRowAtIndexPath:indexPath];
    targetCustomCell.checkBox.checked = !targetCustomCell.checkBox.checked;
	
	// Don't keep the table selection.
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	// Update our data source array with the new checked state.
	NSMutableDictionary *selectedItem = self.dataArray[(NSUInteger)indexPath.row];
    selectedItem[@"checked"] = @(targetCustomCell.checkBox.checked);
    
    // Accessibility
    [self updateAccessibilityForCell:targetCustomCell];
}


//| ----------------------------------------------------------------------------
//! IBAction that is called when the value of a checkbox in any row changes.
//
- (IBAction)checkBoxTapped:(id)sender forEvent:(UIEvent*)event
{
    NSSet *touches = [event allTouches];
	UITouch *touch = [touches anyObject];
	CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    
    // Lookup the index path of the cell whose checkbox was modified.
	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:currentTouchPosition];
    
	if (indexPath != nil)
	{
		// Update our data source array with the new checked state.
        NSMutableDictionary *selectedItem = self.dataArray[(NSUInteger)indexPath.row];
        selectedItem[@"checked"] = @([(Checkbox*)sender isChecked]);
	}
    
    // Accessibility
    [self updateAccessibilityForCell:(CustomCell*)[self.tableView cellForRowAtIndexPath:indexPath]];
}

//| ----------------------------------------------------------------------------
//  This will be called when the accessory button in one of the cells is tapped.
//
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"DetailViewSegue"]) {
        DetailViewController *destination = (DetailViewController*)segue.destinationViewController;
        
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForCell:sender];
        
        destination.item = self.dataArray[(NSUInteger)selectedIndexPath.row];
    }
}

#pragma mark -
#pragma mark Accessibility

//| ----------------------------------------------------------------------------
//! Utility method for configuring a cell's accessibilityValue based upon the
//! current checkbox state.
//
- (void)updateAccessibilityForCell:(CustomCell*)cell
{
    // The cell's accessibilityValue is the Checkbox's accessibilityValue.
    cell.accessibilityValue = cell.checkBox.accessibilityValue;
    
    cell.checkBox.accessibilityLabel = cell.titleLabel.text;
}

@end

