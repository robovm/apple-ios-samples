/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A generic UITableViewController subclass that automatically responds to HomeKit refreshing its objects.
 */

@import UIKit;
@import HomeKit;

@interface HomeKitTableViewController : UITableViewController <HMHomeDelegate>

/**
 *  The current selected Home.
 */
@property (nonatomic, readonly) HMHome *home;

/**
 *  Called whenever the HomeStore updates its home.
 *
 *  The view controller will be responsible for repopulating the HomeKit
 *  objects associated with the current view. This may require inspecting
 *  the home for a new instance of an HMAccessory, for instance.
 *
 *  This function is guaranteed to be called on the main thread.
 */
- (void)homeStoreDidUpdateHomes;

@end
