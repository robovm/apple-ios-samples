/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Constants used by various classes in the EKReminderSuite project.
 */

#import "EKRSConstants.h"

#pragma mark - EKRSReminderStore

NSString * const EKRSAccessDeniedNotification = @"EKRSAccessDeniedNotification";
NSString * const EKRSAccessGrantedNotification = @"EKRSAccessGrantedNotification";
NSString * const EKRSLocationRemindersNotification = @"EKRSIncompleteRemindersNotification";
NSString * const EKRSCompletedRemindersNotification = @"EKRSCompletedRemindersNotification";
NSString * const EKRSPastDueRemindersNotification = @"EKRSPastDueRemindersNotification";
NSString * const EKRSUpcomingRemindersNotification = @"EKRSUpcomingRemindersNotification";
NSString * const EKRSRefreshDataNotification = @"EKRSRefreshDataNotification";
NSString * const EKRSFailureNotification = @"EKRSFailureNotification";


#pragma mark - EKRSReminderStoreUtilities

NSString * const EKRSFrequencyNever = @"Never";
NSString * const EKRSFrequencyDaily = @"Daily";
NSString * const EKRSFrequencyWeekly = @"Weekly";
NSString * const EKRSFrequencyYearly = @"Yearly";
NSString * const EKRSFrequencyMonthly = @"Monthly";
NSString * const EKRSFrequencyBiweekly = @"Biweekly";

NSString * const EKRSAlarmLeaving = @"Leaving";
NSString * const EKRSAlarmArriving = @"Arriving";

NSString * const EKRSPriorityLow = @"Low";
NSString * const EKRSPriorityHigh = @"High";
NSString * const EKRSPriorityNone = @"None";
NSString * const EKRSPriorityMedium = @"Medium";

NSString * const EKRSSymbolPriorityLow = @"!";
NSString * const EKRSSymbolPriorityHigh = @"!!!";
NSString * const EKRSSymbolPriorityMedium = @"!!";

#pragma mark - TimedTabBarController

NSString * const TTBAccessGrantedNotification = @"TTBAccessGrantedNotification";
NSString * const TTBUpcomingRemindersNotification = @"TTBUpcomingRemindersNotification";
NSString * const TTBPastDueRemindersNotification = @"TTBPastDueRemindersNotification";
NSString * const TTBCompletedRemindersNotification = @"TTBCompletedRemindersNotification";


#pragma mark - LocationTabBarController

NSString * const LTBAccessGrantedNotification = @"LTBAccessGrantedNotification";
NSString * const LTBRemindersFetchedNotification = @"LTBRemindersFetchedNotification";

#pragma mark

NSString *const EKRSTitle = @"title";
NSString *const EKRSLocationRadius = @"radius";
NSString *const EKRSLocationProximity = @"proximity";
NSString *const EKRSDescription = @"description";

