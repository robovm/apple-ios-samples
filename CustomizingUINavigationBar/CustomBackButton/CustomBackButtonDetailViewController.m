/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The detail view controller in the Custom Back Button example.
 */

#import "CustomBackButtonDetailViewController.h"

@interface CustomBackButtonDetailViewController ()
@property (nonatomic, weak) IBOutlet UILabel *cityLabel;
@end


@implementation CustomBackButtonDetailViewController

//| ----------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cityLabel.text = self.city;
}

@end
