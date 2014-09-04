/*
    File:       NumberPickerController.m

    Contains:   Controller that lets the user pick a number.

    Written by: DTS

    Copyright:  Copyright (c) 2010 Apple Inc. All Rights Reserved.

    Disclaimer: IMPORTANT: This Apple software is supplied to you by Apple Inc.
                ("Apple") in consideration of your agreement to the following
                terms, and your use, installation, modification or
                redistribution of this Apple software constitutes acceptance of
                these terms.  If you do not agree with these terms, please do
                not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following
                terms, and subject to these terms, Apple grants you a personal,
                non-exclusive license, under Apple's copyrights in this
                original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or
                without modifications, in source and/or binary forms; provided
                that if you redistribute the Apple Software in its entirety and
                without modifications, you must retain this notice and the
                following text and disclaimers in all such redistributions of
                the Apple Software. Neither the name, trademarks, service marks
                or logos of Apple Inc. may be used to endorse or promote
                products derived from the Apple Software without specific prior
                written permission from Apple.  Except as expressly stated in
                this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any
                patent rights that may be infringed by your derivative works or
                by other works in which the Apple Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis. 
                APPLE MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING
                WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
                MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING
                THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT,
                INCIDENTAL OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
                TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
                DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY
                OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY
                OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
                OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF
                SUCH DAMAGE.

*/

#import "NumberPickerController.h"

@interface NumberPickerController ()

@property (nonatomic, copy, readonly ) NSArray *    numbers;

@end

@implementation NumberPickerController

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self != nil) {
        self->_numbers = [[NSMutableArray alloc] initWithObjects:
            [NSNumber numberWithInt:0], 
            [NSNumber numberWithInt:1], 
            [NSNumber numberWithInt:2], 
            [NSNumber numberWithInt:3], 
            [NSNumber numberWithInt:4], 
            [NSNumber numberWithInt:5], 
            [NSNumber numberWithInt:6], 
            [NSNumber numberWithInt:7], 
            [NSNumber numberWithInt:8], 
            [NSNumber numberWithInt:9], 
            nil
        ];
        self.title = @"Number to Add";
    }
    return self;
}

- (void)dealloc
{
    [self->_numbers release];
    [super dealloc];
}

@synthesize numbers  = _numbers;
@synthesize delegate = _delegate;

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tv)
    #pragma unused(section)
    assert(tv == self.tableView);
    assert(section == 0);

    return [self.numbers count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)
    UITableViewCell *	cell;

    assert(tv == self.tableView);
    assert(indexPath != NULL);
    assert(indexPath.section == 0);
    assert(indexPath.row < [self.numbers count]);

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"] autorelease];
        assert(cell != nil);
    }
    cell.textLabel.text = [[self.numbers objectAtIndex:indexPath.row] description];

    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)

    assert(tv == self.tableView);
    assert(indexPath != NULL);
    assert(indexPath.section == 0);
    assert(indexPath.row < [self.numbers count]);

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // Tell the delegate about the selection.
    
    if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(numberPicker:didChooseNumber:)] ) {
        [self.delegate numberPicker:self didChooseNumber:[self.numbers objectAtIndex:indexPath.row]];
    }
}

- (void)cancelAction:(id)sender
{
    #pragma unused(sender)

    // Tell the delegate about the cancellation.

    if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(numberPicker:didChooseNumber:)] ) {
        [self.delegate numberPicker:self didChooseNumber:nil];
    }
}

- (void)presentModallyOn:(UIViewController *)parent
{
    UINavigationController *    nav;

    // Create a navigation controller with us as its root.
    
    nav = [[[UINavigationController alloc] initWithRootViewController:self] autorelease];
    assert(nav != nil);

    // Set up the Cancel button on the left of the navigation bar.
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)] autorelease];
    assert(self.navigationItem.leftBarButtonItem != nil);
    
    // Present the navigation controller on the specified parent 
    // view controller.
    
    [parent presentModalViewController:nav animated:YES];
}

@end
