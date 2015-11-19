/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 An EKRSReminderStore subclass that shows how to create recurring timed-based reminders using EKReminder,
         EKAlarm, and EKRecurrenceRule.
 
 */

#import "TimedReminder.h"
#import "EKRSReminderStore.h"

@interface TimedReminderStore : EKRSReminderStore
+(TimedReminderStore *)sharedInstance;
-(void)createTimedReminder:(TimedReminder *)reminder;

@end

