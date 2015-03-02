/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that creates Timer Triggers. It contains a Name field, a switch for enabling or disabling, 
  a list of Action Sets to add or remove from the trigger, a date picker for choosing a fire date, and a list of possible recurrence intervals.
 */

@import UIKit;
@import HomeKit;
#import "HomeKitTableViewController.h"

/**
 *  TriggerViewController provides UI for creating triggers with a single kind of recurrence.
 *  It creates a table that contains action sets, a date picker, and a few recurrence interval types.
 *
 *  When the user taps the 'Save' button, all of the data associated with the view is used to
 *  initialize a new HMTimerTrigger and add it to the home.
 */
@interface TriggerViewController : HomeKitTableViewController

/**
 *  The trigger with which to initialize this View Controller.
 */
@property (nonatomic) HMTimerTrigger *trigger;

@end
