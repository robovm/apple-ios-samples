/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that displays a list of characteristics within an HMService.
 */

@import UIKit;
@import HomeKit;
@protocol CharacteristicCellDelegate;
#import "HomeKitTableViewController.h"

@interface CharacteristicsViewController : HomeKitTableViewController <HMAccessoryDelegate>

@property (weak, nonatomic) id<CharacteristicCellDelegate> cellDelegate;
@property (nonatomic, strong) HMService *service;

@end
