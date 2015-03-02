/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 An object that responds to CharacteristicCell updates and notifies HomeKit of changes.
 */

#import "AccessoryUpdateController.h"
#import "NSError+HomeKit.h"

@interface AccessoryUpdateController ()

// This exists to keep us from sending an unreasonable amount
// of network traffic through HomeKit.
@property (nonatomic) NSTimer *updateValueTimer;

// Use an NSMapTable because we want to keep strong references
// to the characteristics and their target values.
@property (nonatomic) NSMapTable *targetValueMap;

@end

@implementation AccessoryUpdateController

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    [self startListeningForCellUpdates];
    return self;
}

- (void)dealloc {
    [self stopListeningForCellUpdates];
}

#pragma mark - CharacteristicCellDelegate

/**
 *  Update the target value map with the passed in value, and if immediate, immediately updates characteristics.
 *
 *  @param cell           The cell that was updated.
 *  @param newValue       The new value.
 *  @param characteristic The characteristic to update.
 *  @param immediate      Whether or not to update immediately.
 */
- (void)characteristicCell:(CharacteristicCell *)cell didUpdateValue:(id)newValue forCharacteristic:(HMCharacteristic *)characteristic immediate:(BOOL)immediate {
    [self.targetValueMap setObject:newValue forKey:characteristic];
    if (immediate) {
        [self updateCharacteristics];
    }
}

/**
 *  Reads the value from the characteristic and calls the passed-in completion block on the main thread.
 */
- (void)characteristicCell:(CharacteristicCell *)cell readInitialValueForCharacteristic:(HMCharacteristic *)characteristic completion:(void (^)(id, NSError *))completion {
    [characteristic readValueWithCompletionHandler:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(characteristic.value, error);
        });
    }];
}

/**
 *  Registers for CharacteristicCell update notifications and starts the coalesced
 *  characteristic writing timer.
 */
- (void)startListeningForCellUpdates {
    self.updateValueTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                             target:self
                                                           selector:@selector(updateCharacteristics)
                                                           userInfo:nil
                                                            repeats:YES];
    self.targetValueMap = [NSMapTable strongToStrongObjectsMapTable];
}

/**
 *  Invalidates the timer and resets the target value map.
 */
- (void)stopListeningForCellUpdates {
    [self.updateValueTimer invalidate];
    self.targetValueMap = nil;
}

/**
 *  On our schedule, iterate through the map and perform the writes.
 *  This means that no matter how much the user changes the sliders,
 *  there will always be a steady, limited stream of write requests.
 */
- (void)updateCharacteristics {
    for (HMCharacteristic *characteristic in self.targetValueMap) {
        id newValue = [self.targetValueMap objectForKey:characteristic];
        [characteristic writeValue:newValue completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Could not change value: %@", error.hmc_localizedTranslation);
                return;
            }
        }];
    }
    [self.targetValueMap removeAllObjects];
}

@end
