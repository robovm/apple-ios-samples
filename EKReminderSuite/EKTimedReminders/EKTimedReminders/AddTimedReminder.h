/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This view controller allows you to enter the title, priority, and alarm (time and frequency) information for a new reminder.
 
 */

#import "TimedReminder.h"

@interface AddTimedReminder : UITableViewController
// Used to pass back the user input to the AddTimedReminder view controller
@property (nonatomic, strong) TimedReminder *reminder;

@end
