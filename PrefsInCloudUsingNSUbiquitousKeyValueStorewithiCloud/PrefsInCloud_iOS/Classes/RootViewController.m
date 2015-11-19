/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The main view controller for this app, showing the preferred background color.
 */

#import "RootViewController.h"
#import "ColorsTableViewController.h"

typedef enum ColorIndex : NSInteger
{
    kColorWhite = 0,
    kColorRed,
    kColorGreen,
    kColorYellow,
} ColorIndex;


@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // listen for key-value store changes to our preference value, externally from the cloud
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateKVStoreItems:)
                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object:store];
    // note: by passing "object", it tells the cloud that we want to use "key-value store"
    // (which will allow other devices to automatically sync)

    // make sure we're showing the latest color.
    [self updateFrontViewColor];
    
    // Get any KVStore change since last launch,
    // This will spark the notification "NSUbiquitousKeyValueStoreDidChangeExternallyNotification",
    // to any interested party within this app who is listening for iCloud KVStore changes.
    //
    // It is important to only do this step *after* registering for notifications,
    // this prevents a notification arriving before code is ready to respond to it.
    //
    [store synchronize];
}

- (void)dealloc
{
    // Even though we are using ARC, we still need to manually stop observing any
    // NSNotificationCenter notifications.  Otherwise we could get "zombie" crashes when
    // NSNotificationCenter tries to notify us after our -dealloc finished.
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                  object:[NSUbiquitousKeyValueStore defaultStore]];
}


#pragma mark - ColorIndex Utilities

- (BOOL)IsValidColorIndex:(long long)colorIndex
{
    return kColorWhite <= colorIndex && colorIndex <= kColorYellow;
}

- (void)AssertValidColorIndex:(ColorIndex)colorIndex
{
    NSCAssert([self IsValidColorIndex:colorIndex], @"Invalid Color Index %ld", (long)colorIndex);
}


#pragma mark - ColorIndex Conversion Methods

// convert a ColorIndex into a UIColor that can be used for a background
- (UIColor *)backgroundColorFromColorIndex:(ColorIndex)colorIndex
{
    [self AssertValidColorIndex:colorIndex];
    switch (colorIndex)
    {
        case kColorWhite:  return [UIColor whiteColor];
        case kColorRed:    return [UIColor redColor];
        case kColorGreen:  return [UIColor greenColor];
        case kColorYellow: return [UIColor yellowColor];
    }
    return nil;
}

// the display name for a color index
- (NSString *)colorNameFromColorIndex:(ColorIndex)colorIndex
{
    [self AssertValidColorIndex:colorIndex];
    switch (colorIndex)
    {
        case kColorWhite:  return NSLocalizedString(@"White", @"");
        case kColorRed:    return NSLocalizedString(@"Red", @"");
        case kColorGreen:  return NSLocalizedString(@"Green", @"");
        case kColorYellow: return NSLocalizedString(@"Yellow", @"");
    }
    
    return NSLocalizedString(@"Unknown Color", @"");
}

- (NSIndexPath*)indexPathForColorIndex:(ColorIndex)ci
{
    [self AssertValidColorIndex:ci];
    return [NSIndexPath indexPathForRow:ci inSection:0];
}

- (ColorIndex)colorIndexAtIndexPath:(NSIndexPath*)path;
{
    ColorIndex ci = (ColorIndex)path.row;
    [self AssertValidColorIndex:ci];
    return ci;
}


#pragma mark - Color Saving

// The key-value store is not a replacement for NSUserDefaults or other local techniques
// for saving the same data. The purpose of the key-value store is to share data between apps,
// but if iCloud is not enabled or is not available on a given device, you still might want
// to keep a local copy of the data.
//
// For more information, see the "Preferences and Settings Programming Guide: Storing Preferences in iCloud":
//  <http://developer.apple.com/library/ios/documentation/cocoa/Conceptual/UserDefaults/StoringPreferenceDatainiCloud/StoringPreferenceDatainiCloud.html#//apple_ref/doc/uid/10000059i-CH7-SW7>
//
// It is important to keep your NSUserDefaults and NSUbiquitousKeyValueStore values in sync.
// It helps to only update them from a method that updates them both.


// preference key for storing our background color (used both for NSUserDefaults and KVStore)
static NSString *kBackgroundColorKey = @"backgroundColor";

// We always read the chosen color from local NSUserDefaults.
// NSUbiquitousKeyValueStore is used to update NSUserDefaults.
// Default is kColorWhite (0) if no color has been chosen yet.
//
- (NSInteger)chosenColorIndex
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBackgroundColorKey];
}

// update the chosen color
- (void)setChosenColorIndex:(ColorIndex)newColorIndex
{
    [self AssertValidColorIndex:newColorIndex]; // it is a programming error to attempt to save an invalid value
    
    NSUbiquitousKeyValueStore *kvStore = [NSUbiquitousKeyValueStore defaultStore];
    [kvStore setLongLong:newColorIndex forKey:kBackgroundColorKey];
    
    [[NSUserDefaults standardUserDefaults] setInteger:newColorIndex forKey:kBackgroundColorKey];
    
    // update the UI
    [self updateFrontViewColor];
}


#pragma mark - View Methods

- (void)updateFrontViewColor
{
    UIColor *chosenColor = [self backgroundColorFromColorIndex:(ColorIndex)self.chosenColorIndex];
    
    NSLog(@"chosenColor = %ld", (long)self.chosenColorIndex);
    NSLog(@"chosenColorName = %@", [self colorNameFromColorIndex:(ColorIndex)self.chosenColorIndex]);
    
    self.view.backgroundColor = chosenColor;
}


#pragma mark - Segues

// we are returning back from our modal view controller, obtain it's selected color and apply it here
- (IBAction)unwind:(UIStoryboardSegue *)unwindSegue
{
    ColorsTableViewController *colorsTableViewController = unwindSegue.sourceViewController;
    ColorIndex chosenColor = [self colorIndexAtIndexPath:colorsTableViewController.selectedColor];
    [self setChosenColorIndex:chosenColor];
}

// we are about to present our color table modally, send it our color content
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender
{
    // pass on the available background colors to the table view
    UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
    ColorsTableViewController *destinationVC = (ColorsTableViewController *)navController.topViewController;
    if (destinationVC != nil)
    {
        destinationVC.colors = @[[self colorNameFromColorIndex:kColorWhite],
                                 [self colorNameFromColorIndex:kColorRed],
                                 [self colorNameFromColorIndex:kColorGreen],
                                 [self colorNameFromColorIndex:kColorYellow]];
        destinationVC.selectedColor = [NSIndexPath indexPathForRow:[self chosenColorIndex] inSection:0];
    }
}


#pragma mark - Cloud support

// This method is called when the key-value store in the cloud has changed externally.
// The old color value is replaced with the new one. Additionally, NSUserDefaults is updated as well.
//
- (void)updateKVStoreItems:(NSNotification *)notification
{
	// We get more information from the notification, by using:
    // NSUbiquitousKeyValueStoreChangeReasonKey or NSUbiquitousKeyValueStoreChangedKeysKey constants
    // against the notification's useInfo.
	//
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *reasonForChange = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
    if (reasonForChange)    // reason must be determined in order to perform an update
    {
        // get the reason for the notification (initial download, external change or quota violation change)
        NSInteger reasonForChangeValue = [[userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey] integerValue];
        
        // reason can be:
        //
        // NSUbiquitousKeyValueStoreServerChange:
        //      Value(s) were changed externally from other users/devices.
        //      Get the changes and update the corresponding keys locally.
        //
        // NSUbiquitousKeyValueStoreInitialSyncChange:
        //      Initial downloads happen the first time a device is connected to an iCloud account,
        //      and when a user switches their primary iCloud account.
        //      Get the changes and update the corresponding keys locally.
        //
        // note: if you receive "NSUbiquitousKeyValueStoreInitialSyncChange" as the reason,
        // you can decide to "merge" your local values with the server values
        //
        if (reasonForChangeValue == NSUbiquitousKeyValueStoreInitialSyncChange)
        {
            // do the merge
            // ... but for this sample we have only one value, so a merge is not necessary
        }
        
        NSArray *changedKeys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
        
        // check if any of the keys we care about were updated, and if so use the new value stored under that key.
        for (NSString *changedKey in changedKeys)
        {
            if ([changedKey isEqualToString:kBackgroundColorKey])
            {
                // Replace our "selectedColor" with the value from the cloud, but *only* if it's a value we know how to interpret.
                // It is important to validate any value that comes in through iCloud, because it could have been generated by a different version of your app.
                long long possibleColorIndexFromiCloud = [[NSUbiquitousKeyValueStore defaultStore] longLongForKey:kBackgroundColorKey];
                if ([self IsValidColorIndex:possibleColorIndexFromiCloud])
                {
                    // we know the new value is valid, use it.
                    [self setChosenColorIndex:(ColorIndex)possibleColorIndexFromiCloud];
                }
                else
                {
                    // the value isn't something we can understand.
                    // The best way to handle an unexpected value depends on what the value represents, and what your app does.
                    // But a good rule of thumb is to ignore values you can not interpret and not apply the update.
                    //
                    NSLog(@"WARNING: Invalid kBackgroundColorKey value of %lld received from iCloud. This value will be ignored.", possibleColorIndexFromiCloud);
                }
            }
        }
    }
}

@end
