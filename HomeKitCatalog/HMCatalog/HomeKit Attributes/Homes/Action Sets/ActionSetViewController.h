/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that facilitates creation of Action Sets. It contains a cell for a name, and lists accessories within a home. 
  If there are actions within the action set, it also displays a list of ActionCells displaying those actions.
  It owns an ActionSetCreator and routes events to the creator as appropriate.
 */

@import UIKit;
@import HomeKit;
#import "HomeKitTableViewController.h"

@interface ActionSetViewController : HomeKitTableViewController

/**
 *  The action set that this controller will configure.
 */
@property (nonatomic) HMActionSet *actionSet;

@end
