/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A Singleton for maintaining a persitent selected home. It fires a notification when the selected home changes.
 */

@import HomeKit;

/**
 *  The notification name called whenever the HomeStore changes its home instance.
 */
extern NSString *const HomeStoreDidChangeSharedHomeNotification;
extern NSString *const HomeStoreDidUpdateHomesNotification;

@interface HomeStore : NSObject

/**
 *  A shared HomeStore to hold the current, most accurate HMHome.
 */
+ (instancetype)sharedStore;

/**
 *  The current home that the user has selected on either tab.
 */
@property HMHome *home;

@property HMHomeManager *homeManager;

@end
