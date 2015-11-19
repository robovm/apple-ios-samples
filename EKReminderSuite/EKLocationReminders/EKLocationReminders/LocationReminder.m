/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Model class representing a location reminder.
 */

#import "LocationReminder.h"

@implementation LocationReminder


-(instancetype)init
{
    self = [self initWithTitle:nil proximity:nil structureLocation:nil];
    if (self != nil)
    {
    }
    return self;
}


-(instancetype)initWithTitle:(NSString *)name proximity:(NSString *)proximity structureLocation:(EKStructuredLocation *)location
{
    self = [super init];
    if(self != nil)
    {
        _title = name;
        _proximity = proximity;
        _structuredLocation = location;
    }
    return self;
}

@end