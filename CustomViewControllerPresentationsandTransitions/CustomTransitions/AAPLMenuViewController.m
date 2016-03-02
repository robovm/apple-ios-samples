/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Displays the list of examples.
 */

#import "AAPLMenuViewController.h"

@implementation AAPLMenuViewController

//| ----------------------------------------------------------------------------
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // Certain examples are only supported on iOS 8 and later.
    if ([UIDevice currentDevice].systemVersion.floatValue < 8.f)
    {
        NSArray *iOS7Examples = @[@"CrossDissolve", @"Dynamics", @"Swipe", @"Checkerboard", @"Slide"];
        
        if ([iOS7Examples containsObject:identifier] == NO) {
            [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can not load example." message:@"This example requires iOS 8 or later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
            return NO;
        }
    }
    
    return YES;
}


//| ----------------------------------------------------------------------------
- (IBAction)unwindToMenuViewController:(UIStoryboardSegue*)sender
{ }

@end
