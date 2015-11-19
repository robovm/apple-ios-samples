/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A helper class that includes methods to create a date formatter, generate a custom date, and display an alert.
 */

#import "EKRSHelperClass.h"

@implementation EKRSHelperClass

#pragma mark - Date Formatter

// Create a date formatter with a short date and time
+(NSDateFormatter *)dateFormatter
{
    NSDateFormatter *myDateFormatter = [[NSDateFormatter alloc] init];
    myDateFormatter.dateStyle = NSDateFormatterShortStyle;
    myDateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    return myDateFormatter;
}


#pragma mark - Create a Date

// Create a new date by adding a given number of days to the current date
+(NSDate*)dateByAddingDays:(NSInteger)day
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = day;
    
    return [gregorian dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
}


#pragma mark - Create Alert Dialog

// Return an alert with a given title and message
+(UIAlertController *)alertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    return alert;
}

@end