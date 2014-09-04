/*
     File: CustomRightViewController.m
 Abstract: Demonstrates configuring various types of controls as the right 
 bar item of the navigation bar.
 
  Version: 1.12
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
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
