/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This view controller displays all reminders whose due date was within the last 7 days.
         It shows the title, due date, frequency, and priority of each reminder using EKReminder's title, dueDateComponents, and priority properties
         and EKRecurrenceRule, respectively. It also allows you to mark a reminder as completed.
 
 */

@interface PastDueReminders : UITableViewController
@end
