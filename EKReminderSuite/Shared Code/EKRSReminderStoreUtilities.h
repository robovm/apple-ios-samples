/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class creates categories for the EKAlarm, EKRecurrenceRule, and EKReminder classes.
 
 */

#pragma mark - EKAlarm Additions
@interface EKAlarm (AlarmAdditions)
-(EKAlarmProximity)proximityMatchingName:(NSString *)name;
-(NSString *)nameMatchingProximity:(EKAlarmProximity)proximity;

@end


#pragma mark - EKRecurrenceRule Additions
@interface EKRecurrenceRule (RecurrenceRuleAdditions)
-(EKRecurrenceFrequency)frequencyMatchingName:(NSString *)name;
-(NSString *)nameMatchingFrequency:(EKRecurrenceFrequency)frequency;

-(NSUInteger)intervalMatchingFrequency:(NSString *)frequency;

-(EKRecurrenceRule *)recurrenceRuleMatchingFrequency:(NSString *)frequency;
-(NSString *)nameMatchingRecurrenceRuleWithFrequency:(EKRecurrenceFrequency)frequency interval:(NSInteger)interval;

@end


#pragma mark - EKReminder Additions
@interface EKReminder (EKReminderAdditions)
-(NSInteger)priorityMatchingName:(NSString *)name;
-(NSString *)symbolMatchingPriority:(NSInteger)priority;

@end