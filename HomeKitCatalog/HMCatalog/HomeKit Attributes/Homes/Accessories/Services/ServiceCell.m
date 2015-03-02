/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableViewCell subclass for displaying a service and the room and accessory where it resides.
 */

#import "ServiceCell.h"
#import "HMHome+Properties.h"

@implementation ServiceCell

/**
 *  Sets the name of the cell to the service name, and the detail text to a description of where that service lives in the home.
 */
- (void)setService:(HMService *)service {
    _service = service;
    // Inherit the name from the accessory if the Service doesn't have one.
    self.textLabel.text = service.name ?: service.accessory.name;
    NSString *formatString = NSLocalizedString(@"%@ in %@", @"Accessory in Room");
    NSString *accessoryName = service.accessory.name;
    NSString *roomName = service.accessory.room.name;
    self.detailTextLabel.text = [NSString stringWithFormat:formatString, accessoryName, roomName];
}

@end
