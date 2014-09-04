/*
     File: FilterAttributesController.m
 Abstract: View controller for the filter attribute editor
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

#import "FilterAttributesController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreImage/CoreImage.h>
#import "CIFilter+FHAdditions.h"
#import "FilterAttributeBinding.h"
#import "SliderCell.h"

@implementation FilterAttributesController
@synthesize filter = _filter;
@synthesize screenSize;

#pragma mark - View lifecycle

- (void)_resetAction
{
    for (FilterAttributeBinding *binding in _attributeBindings)
        [binding revertToDefaultValues];
    
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // create the attribute bindings
    _attributeBindings = [[NSMutableArray alloc] init];
   
    for (NSString *key in _filter.inputKeys)
    {
        NSDictionary *attrDict = [_filter.attributes objectForKey:key];
        if ([CIFilter isAttributeConfigurable:attrDict])
        {
            FilterAttributeBinding *binding = [[FilterAttributeBinding alloc] initWithFilter:_filter
                                                                               attributeName:key
                                                                                  dictionary:attrDict
                                                                                  screenSize:self.screenSize];
            [_attributeBindings addObject:binding];
        }
    }
    
    self.title = [[_filter attributes] valueForKey:kCIAttributeFilterDisplayName] ?: _filter.name;
    
    self.tableView.rowHeight = [SliderCell cellHeight];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reset"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(_resetAction)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // each input attribute is a section in the table view
    return _attributeBindings.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section >= _attributeBindings.count)
        return 0;
    
    FilterAttributeBinding *binding = [_attributeBindings objectAtIndex:section];
    return binding.elementCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section >= _attributeBindings.count)
        return nil;
    
    FilterAttributeBinding *binding = [_attributeBindings objectAtIndex:section];
    return binding.elementCount>1 ? binding.title : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    SliderCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[SliderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    else
        [(FilterAttributeBinding *)cell.delegate unbindSliderCell:cell];
    
    FilterAttributeBinding *binding = [_attributeBindings objectAtIndex:indexPath.section];
    
    NSUInteger elementIndex = indexPath.row;
    
    [binding bindSliderCell:cell toElementIndex:elementIndex];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.delegate = binding;    
    cell.titleLabel.text = binding.elementCount>1 ? [binding elementTitleForIndex:elementIndex] : binding.title;
    cell.slider.minimumValue = binding.minElementValue;
    cell.slider.maximumValue = binding.maxElementValue;
    cell.slider.value = [binding elementValueForIndex:elementIndex];
    [cell.slider sendActionsForControlEvents:UIControlEventValueChanged];
    
    return cell;
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // disallow selection of any cell
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // disallow selection of any cell
    return;
}

@end
