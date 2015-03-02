/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller that shows a user's profile.
 */

@import UIKit;

@class AAPLUser;

@interface AAPLProfileViewController : UIViewController

@property (strong, nonatomic) AAPLUser *user;

@end
