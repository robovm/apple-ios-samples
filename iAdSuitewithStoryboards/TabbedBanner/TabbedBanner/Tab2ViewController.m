/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
View controller for tab 2.
*/

#import "Tab2ViewController.h"

@implementation Tab2ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSDictionary *ipsums = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"ipsums" withExtension:@"plist"]];
    self.text = ipsums[@"Meaty"];
}

@end
