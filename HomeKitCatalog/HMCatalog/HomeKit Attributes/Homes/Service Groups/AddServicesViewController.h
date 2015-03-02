/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that provides a list of services and lets the user select services to be added to the provided Service Group.
  The services are not added to the service group until the 'Done' button is pressed.
 */

@import UIKit;
@import HomeKit;
#import "HomeKitTableViewController.h"

@interface AddServicesViewController : HomeKitTableViewController

@property (nonatomic) HMServiceGroup *serviceGroup;

@end
