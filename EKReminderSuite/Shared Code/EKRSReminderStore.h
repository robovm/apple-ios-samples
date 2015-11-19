/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 EKRSReminderStore allows you to add, fetch, and remove upcoming, past-due, incomplete, and completed reminders
         using the EventKit framework. It checks and requests access to the Reminders application and observes changes
         using EKEventStoreChangedNotification. It also shows how to mark reminders as completed. EKRSReminderStore uses
         the default calendar for reminders.
 
 */

@interface EKRSReminderStore : NSObject
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) EKCalendar *calendar;
// Specifies the type of calendar being created
@property (nonatomic, copy) NSString *calendarName;

// Error encountered while saving or removing a reminder
@property (nonatomic, copy) NSString *errorMessage;

// Keep track of all past-due reminders
@property (nonatomic, strong) NSMutableArray *pastDueReminders;
// Keep track of all upcoming reminders
@property (nonatomic, strong) NSMutableArray *upcomingReminders;
// Keep track of all completed reminders
@property (nonatomic, strong) NSMutableArray *completedReminders;
// Keep track of location reminders
@property (nonatomic, strong) NSMutableArray *locationReminders;

// Check whether application has access to the Reminders application
-(void)checkEventStoreAuthorizationStatus;

// Save reminder
-(void)save:(EKReminder *)reminder;
// Delete reminder
-(void)remove:(EKReminder *)reminder;
// Mark reminder as completed
-(void)complete:(EKReminder *)reminder;

// Fetch all location reminders
-(void)fetchLocationReminders;
// Fetch all incomplete reminders starting now and ending later
-(void)fetchUpcomingRemindersWithDueDate:(NSDate *)endDate;
// Fetch all incomplete reminders ending now
-(void)fetchPastDueRemindersWithDateStarting:(NSDate *)startDate;
// Fetch all completed reminders, which start and end within a given period
-(void)fetchCompletedRemindersWithDueDateStarting:(NSDate *)startDate ending:(NSDate *)endDate;

@end
