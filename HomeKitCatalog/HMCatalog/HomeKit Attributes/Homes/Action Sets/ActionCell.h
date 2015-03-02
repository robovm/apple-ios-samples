/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableViewCell subclass that displays a characteristic's 'target value'.
 */

@import UIKit;
@import HomeKit;

@interface ActionCell : UITableViewCell

- (void)setCharacteristic:(HMCharacteristic *)characteristic targetValue:(id)value;

@end
