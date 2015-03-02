/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
 Test view controller parent for implementing test pages in the test application.
  
 */


#import "AAPLBasicTestViewController.h"
#import "AAPLTest.h"

@interface AAPLBasicTestViewController ()

@end

@implementation AAPLBasicTestViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    return self;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tests count];
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"SELECT_TEST", nil);
}

- (AAPLTest*)testForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section > 0 || indexPath.row >= self.tests.count) {
        return nil;
    }
    
    return [self.tests objectAtIndex:indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"tableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    AAPLTest *test = [self testForIndexPath:indexPath];
    cell.textLabel.text = test.name;
    cell.detailTextLabel.text = test.details;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AAPLTest *test = [self testForIndexPath:indexPath];
    
    // invoke the selector with the selected test
    [self performSelector:test.method withObject:nil afterDelay:0.0f];
    [tableView deselectRowAtIndexPath:indexPath animated:YES ];
}

- (void)printResult:(UITextView*)textView message:(NSString*)msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // update the result in the main queue because we may be calling from asynchronous block
        textView.text = [textView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n",msg]];
        [textView scrollRangeToVisible:NSMakeRange([textView.text length], 0)];
    });
}

@end
