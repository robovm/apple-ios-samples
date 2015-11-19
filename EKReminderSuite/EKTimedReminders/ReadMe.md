# EKTimedReminders
EKTimedReminders demonstrates how to add, fetch, and remove time-based reminders using the EventKit framework.
It shows how to create alarms and recurring reminders using EKReminder, EKAlarm, EKRecurrenceFrequency, and EKRecurrenceRule.
It displays the title, due date, and priority of each reminder using EKReminder's title, dueDateComponents, and priority properties,respectively.
It also shows how to complete reminders using EKReminder's completed property.
It consists of three views: Upcoming, “Past Due”, and Complete. Upcoming displays all reminders whose due date is within the next 7 days,
“Past Due” displays all reminders whose due date was within the last 7 days, and Complete shows completed reminders that occur within +/- 7 days.
Tap “+” in Upcoming to add a new reminder. Tap any reminder in Upcoming or “Past Due” to complete it. Navigate to Complete to delete any reminder.


## Requirements

### Build

iOS SDK 9.1 or later

### Runtime

iOS 8.0 or later

Copyright (C) 2015 Apple Inc. All rights reserved.
