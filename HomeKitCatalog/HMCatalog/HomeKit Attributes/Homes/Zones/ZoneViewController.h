/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that lists the roms within a provided zone.
 */

@import UIKit;
@import HomeKit;
#import "HomeKitTableViewController.h"

/**
 *  @class ZoneViewController
 *  @discussion ZoneViewController allows you to add rooms to and show rooms associated with a given HMZone.
 */
@interface ZoneViewController : HomeKitTableViewController

/**
 *  The home to which this zone is associated.
 */
@property (nonatomic) HMZone *zone;

@end
