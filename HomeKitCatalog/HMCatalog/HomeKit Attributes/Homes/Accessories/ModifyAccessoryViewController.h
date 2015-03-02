/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that allows for renaming, reassigning, and identifying accessories before and after they've been added to a home.
 */

@import UIKit;
@import HomeKit;
#import "HomeKitTableViewController.h"

@class ModifyAccessoryViewController;
@protocol ModifyAccessoryDelegate <NSObject>

- (void)accessoryViewController:(ModifyAccessoryViewController *)viewController didSaveAccessory:(HMAccessory *)accessory;

@end

@interface ModifyAccessoryViewController : HomeKitTableViewController

@property (nonatomic) HMAccessory *accessory;
@property (nonatomic) id<ModifyAccessoryDelegate> delegate;

@end
