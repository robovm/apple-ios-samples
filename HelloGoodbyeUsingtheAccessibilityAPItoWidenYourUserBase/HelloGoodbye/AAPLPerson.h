/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A model class that represents a user in the application.
  
 */

@import UIKit;

@interface AAPLPerson : NSObject

@property (nonatomic) UIImage *photo;
@property (nonatomic) NSUInteger age;
@property (nonatomic) NSString *hobbies;
@property (nonatomic) NSString *elevatorPitch;

// Property list deserialization
+ (instancetype)personWithDictionary:(NSDictionary *)personDictionary;

@end
