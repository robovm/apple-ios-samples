/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The NSOperation class used to perform the XML parsing of earthquake data.
 */

@import Foundation;

@interface APLParseOperation : NSOperation

@property (copy, readonly) NSData *earthquakeData;

- (instancetype)initWithData:(NSData *)parseData NS_DESIGNATED_INITIALIZER;

+ (NSString *)AddEarthQuakesNotificationName;       // NSNotification name for sending earthquake data back to the app delegate
+ (NSString *)EarthquakeResultsKey;                 // NSNotification userInfo key for obtaining the earthquake data

+ (NSString *)EarthquakesErrorNotificationName;     // NSNotification name for reporting errors
+ (NSString *)EarthquakesMessageErrorKey;           // NSNotification userInfo key for obtaining the error message

@end
