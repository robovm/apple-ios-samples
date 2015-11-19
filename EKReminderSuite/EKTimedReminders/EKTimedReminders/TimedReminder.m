/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Model class representing a timed-based reminder.
 */

#import "TimedReminder.h"

@implementation TimedReminder

-(instancetype)init
{
    self = [self initWithTitle:nil startDate:nil frequency:nil priority:nil];
    if (self != nil)
    {
    }
    return self;
}


-(instancetype)initWithTitle:(NSString *)title startDate:(NSDate *)startDate frequency:(NSString *)frequency priority:(NSString *)priority
{
    self = [super init];
    if(self != nil)
    {
        _title = title;
        _startDate = startDate;
        _frequency = frequency;
        _priority = priority;
    }
    return self;
}

@end
