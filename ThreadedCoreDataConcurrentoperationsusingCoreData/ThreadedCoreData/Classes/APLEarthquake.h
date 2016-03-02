/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The model class that stores the information about an earthquake.
 */

@import Foundation;
@import CoreData;

@interface APLEarthquake : NSManagedObject

// Magnitude of the earthquake on the Richter scale.
@property (nonatomic, unsafe_unretained) NSNumber *magnitude;

// Name of the location of the earthquake.
@property (nonatomic, strong) NSString *location;
// Date and time at which the earthquake occurred.
@property (nonatomic, strong) NSDate *date;

// Latitude and longitude of the earthquake.
@property (nonatomic, unsafe_unretained) NSNumber *latitude;
@property (nonatomic, unsafe_unretained) NSNumber *longitude;

@end
