/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The detail view controller used for displaying the Golden Gate Bridge either in a popover for iPad, or in a pushed view controller for iPhone.
 */

#import "DetailViewController.h"

@implementation DetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // fit the our popover size to match our image size
    UIImageView *imageView = (UIImageView *)self.view;
    
    // this will determine the appropriate size of our popover
    self.preferredContentSize = CGSizeMake(imageView.image.size.width, imageView.image.size.height);
    self.title = @"Golden Gate";
}

@end
