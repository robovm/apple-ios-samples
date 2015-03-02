/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A Singleton for maintaining a persitent selected home. It fires a notification when the selected home changes.
 */

#import "HomeStore.h"

NSString *const HomeStoreDidChangeSharedHomeNotification = @"HomeStoreDidChangeSharedHomeNotification";
NSString *const HomeStoreDidUpdateHomesNotification = @"HomeStoreDidUpdateHomesNotification";

@interface HomeStore () <HMHomeManagerDelegate>

/**
 *  A dispatch queue to make sure setting the home is thread-safe.
 */
@property (nonatomic) dispatch_queue_t homeQueue;

@end

@implementation HomeStore

@synthesize home = _home;

+ (instancetype)sharedStore {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [self new];
    });

    return _sharedInstance;
}

/**
 *  Creates a new HomeStore and initializes a new HomeManager.
 */
- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _homeManager = [HMHomeManager new];
    _homeManager.delegate = self;
    _homeQueue = dispatch_queue_create("com.sample.HMCatalog.HomeQueue", DISPATCH_QUEUE_SERIAL);
    return self;
}

/**
 *  @return The current saved home instance.
 */
- (HMHome *)home {
    // We always search through the homeManager's homes list
    // just in case there was a cloud refresh and the home manager
    // has a new list of instances.
    HMHome *oldHome = _home;
    HMHome *newHome = [self homeMatchingName:oldHome.name];
    _home = newHome;
    if (oldHome && !newHome) {
        // If we didn't find a match, the user has
        // either renamed or deleted the home externally.
        // Alert our observers that we have no home.
        [self alertForHomeDidChange];
    }
    return _home;
}

/**
 *  @param name The name of the home you'd like to find.
 *
 *  @return The first home in the home manager's list with a matching name.
 */
- (HMHome *)homeMatchingName:(NSString *)name {
    // Because HomeKit can invalidate Homes, we need to always
    // look for the freshest copy of the home we're currently holding.
    for (HMHome *home in self.homeManager.homes) {
        if ([name isEqualToString:home.name]) {
            return home;
        }
    }
    return nil;
}

/**
 *  Saves the home instance and updates the universal home with the new name.
 *
 *  This method always posts a notification on the main queue after setting the home.
 *
 *  @param home The home to set universally.
 */
- (void)setHome:(HMHome *)home {
    if (home == _home) {
        return;
    }
    dispatch_async(self.homeQueue, ^{
        _home = home;
        [self alertForHomeDidChange];
    });
}

- (void)alertForHomeDidChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:HomeStoreDidChangeSharedHomeNotification object:self];
    });
}

- (void)homeManagerDidUpdateHomes:(HMHomeManager *)manager {
    [[NSNotificationCenter defaultCenter] postNotificationName:HomeStoreDidUpdateHomesNotification object:self];
    self.home = [self homeMatchingName:_home.name];
}

@end
