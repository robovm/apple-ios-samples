/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Demonstrates displaying text above the navigation bar.
 */

#import "NavigationPromptViewController.h"

@implementation NavigationPromptViewController

//| ----------------------------------------------------------------------------
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


//| ----------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
    // There is a bug in iOS 7.x (fixed in iOS 8) which causes the
    // topLayoutGuide to not be properly resized if the prompt is set before
    // -viewDidAppear: is called. This may result in the navigation bar
    // improperly overlapping your content.  For this reason, you should avoid
    // configuring the prompt in your storyboard and instead configure it
    // programmatically in -viewDidAppear:.
    self.navigationItem.prompt = @"Navigation prompts appear at the top.";
}

@end
