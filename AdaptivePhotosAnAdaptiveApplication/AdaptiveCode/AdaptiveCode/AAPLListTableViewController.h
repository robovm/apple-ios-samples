/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller that shows a list of conversations that can be viewed.
 */

@import UIKit;

@class AAPLUser;

@interface AAPLListTableViewController : UITableViewController

@property (strong, nonatomic) AAPLUser *user;

@end
