/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableViewCell subclass for displaying a service and the room and accessory where it resides.
 */

@import UIKit;
@import HomeKit;

@interface ServiceCell : UITableViewCell

@property (weak, nonatomic) HMService *service;

@end
