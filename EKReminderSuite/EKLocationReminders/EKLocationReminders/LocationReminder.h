/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Model class representing a location reminder.
 
 */


@interface LocationReminder : NSObject
@property(nonatomic) double radius;
// Reminder's title
@property (nonatomic, copy) NSString *title;
// Reminder's proximity value
@property (nonatomic, copy) NSString *proximity;
// Reminder's recurrence frequency
@property (nonatomic, copy) NSString *frequency;
// Reminder's location used to trigger alarm
@property (nonatomic, strong) EKStructuredLocation *structuredLocation;

-(instancetype)initWithTitle:(NSString *)name proximity:(NSString *)proximity structureLocation:(EKStructuredLocation *)location NS_DESIGNATED_INITIALIZER;

@end
