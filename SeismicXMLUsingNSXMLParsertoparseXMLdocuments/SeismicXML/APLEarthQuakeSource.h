/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Data source object responsible for initiating the download of the XML data and parses the Earthquake objects at view load time.
 */

@import Foundation;

@interface APLEarthQuakeSource : NSObject

@property (readonly) NSMutableArray *earthquakes;
@property (readonly) NSError *error;

- (void)startEarthQuakeLookup;

@end