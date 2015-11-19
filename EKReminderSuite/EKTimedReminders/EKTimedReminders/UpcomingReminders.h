/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This view controller displays all reminders whose due date is within the next 7 days.
         It shows the title, due date, priority, and frequency of each reminder using EKReminder's title,
         dueDateComponents, and priority properties and EKRecurrenceRule, respectively.
         It allows you to create a reminder and mark a reminder as completed.
 
 */

@interface UpcomingReminders : UITableViewController
@end
