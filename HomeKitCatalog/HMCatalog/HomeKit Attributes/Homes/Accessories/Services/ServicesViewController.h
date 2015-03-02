/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller which displays all the services of a provided accessory, and passes its cell delegate onto a CharacteristicsViewController.
 */

@import UIKit;
@import HomeKit;
#import "HomeKitTableViewController.h"

#import "CharacteristicCell.h"

@interface ServicesViewController : HomeKitTableViewController

@property (nonatomic) id<CharacteristicCellDelegate> cellDelegate;
@property (nonatomic) HMAccessory *accessory;

@end
