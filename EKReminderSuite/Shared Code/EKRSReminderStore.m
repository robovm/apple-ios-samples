/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    EKRSReminderStore allows you to add, fetch, and remove upcoming, past-due, incomplete, and completed reminders
            using the EventKit framework. It checks and requests access to the Reminders application and observes changes
            using EKEventStoreChangedNotification. It also shows how to mark reminders as completed. EKRSReminderStore uses
            the default calendar for reminders.
 */

#import "EKRSConstants.h"
#import "EKRSReminderStore.h"
#import "EKRSReminderStoreUtilities.h"



@implementation EKRSReminderStore

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _completedReminders = [[NSMutableArray alloc] initWithCapacity:0];
        _pastDueReminders = [[NSMutableArray alloc] initWithCapacity:0];
        _upcomingReminders = [[NSMutableArray alloc] initWithCapacity:0];
        _locationReminders = [[NSMutableArray alloc] initWithCapacity:0];
        _eventStore = [[EKEventStore alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(storeChanged:)
                                                     name:EKEventStoreChangedNotification
                                                   object:_eventStore];
    }
    return self;
}


#pragma mark - Reminders Access Methods

// Check the authorization status of our application for Reminders
-(void)checkEventStoreAuthorizationStatus
{
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder];
    
    switch (status)
    {
        case EKAuthorizationStatusAuthorized:
            [self accessGrantedForReminders];
            break;
        case  EKAuthorizationStatusNotDetermined :
            [self requestEventStoreAccessForReminders];
            break;
        case  EKAuthorizationStatusDenied:
        case  EKAuthorizationStatusRestricted:
            [self accessDeniedForReminders];
            break;
        default:
            break;
    }
}


// Prompt the user for access to their Reminders app
-(void)requestEventStoreAccessForReminders
{
    [self.eventStore requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError *error) {
        if (granted)
        {
            [self accessGrantedForReminders];
        }
        else
        {
            [self accessDeniedForReminders];
        }
    }];
    
}


// Called when the user has granted access to Reminders
-(void)accessGrantedForReminders
{
    // EKRSReminderStore uses the default calendar for reminders
    self.calendar = self.eventStore.defaultCalendarForNewReminders;
    
    // Notifies the listener that access was granted to Reminders
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:EKRSAccessGrantedNotification object:self];
    });
}


// Called when the user has denied or restricted access to Reminders
-(void)accessDeniedForReminders
{
    // Notifies the listener that access was denied to Reminders
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:EKRSAccessDeniedNotification object:self];
    });
}



#pragma mark - Handle EKEventStoreChangedNotification

-(void)storeChanged:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:EKRSRefreshDataNotification object:self];
    });
}


#pragma mark - Filter Reminders

// Return incomplete location reminders
-(NSArray *)predicateForLocationReminders:(NSArray*)reminders
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id myobject, NSDictionary *bindings) {
        EKReminder *reminder = (EKReminder*)myobject;
        BOOL hasLocationAlarm = NO;
        
        for (EKAlarm *alarm in reminder.alarms)
        {
            if ((!reminder.completed) && (alarm.structuredLocation) && ((alarm.proximity == EKAlarmProximityLeave) || (alarm.proximity == EKAlarmProximityEnter)))
            {
                hasLocationAlarm = YES;
                break;
            }
        }
        return hasLocationAlarm;
    }];
    return [reminders filteredArrayUsingPredicate:predicate];
}


#pragma mark - Fetch Past-Due Reminders

// Fetch all past-due reminders
-(void)fetchPastDueRemindersWithDateStarting:(NSDate *)startDate
{
    // Predicate to fetch all incomplete reminders ending now in the calendar
    NSPredicate *predicate = [self.eventStore predicateForIncompleteRemindersWithDueDateStarting:startDate
                                                                                          ending:[NSDate date]
                                                                                       calendars:@[self.calendar]];
    // Fetch reminders matching the above predicate
    [self.eventStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray *reminders)
     {
         self.pastDueReminders = [NSMutableArray arrayWithArray:reminders];
         dispatch_async(dispatch_get_main_queue(), ^{
             [[NSNotificationCenter defaultCenter] postNotificationName:EKRSPastDueRemindersNotification object:self];
         });
     }];
}



#pragma mark - Fetch Upcoming Reminders

// Fetch all upcoming reminders
-(void)fetchUpcomingRemindersWithDueDate:(NSDate *)endDate
{
    // Predicate to fetch all incomplete reminders starting now and ending on endDate
    NSPredicate *predicate = [self.eventStore predicateForIncompleteRemindersWithDueDateStarting:[NSDate date]
                                                                                          ending:endDate
                                                                                       calendars:@[self.calendar]];
    // Fetch reminders matching the above predicate
    [self.eventStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray *reminders)
     {
         self.upcomingReminders = [NSMutableArray arrayWithArray:reminders];
         dispatch_async(dispatch_get_main_queue(), ^{
             [[NSNotificationCenter defaultCenter] postNotificationName:EKRSUpcomingRemindersNotification object:self];
         });
     }];
}


#pragma mark - Fetch Completed Reminders

// Fetch all completed reminders within a period
-(void)fetchCompletedRemindersWithDueDateStarting:(NSDate *)startDate ending:(NSDate *)endDate
{
    // Predicate to fetch all completed reminders falling within startDate and endDate in calendar
    NSPredicate *predicate = [self.eventStore predicateForCompletedRemindersWithCompletionDateStarting:startDate
                                                                                                ending:endDate
                                                                                             calendars:@[self.calendar]];
    // Fetch reminders matching the above predicate
    [self.eventStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray *reminders)
     {
         self.completedReminders = [NSMutableArray arrayWithArray:reminders];
         dispatch_async(dispatch_get_main_queue(), ^{
             [[NSNotificationCenter defaultCenter] postNotificationName:EKRSCompletedRemindersNotification object:self];
         });
     }];
}


#pragma mark - Fetch Location Reminders

// Fetch all reminders, then use predicateForLocationReminders: to filter the result for incomplete location-based reminders
-(void)fetchLocationReminders
{
    // Fetch all reminders available in calendar
    NSPredicate *predicate = [self.eventStore predicateForRemindersInCalendars:@[self.calendar]];
    
    [self.eventStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray *reminders)
     {
         // Filter the reminders for location ones
         self.locationReminders = (reminders.count > 0) ? [NSMutableArray arrayWithArray:[self predicateForLocationReminders:reminders]] : [NSMutableArray array];
         
         dispatch_async(dispatch_get_main_queue(), ^{
             [[NSNotificationCenter defaultCenter] postNotificationName:EKRSLocationRemindersNotification object:self];
         });
     }];
}


#pragma mark - Mark Reminder as Completed

// Use the completed property to mark a reminder as completed
-(void)complete:(EKReminder *)reminder
{
    reminder.completed = YES;
    // Update the reminder
    [self save:reminder];
}


#pragma mark - Save Reminder

// Save the reminder to the event store
-(void)save:(EKReminder *)reminder
{
    NSError *error = nil;
    if (![self.eventStore saveReminder:reminder commit:YES error:&error])
    {
        // Keep track of the error message encountered
        self.errorMessage = error.localizedDescription;
        // Notifies the listener that the operation failed
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:EKRSFailureNotification object:self];
        });
    }
    else
    {
        // Notifies the listener that the operation was successful
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:EKRSRefreshDataNotification object:self];
        });
    }
}


#pragma mark - Remove Reminder

// Remove reminder from the event store
-(void)remove:(EKReminder *)reminder
{
    NSError *error = nil;
    if (![self.eventStore removeReminder:reminder commit:YES error:&error])
    {
        self.errorMessage = error.localizedDescription;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:EKRSFailureNotification object:self];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:EKRSRefreshDataNotification object:self];
        });
    }
}


#pragma mark - Memory Management

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:EKEventStoreChangedNotification
                                                  object:nil];
}
@end
