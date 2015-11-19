/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A helper class that includes methods to create a date formatter, generate a custom date, and display an alert.
 
 */

#define kMeter 1609.344

@interface EKRSHelperClass : NSObject
+(NSDateFormatter *)dateFormatter;
+(NSDate*)dateByAddingDays:(NSInteger)day;
+(UIAlertController *)alertWithTitle:(NSString *)title message:(NSString *)message;

@end
