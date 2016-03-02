/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The model class that stores the information about an earthquake.
 */

@import Foundation;

@interface APLEarthquake : NSObject

// Magnitude of the earthquake on the Richter scale.
@property (nonatomic) float magnitude;
// Name of the location of the earthquake.
@property (nonatomic, strong) NSString *location;
// Date and time at which the earthquake occurred.
@property (nonatomic, strong) NSDate *date;
// Latitude and longitude of the earthquake.
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;

@end
