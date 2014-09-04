/*
     File: AccessoryViewController.m
 Abstract: The table view controller for the Accessory View tab.  It Manages
 a table view where each cell contains a checkbox control in the 
 accessoryView.
 
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

#import "AccessoryViewController.h"
#import "Checkbox.h"

@interface AccessoryViewController ()
//! Product listings from the TableData plist file.
@property (nonatomic, strong) NSMutableArray *dataArray;
@end


@implementation AccessoryViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // load our data from a plist file inside our app bundle
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TableData" ofType:@"plist"];
    self.dataArray = [NSMutableArray arrayWithContentsOfFile:path];
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
	static NSString *kStandardCellID = @"StandardCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kStandardCellID];
    
    if (cell.accessoryView == nil) {
        // Only configure the Checkbox control once.
        cell.accessoryView = [[Checkbox alloc] initWithFrame:CGRectMake(0, 0, 25, 43)];
        cell.accessoryView.opaque = NO;
        cell.backgroundColor = [UIColor clearColor];
        
        [(Checkbox*)cell.accessoryView addTarget:self action:@selector(checkBoxTapped:forEvent:) forControlEvents:UIControlEventValueChanged];
    }
    
	NSDictionary *item = self.dataArray[(NSUInteger)indexPath.row];
    
	cell.textLabel.text = [item objectForKey:@"text"];
    [(Checkbox*)cell.accessoryView setChecked: [item[@"checked"] boolValue] ];
    
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
	UITableViewCell *targetCell = [tableView cellForRowAtIndexPath:indexPath];
    Checkbox *targetCheckbox = (Checkbox*)[targetCell accessoryView];
    targetCheckbox.checked = !targetCheckbox.checked;
    
    // Don't keep the table selection.
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Update our data source array with the new checked state.
	NSMutableDictionary *selectedItem = self.dataArray[(NSUInteger)indexPath.row];
    selectedItem[@"checked"] = @(targetCheckbox.checked);
    
    // Accessibility
    [self updateAccessibilityForCell:targetCell];
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
    
	if (indexPath != nil) {
        // Update our data source array with the new checked state.
        NSMutableDictionary *selectedItem = self.dataArray[(NSUInteger)indexPath.row];
        selectedItem[@"checked"] = @([(Checkbox*)sender isChecked]);
    }
    
    // Accessibility
    [self updateAccessibilityForCell:[self.tableView cellForRowAtIndexPath:indexPath]];
}


//| ----------------------------------------------------------------------------
//  Because a custom accessory view is used, this method is never invoked by
//  the table view.  If one of the standard UITableViewCellAccessoryTypes were
//  used instead, the table view would invoke this method in response to a tap
//  on the accessory.
//
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark -
#pragma mark Accessibility

//| ----------------------------------------------------------------------------
//! Utility method for configuring a cell's accessibilityValue based upon the
//! current checkbox state.
//
- (void)updateAccessibilityForCell:(UITableViewCell*)cell
{
    // The cell's accessibilityValue is the Checkbox's accessibilityValue.
    cell.accessibilityValue = cell.accessoryView.accessibilityValue;
}

@end

