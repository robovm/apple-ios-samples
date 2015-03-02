/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The model object that represents a conversation.
 */

@import Foundation;

@interface AAPLConversation : NSObject

+ (instancetype)conversationWithDictionary:(NSDictionary *)dictionary;

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSArray *photos;

@end
