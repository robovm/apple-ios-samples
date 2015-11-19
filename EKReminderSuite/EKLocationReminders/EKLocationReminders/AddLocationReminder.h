/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This view controller allows you to enter the title, proximity, and geofence's radius for a new location-based reminder.
 
 */

#import "LocationReminder.h"

@interface AddLocationReminder : UITableViewController
@property (nonatomic, strong) LocationReminder *reminder;
// Location's name
@property (nonatomic, copy) NSString *name;
// Location's address
@property (nonatomic, copy) NSString *address;
// Used to pass back the user input to the Map view controller
@property (nonatomic, strong) NSDictionary *userInput;

@end