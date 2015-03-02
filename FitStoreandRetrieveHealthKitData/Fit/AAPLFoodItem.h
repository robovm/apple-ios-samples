/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A simple model class to represent food and its associated energy.
            
*/

@import Foundation;
@import HealthKit;

@interface AAPLFoodItem : NSObject

// Creates a new food item.
+ (instancetype)foodItemWithName:(NSString *)name joules:(double)joules;

// \c AAPLFoodItem properties are immutable.
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly) double joules;

@end
