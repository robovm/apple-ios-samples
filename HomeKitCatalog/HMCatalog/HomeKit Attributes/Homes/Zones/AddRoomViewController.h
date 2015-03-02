/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that lists rooms within a home and allows the user to add the rooms to a provided zone.
 */

@import UIKit;
@import HomeKit;
#import "HomeKitTableViewController.h"

@interface AddRoomViewController : HomeKitTableViewController

/**
 *  The zone to which to add the rooms.
 */
@property (nonatomic) HMZone *zone;

@end
