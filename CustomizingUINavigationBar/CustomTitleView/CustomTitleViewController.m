/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates configuring the navigation bar to use a UIView
  as the title.
 */

#import "CustomTitleViewController.h"

@implementation CustomTitleViewController

//| ----------------------------------------------------------------------------
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
	NSArray *segmentTextContent = @[
        NSLocalizedString(@"Image", @""),
        NSLocalizedString(@"Text", @""),
        NSLocalizedString(@"Video", @""),
    ];
    
    // Segmented control as the custom title view
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
	segmentedControl.selectedSegmentIndex = 0;
	segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	segmentedControl.frame = CGRectMake(0, 0, 400.0f, 30.0f);
	[segmentedControl addTarget:self action:@selector(action:) forControlEvents:UIControlEventValueChanged];
	
	self.navigationItem.titleView = segmentedControl;
}


//| ----------------------------------------------------------------------------
//! IBAction for the segmented control.
//
- (IBAction)action:(id)sender
{
	NSLog(@"-[%@ %@], Selected segment is: %zi", [self class], NSStringFromSelector(_cmd), [sender selectedSegmentIndex]);
}

@end
