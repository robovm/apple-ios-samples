/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  The top level model object. Manages a list of conversations and the user's profile.
 */

#import "AAPLUser.h"
#import "AAPLConversation.h"
#import "AAPLPhoto.h"

@implementation AAPLUser

+ (instancetype)userWithDictionary:(NSDictionary *)dictionary
{
    AAPLUser *user = [[self alloc] init];
    user.name = dictionary[@"name"];
    
    NSArray *conversationDictionaries = dictionary[@"conversations"];
    NSMutableArray *conversations = [NSMutableArray array];
    
    for (NSDictionary *conversationDictionary in conversationDictionaries) {
        AAPLConversation *conversation = [AAPLConversation conversationWithDictionary:conversationDictionary];
        [conversations addObject:conversation];
    }
    
    user.conversations = conversations;
    
    NSDictionary *lastPhotoDictionary = dictionary[@"lastPhoto"];
    user.lastPhoto = [AAPLPhoto photoWithDictionary:lastPhotoDictionary];
    return user;
}

@end
