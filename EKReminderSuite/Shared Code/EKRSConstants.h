/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Constants used by various classes in the EKReminderSuite project.
 
 */

#pragma mark - EKRSReminderStore

extern NSString * const EKRSAccessDeniedNotification; // Indicates that access was denied to Reminders
extern NSString * const EKRSAccessGrantedNotification; // Indicates that access was granted to Reminders
extern NSString * const EKRSLocationRemindersNotification; // Indicates that location reminders were fetched
extern NSString * const EKRSCompletedRemindersNotification; // Indicates that completed reminders were fetched
extern NSString * const EKRSPastDueRemindersNotification; // Indicates that past-due reminders were fetched
extern NSString * const EKRSUpcomingRemindersNotification; // Indicates that upcoming reminders were fetched
extern NSString * const EKRSRefreshDataNotification; // Sent when saving, removing, or marking a reminder as completed was successful
extern NSString * const EKRSFailureNotification; // Sent when saving, removing, or marking a reminder as completed failed


#pragma mark - EKRSReminderStoreUtilities

extern NSString * const EKRSFrequencyNever;
extern NSString * const EKRSFrequencyDaily;
extern NSString * const EKRSFrequencyWeekly;
extern NSString * const EKRSFrequencyYearly;
extern NSString * const EKRSFrequencyMonthly;
extern NSString * const EKRSFrequencyBiweekly;

extern NSString * const EKRSAlarmLeaving;
extern NSString * const EKRSAlarmArriving;

extern NSString * const EKRSPriorityLow;
extern NSString * const EKRSPriorityHigh;
extern NSString * const EKRSPriorityNone;
extern NSString * const EKRSPriorityMedium;

extern NSString * const EKRSSymbolPriorityLow;
extern NSString * const EKRSSymbolPriorityHigh;
extern NSString * const EKRSSymbolPriorityMedium;


#pragma mark - TimedTabBarController

extern NSString * const TTBAccessGrantedNotification;
extern NSString * const TTBUpcomingRemindersNotification;
extern NSString * const TTBPastDueRemindersNotification;
extern NSString * const TTBCompletedRemindersNotification;

#pragma mark - LocationTabBarController

extern NSString * const LTBAccessGrantedNotification; // Indicates that access was granted to Reminders
extern NSString * const LTBRemindersFetchedNotification; // Indicates that location reminders were received


#pragma mark -

extern NSString *const EKRSTitle;
extern NSString *const EKRSDescription;
extern NSString *const EKRSLocationRadius;
extern NSString *const EKRSLocationProximity;


