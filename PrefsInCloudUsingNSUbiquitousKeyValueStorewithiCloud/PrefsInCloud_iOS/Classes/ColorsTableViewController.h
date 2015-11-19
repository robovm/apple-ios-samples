/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The modal table view controller used to pick a preferred background color.
 */

#import <UIKit/UIKit.h>

@interface ColorsTableViewController : UITableViewController

@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) NSIndexPath *selectedColor;

@end
