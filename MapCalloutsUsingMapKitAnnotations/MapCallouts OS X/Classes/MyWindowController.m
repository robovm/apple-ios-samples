/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Header file for this sample's main NSWindowController.
 */

#import "MyWindowController.h"
#import "MapViewController.h"

@interface MyWindowController ()
@property (nonatomic, strong) IBOutlet NSView *viewPlaceHolder;
@property (nonatomic, strong) MapViewController *mainVC;
@end

#pragma mark -

@implementation MyWindowController

- (void)awakeFromNib
{
    _mainVC = [[MapViewController alloc] initWithNibName:@"MainView" bundle:nil];
    [self.viewPlaceHolder addSubview:self.mainVC.view];
    
    // since we are manually adding the view hierarchy that belongs to MapViewController,
    // we need to add the proper auto layout constraints so that it shrinks and grows along
    // with our window's contentView
    //
    NSView *viewControllerView = self.mainVC.view;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(viewControllerView);
    [self.window.contentView addConstraints:[NSLayoutConstraint
                                             constraintsWithVisualFormat:@"V:|[viewControllerView]|"
                                             options:0
                                             metrics:nil
                                             views:viewsDictionary]];
    [self.window.contentView addConstraints:[NSLayoutConstraint
                                             constraintsWithVisualFormat:@"H:|[viewControllerView]|"
                                             options:0
                                             metrics:nil
                                             views:viewsDictionary]];
}

@end
