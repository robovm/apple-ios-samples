/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A generic View Controller for displaying a list of homes in a home manager.
 */

@import UIKit;
@import HomeKit;
#import "HomeKitTableViewController.h"

@interface HomeListViewController : HomeKitTableViewController <HMHomeManagerDelegate>

@property (nonatomic, readonly) HMHomeManager *homeManager;

@end
