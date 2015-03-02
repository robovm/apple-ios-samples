/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that lists the accessories within a room.
 */

@import UIKit;
@import HomeKit;
#import "HomeKitTableViewController.h"

@interface RoomViewController : HomeKitTableViewController

@property (nonatomic) HMRoom *room;

@end
