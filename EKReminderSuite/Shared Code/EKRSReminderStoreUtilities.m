/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class creates categories for the EKAlarm, EKRecurrenceRule, and EKReminder classes.
 */

#import "EKRSConstants.h"
#import "EKRSReminderStoreUtilities.h"

#pragma mark - EKAlarm Additions

@implementation EKAlarm (AlarmAdditions)

// Return the EKAlarmProximity value matching a given name
-(EKAlarmProximity)proximityMatchingName:(NSString *)name
{
    // Default value
    EKAlarmProximity alarmProximity = EKAlarmProximityNone;
    
    if ([name isEqualToString:EKRSAlarmLeaving])
    {
        alarmProximity = EKAlarmProximityLeave;
    }
    else if ([name isEqualToString:EKRSAlarmArriving])
    {
        alarmProximity = EKAlarmProximityEnter;
    }
    
    return alarmProximity;
}


// Return the name matching a given EKAlarmProximity value
-(NSString *)nameMatchingProximity:(EKAlarmProximity)proximity
{
    NSString *name = nil;
    
    if (proximity == EKAlarmProximityLeave)
    {
        name = EKRSAlarmLeaving;
    }
    else if (proximity == EKAlarmProximityEnter)
    {
        name = EKRSAlarmArriving;
    }
    
    return name;
}

@end


#pragma mark - EKRecurrenceRule Additions

@implementation EKRecurrenceRule (RecurrenceRuleAdditions)

// Return the EKRecurrenceFrequency value matching a given name
-(EKRecurrenceFrequency)frequencyMatchingName:(NSString *)name
{
    // Default value
    EKRecurrenceFrequency recurrence = EKRecurrenceFrequencyDaily;
    
    if ([name isEqualToString:EKRSFrequencyWeekly])
    {
        recurrence = EKRecurrenceFrequencyWeekly;
    }
    else if ([name isEqualToString:EKRSFrequencyMonthly])
    {
        recurrence = EKRecurrenceFrequencyMonthly;
    }
    else if ([name isEqualToString:EKRSFrequencyYearly])
    {
        recurrence = EKRecurrenceFrequencyYearly;
    }
    
    return recurrence;
}


// Return the name matching a given EKRecurrenceFrequency value
-(NSString *)nameMatchingFrequency:(EKRecurrenceFrequency)frequency
{
    // Default value
    NSString *name = EKRSFrequencyDaily;
    
    if (frequency == EKRecurrenceFrequencyDaily)
    {
        name = EKRSFrequencyDaily;
    }
    else if (frequency == EKRecurrenceFrequencyWeekly)
    {
        name = EKRSFrequencyWeekly;
    }
    else if (frequency == EKRecurrenceFrequencyMonthly)
    {
        name = EKRSFrequencyMonthly;
    }
    else if (frequency == EKRecurrenceFrequencyYearly)
    {
        name = EKRSFrequencyYearly;
    }
    
    return name;
}


// Create a recurrence interval
-(NSUInteger)intervalMatchingFrequency:(NSString *)frequency
{
    // Return 2 if the reminder repeats every two weeks and 1, otherwise
    NSUInteger interval = ([frequency isEqualToString:EKRSFrequencyBiweekly]) ? 2: 1;
    return  interval;
}


// Create a recurrence rule
-(EKRecurrenceRule *)recurrenceRuleMatchingFrequency:(NSString *)frequency
{
    // Create a recurrence interval matching the specified frequency
    NSUInteger interval = [self intervalMatchingFrequency:frequency];
    // Create a weekly recurrence frequency if the reminder repeats every two  weeks. Fetch the EKRecurrenceFrequency value matching frequency, otherwise.
    EKRecurrenceFrequency recurrenceFrequency = ([frequency isEqualToString:EKRSFrequencyBiweekly]) ? EKRecurrenceFrequencyWeekly : [self frequencyMatchingName:frequency];
    
    // Create a recurrence rule using the above recurrenceFrequency and interval
    EKRecurrenceRule *rule = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:recurrenceFrequency
                                                                          interval:interval
                                                                               end:nil];
    return rule;
}


// Return the name matching a recurrence rule
-(NSString *)nameMatchingRecurrenceRuleWithFrequency:(EKRecurrenceFrequency)frequency interval:(NSInteger)interval
{
    // Get the name matching frequency
    NSString *name = [self nameMatchingFrequency:frequency];
    
    // A Biweekly reminder is one with a weekly recurrence frequency and an interval of 2.
    // Set name to Biweekly if that is the case.
    if ((interval == 2) && [name isEqualToString:EKRSFrequencyWeekly])
    {
        name = EKRSFrequencyBiweekly;
    }
    
    return name;
}

@end


#pragma mark - EKReminder Additions

@implementation EKReminder (EKReminderAdditions)

// Return the priority value matching a given name
-(NSInteger)priorityMatchingName:(NSString *)name
{
    NSInteger priority = 0;
    if ([name isEqualToString:EKRSPriorityNone])
    {
        priority = 0;
    }
    else if ([name isEqualToString:EKRSPriorityHigh])
    {
        priority = 4;
    }
    else if ([name isEqualToString:EKRSPriorityMedium])
    {
        priority = 5;
    }
    else if ([name isEqualToString:EKRSPriorityLow])
    {
        priority = 6;
    }
    
    return priority;
}


// Return the symbol(s) matching a given priority value. The priority is an integer
// going from 1 (highest) to 9 (lowest). A priority of 0 means no priority.
// Priorities of 1-4, which are considered High, are represented by "!!!".
// A priority of 5, which is considered Medium, is represented by "!!".
// A priority of 6-9, which are considered Low, are represented by "!".
-(NSString *)symbolMatchingPriority:(NSInteger)priority
{
    NSString *name = nil;
    if (priority == 0)
    {
        name = nil;
    }
    else if (priority > 0 && priority < 5)
    {
        name = EKRSSymbolPriorityHigh;
    }
    else if (priority == 5)
    {
        name = EKRSSymbolPriorityMedium;
    }
    else if (priority > 5)
    {
        name = EKRSSymbolPriorityLow;
    }
    
    return name;
}

@end
