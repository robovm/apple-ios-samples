/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The top level model object. Manages a list of conversations and the user's profile.
 */

@import Foundation;

@class AAPLPhoto;

@interface AAPLUser : NSObject

+ (instancetype)userWithDictionary:(NSDictionary *)dictionary;

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSArray *conversations;

@property (strong, nonatomic) AAPLPhoto *lastPhoto;

@end
