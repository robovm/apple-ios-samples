/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The model object that represents a conversation.
 */

#import "AAPLConversation.h"
#import "AAPLPhoto.h"

@implementation AAPLConversation

+ (instancetype)conversationWithDictionary:(NSDictionary *)dictionary
{
    AAPLConversation *conversation = [[self alloc] init];
    conversation.name = dictionary[@"name"];
    
    NSArray *photoValues = dictionary[@"photos"];
    NSMutableArray *photos = [NSMutableArray array];
    
    for (NSDictionary *photoValue in photoValues) {
        AAPLPhoto *photo = [AAPLPhoto photoWithDictionary:photoValue];
        [photos addObject:photo];
    }
    
    conversation.photos = photos;
    return conversation;
}

@end
