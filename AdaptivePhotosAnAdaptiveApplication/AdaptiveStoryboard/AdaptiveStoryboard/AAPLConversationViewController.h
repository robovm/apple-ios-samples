/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller that shows the contents of a conversation.
 */

@import UIKit;

@class AAPLConversation;

@interface AAPLConversationViewController : UITableViewController

@property (strong, nonatomic) AAPLConversation *conversation;

@end
