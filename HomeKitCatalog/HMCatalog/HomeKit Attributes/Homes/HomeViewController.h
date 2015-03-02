/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that displays all elements within a home.
  It contains separate sections for Accessories, Rooms, Zones, Action Sets,
  Timer Triggers, and Service Groups.
 */

@import UIKit;
#import "NSError+HomeKit.h"
#import "RoomViewController.h"

/**
 *  @class HomeViewController
 *  @discussion HomeViewController manages every top-level aspect of home management.
 *  It's where you add new rooms, zones, users, action sets, and triggers.
 */
@interface HomeViewController : HomeKitTableViewController

@end
