/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This view controller manages the child view controllers: CompletedReminders, PastDueReminders and UpcomingReminders.
         It calls TimedReminderStore to check access to the Reminders application. It listens and handles TimedReminderStore notifications.
         It calls TimedReminderStore to fetch upcoming, past-due, and completed reminders. It notifies the UpcomingReminders, PastDueReminders,
         and CompletedReminders view controllers upon receiving their associated data.
 
 */

@interface TimedTabBarController : UITabBarController
@end