/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A model class that represents a user in the application.
  
 */

#import "AAPLPerson.h"

static NSString *const AAPLPersonPhotoKey = @"photo";
static NSString *const AAPLPersonAgeKey = @"age";
static NSString *const AAPLPersonHobbiesKey = @"hobbies";
static NSString *const AAPLPersonElevatorPitchKey = @"elevatorPitch";

@implementation AAPLPerson

+ (instancetype)personWithDictionary:(NSDictionary *)personDictionary {
    AAPLPerson *person = [[self alloc] init];
    
    person.photo = [UIImage imageNamed:personDictionary[AAPLPersonPhotoKey]];
    person.age = [personDictionary[AAPLPersonAgeKey] unsignedIntegerValue];
    person.hobbies = personDictionary[AAPLPersonHobbiesKey];
    person.elevatorPitch = personDictionary[AAPLPersonElevatorPitchKey];
    return person;
}

@end
