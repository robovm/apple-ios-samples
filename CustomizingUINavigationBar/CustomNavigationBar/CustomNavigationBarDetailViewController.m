/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The detail view controller in the Custom Navigation Bar example.
 */

#import "CustomNavigationBarDetailViewController.h"

@interface CustomNavigationBarDetailViewController ()
@property (nonatomic, weak) IBOutlet UILabel *cityLabel;
@end


@implementation CustomNavigationBarDetailViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cityLabel.text = self.city;
}

@end
