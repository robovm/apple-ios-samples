/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 An EKRSReminderStore subclass that shows how to create location-based reminders using EKReminder and EKAlarm.
 
 */

#import "EKRSReminderStore.h"
#import "LocationReminder.h"

@interface LocationReminderStore : EKRSReminderStore
+(LocationReminderStore *)sharedInstance;
-(void)createLocationReminder:(LocationReminder *)reminder;

@end
