/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The presented view controller for the Cross Dissolve demo.
 */

#import "AAPLCrossDissolveSecondViewController.h"

@implementation AAPLCrossDissolveSecondViewController

//| ----------------------------------------------------------------------------
- (IBAction)dismissAction:(id)sender
{
    // For the sake of example, this demo implements the presentation and
    // dismissal logic completely in code.  Take a look at the later demos
    // to learn how to integrate custom transitions with segues.
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
