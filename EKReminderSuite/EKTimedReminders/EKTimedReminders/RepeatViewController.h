/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This view controller allows you to select a recurrence frequency for a reminder, which is Never, Daily, Weekly, Biweekly, Monthly, or Yearly.
         It passes the selected frequency to the AddTimedReminder view controller via the prepareForSegue:sender: method.
 
 */

@interface RepeatViewController : UITableViewController
// Keep track of the displayed frequency
@property(nonatomic, copy) NSString *displayedFrequency;

@end
