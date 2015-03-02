/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A HomeListViewController subclass which allows the user to add and remove homes and set the primary home.
 */

@import UIKit;
#import "NSError+HomeKit.h"
#import "HomeViewController.h"
#import "HomeListViewController.h"

/**
 *  Displays all of the homes in a user's HomeKit database and allows the user to select a home to
 *  interact with it.
 */
@interface HomeListConfigurationViewController : HomeListViewController

@end
