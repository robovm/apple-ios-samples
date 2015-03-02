/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A simple model class to represent food and its associated energy.
            
*/

#import "AAPLFoodItem.h"

@interface AAPLFoodItem ()

@property (nonatomic, readwrite) double joules;
@property (nonatomic, readwrite, copy) NSString *name;

@end

@implementation AAPLFoodItem

+ (instancetype)foodItemWithName:(NSString *)name joules:(double)joules {
    AAPLFoodItem *foodItem = [[self alloc] init];
    
    foodItem.name = name;
    foodItem.joules = joules;

    return foodItem;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[AAPLFoodItem class]]) {
        return [object joules] == self.joules && [self.name isEqualToString:[object name]];
    }
    
    return NO;
}

- (NSString *)description {
    return [@{
        @"name": self.name,
        @"joules": @(self.joules)
    } description];
}

@end
