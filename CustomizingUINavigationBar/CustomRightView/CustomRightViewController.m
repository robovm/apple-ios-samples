/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates configuring various types of controls as the right 
  bar item of the navigation bar.
 */

#import "CustomRightViewController.h"

@implementation CustomRightViewController

//| ----------------------------------------------------------------------------
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

//| ----------------------------------------------------------------------------
//! IBAction for the segemented control.
//
- (IBAction)changeRightBarItem:(UISegmentedControl*)sender
{
    if (sender.selectedSegmentIndex == 0)
    {
        // Add a custom add button as the nav bar's custom right view
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"AddTitle", @"")
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(action:)];
        self.navigationItem.rightBarButtonItem = addButton;
    }
    else if (sender.selectedSegmentIndex == 1)
    {
        // add our custom image button as the nav bar's custom right view
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Email"]
                                                                      style:UIBarButtonItemStyleBordered target:self action:@selector(action:)];
        self.navigationItem.rightBarButtonItem = addButton;
    }
    else if (sender.selectedSegmentIndex == 2)
    {
        // "Segmented" control to the right
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[
            [UIImage imageNamed:@"UpArrow"],
            [UIImage imageNamed:@"DownArrow"],
        ]];
        
        [segmentedControl addTarget:self action:@selector(action:) forControlEvents:UIControlEventValueChanged];
        segmentedControl.frame = CGRectMake(0, 0, 90, 30.0);
        segmentedControl.momentary = YES;
        
        UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
        
        self.navigationItem.rightBarButtonItem = segmentBarItem;
    }
}

#pragma mark -
#pragma mark IBActions

//| ----------------------------------------------------------------------------
//! IBAction for the various bar button items shown in this example.
//
- (IBAction)action:(id)sender
{
	NSLog(@"-[%@ %@]", [self class], NSStringFromSelector(_cmd));
}

@end
