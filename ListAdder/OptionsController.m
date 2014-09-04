/*
    File:       OptionsController.m

    Contains:   Controller to set various debugging options.

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

#import "OptionsController.h"

#include <AssertMacros.h>

@interface OptionsController ()

@property (nonatomic, retain, readonly ) NSMutableDictionary * currentState;
@end

@implementation OptionsController

static NSString * kOptionLabels[] = { @"Retain, Not Copy", @"Allow Stale", @"Use Threads Directly", @"Apply Results From Thread" };
static NSString *   kOptionKeys[] = { @"retainNotCopy",    @"allowStale",  @"useThreadsDirectly",   @"applyResultsFromThread"    };

enum {
    kOptionCount = sizeof(kOptionLabels) / sizeof(*kOptionLabels)
};
check_compile_time( kOptionCount == (sizeof(kOptionKeys) / sizeof(*kOptionKeys)) );

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self != nil) {
        NSUserDefaults *    defaults;
        NSUInteger          optionIndex;
        
        self->_currentState = [[NSMutableDictionary alloc] init];
        assert(self->_currentState != nil);
        
        defaults = [NSUserDefaults standardUserDefaults];
        assert(defaults != nil);

        for (optionIndex = 0; optionIndex < kOptionCount; optionIndex++) {
            [self->_currentState setObject:[NSNumber numberWithBool:[defaults boolForKey:kOptionKeys[optionIndex]]] forKey:kOptionKeys[optionIndex]];
        }

        self.title = @"Options";
    }
    return self;
}

- (void)dealloc
{
    [self->_currentState release];
    [super dealloc];
}

@synthesize currentState = _currentState;
@synthesize delegate     = _delegate;

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)section
{
    #pragma unused(tv)
    #pragma unused(section)
    assert(tv == self.tableView);
    assert(section == 0);
    return @
    "These options enable code that does not work properly. "
    "If you enable any options, the application is likely to crash or misbehave. "
    "The goal here is to illustrate TN2109's examples of how NOT to write threaded code; "
    "these options let you see the resulting problems in action."
    ;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tv)
    #pragma unused(section)
    assert(tv == self.tableView);
    assert(section == 0);

    return kOptionCount;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)
    UITableViewCell *	cell;

    assert(tv == self.tableView);
    assert(indexPath != NULL);
    assert(indexPath.section == 0);
    assert(indexPath.row < kOptionCount);

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"] autorelease];
        assert(cell != nil);
    }
    cell.textLabel.text = kOptionLabels[indexPath.row];
    cell.accessoryType  = [[self.currentState objectForKey:kOptionKeys[indexPath.row]] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    return cell;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tv)
    #pragma unused(indexPath)
    UITableViewCell *   cell;
    NSString *          key;
    BOOL                newValue;

    assert(tv == self.tableView);
    assert(indexPath != NULL);
    assert(indexPath.section == 0);
    assert(indexPath.row < kOptionCount);

    key = kOptionKeys[indexPath.row];
    newValue = ! [[self.currentState objectForKey:kOptionKeys[indexPath.row]] boolValue];
    [self.currentState setObject:[NSNumber numberWithBool:newValue] forKey:key];
    cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell != nil) {
        cell.accessoryType  = newValue ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)saveAction:(id)sender
{
    #pragma unused(sender)
    NSUserDefaults *    defaults;

    // Commit the options to the user defaults.
    
    defaults = [NSUserDefaults standardUserDefaults];
    assert(defaults != nil);
    
    for (NSString * key in self.currentState) {
        [defaults setObject:[self.currentState objectForKey:key] forKey:key];
    }

    [defaults synchronize];
    
    // Tell the delegate about the save.

    if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(didSaveOptions:)] ) {
        [self.delegate didSaveOptions:self];
    }
}

- (void)cancelAction:(id)sender
{
    #pragma unused(sender)

    // Tell the delegate about the cancellation.

    if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(didCancelOptions:)] ) {
        [self.delegate didCancelOptions:self];
    }
}

- (void)presentModallyOn:(UIViewController *)parent
{
    UINavigationController *    nav;

    // Create a navigation controller with us as its root.
    
    nav = [[[UINavigationController alloc] initWithRootViewController:self] autorelease];
    assert(nav != nil);

    // Set up the Cancel button on the left of the navigation bar.
    
    self.navigationItem.leftBarButtonItem  = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)] autorelease];
    assert(self.navigationItem.leftBarButtonItem != nil);
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave   target:self action:@selector(saveAction:)] autorelease];
    assert(self.navigationItem.rightBarButtonItem != nil);
    
    // Present the navigation controller on the specified parent 
    // view controller.
    
    [parent presentModalViewController:nav animated:YES];
}

@end
