/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 An object that responds to CharacteristicCell updates and notifies HomeKit of changes.
 */

@import HomeKit;
#import "CharacteristicCell.h"

@interface AccessoryUpdateController : NSObject <CharacteristicCellDelegate>

@end
