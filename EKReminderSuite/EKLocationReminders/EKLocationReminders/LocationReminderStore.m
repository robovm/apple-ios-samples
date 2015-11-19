/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An EKRSReminderStore subclass that shows how to create location-based reminders using EKReminder and EKAlarm.
 */

#import "LocationReminderStore.h"
#import "EKRSReminderStoreUtilities.h"

@implementation LocationReminderStore

+(LocationReminderStore *)sharedInstance
{
    static dispatch_once_t onceToken;
    static LocationReminderStore * locationReminderStoreSharedInstance;
    
    dispatch_once(&onceToken, ^{
        locationReminderStoreSharedInstance = [[LocationReminderStore alloc] init];
    });
    return locationReminderStoreSharedInstance;
}


#pragma mark -
#pragma mark Add Location Reminder

// Create a location-based reminder
-(void)createLocationReminder:(LocationReminder *)reminder
{
    EKReminder *myReminder = [EKReminder reminderWithEventStore:self.eventStore];
    myReminder.title = reminder.title;
    myReminder.calendar = self.calendar;
    
    // Create an alarm
    EKAlarm *alarm = [[EKAlarm alloc] init];
    // Configure a geofence by setting up the structured location and proximity properties
    alarm.proximity = [alarm proximityMatchingName:reminder.proximity];
    alarm.structuredLocation = reminder.structuredLocation;
    
    // Add the above alarm to myReminder
    [myReminder addAlarm:alarm];
    
    // Attempt to save the reminder
    [self save:myReminder];
}

@end