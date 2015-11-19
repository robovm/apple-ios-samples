/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Model class representing a timed-based reminder.
 
 */

@interface TimedReminder : NSObject
// Reminder's title
@property (nonatomic, copy) NSString *title;
// Reminder's priority
@property (nonatomic, copy) NSString *priority;
// Reminder's recurrence frequency
@property (nonatomic, copy) NSString *frequency;
// Reminder's start date
@property (nonatomic, copy) NSDate *startDate;

-(instancetype)initWithTitle:(NSString *)title startDate: (NSDate *)startDate frequency:(NSString *)frequency priority: (NSString *)priority NS_DESIGNATED_INITIALIZER;

@end

