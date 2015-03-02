/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that allows the user to add services to a service group.
 */

@import UIKit;
@import HomeKit;
#import "HomeKitTableViewController.h"

@interface ServiceGroupViewController : HomeKitTableViewController

@property (nonatomic) HMServiceGroup *serviceGroup;

@end
