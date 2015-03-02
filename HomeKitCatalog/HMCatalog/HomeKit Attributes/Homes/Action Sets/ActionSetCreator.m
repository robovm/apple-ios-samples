/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A CharacteristicCellDelegate that builds an HMActionSet when it receives delegate callbacks.
 */

#import "ActionSetCreator.h"
#import "NSError+HomeKit.h"

@interface ActionSetCreator ()

@property (nonatomic) dispatch_group_t saveActionSetGroup;
@property (nonatomic) NSMapTable *targetValueMap;
@property (nonatomic) NSError *saveError;

@end

@implementation ActionSetCreator

+ (instancetype)creatorWithActionSet:(HMActionSet *)actionSet inHome:(HMHome *)home {
    ActionSetCreator *controller = [self new];
    controller.actionSet = actionSet;
    controller.home = home;
    return controller;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    // Create the structure we're going to use to hold the target values.
    self.targetValueMap = [NSMapTable strongToStrongObjectsMapTable];

    // Create a dispatch group so we can properly wait for all of the individual
    // components of the saving process to finish before dismissing.
    self.saveActionSetGroup = dispatch_group_create();

    return self;
}

- (void)saveActionSetWithName:(NSString *)name completionHandler:(void (^)(NSError *error))completion {
    if (self.actionSet) {
        [self saveActionSet:self.actionSet];
        [self updateNameIfNecessary:name];
    } else {
        [self createActionSetWithName:name];
    }
    dispatch_group_notify(self.saveActionSetGroup, dispatch_get_main_queue(), ^{
        completion(self.saveError);
        self.saveError = nil;
    });
}

/**
 *  Adds all of the actions that have been requested to the Action Set, then runs a completion block.
 *
 *  @param completion A block to be called when all of the actions have been added.
 */
- (void)saveActionSet:(HMActionSet *)actionSet {
    NSArray *actions = [self actionsFromMapTable:self.targetValueMap];
    for (HMCharacteristicWriteAction *action in actions) {
        __weak typeof(self) weakSelf = self;
        dispatch_group_enter(self.saveActionSetGroup);
        [self addAction:action toActionSet:actionSet completion:^(NSError *error) {
            if (error) {
                NSLog(@"Error adding action: %@", error.hmc_localizedTranslation);
                weakSelf.saveError = error;
            }
            dispatch_group_leave(weakSelf.saveActionSetGroup);
        }];
    }
}

- (void)updateNameIfNecessary:(NSString *)name {
    if ([self.actionSet.name isEqualToString:name]) {
        return;
    }
    dispatch_group_enter(self.saveActionSetGroup);
    [self.actionSet updateName:name completionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Error updating name: %@", error.hmc_localizedTranslation);
            self.saveError = error;
        }
        dispatch_group_leave(self.saveActionSetGroup);
    }];
}

- (void)createActionSetWithName:(NSString *)name {
    __weak typeof(self) weakSelf = self;
    dispatch_group_enter(self.saveActionSetGroup);
    [self.home addActionSetWithName:name completionHandler:^(HMActionSet *actionSet, NSError *error) {
        if (error) {
            NSLog(@"Error creating action set: %@", error.hmc_localizedTranslation);
            weakSelf.saveError = error;
        } else {
            [weakSelf saveActionSet:actionSet];
        }
        dispatch_group_leave(weakSelf.saveActionSetGroup);
    }];
}

/**
 *  Checks to see if an action already exists to modify the same characteristic as the action passed in.
 *  If such an action exists, the method tells the existing action to update its target value.
 *  Otherwise, the new action is simply added to the action set.
 *
 *  @param action     The action to add or update.
 *  @param actionSet  The action set to which to add the action.
 *  @param completion A block to call when the addition has finished.
 */
- (void)addAction:(HMCharacteristicWriteAction *)action toActionSet:(HMActionSet *)actionSet completion:(void (^)(NSError *))completion {
    HMCharacteristicWriteAction *existingAction = [self existingActionInActionSetMatchingAction:action];
    if (existingAction) {
        [existingAction updateTargetValue:action.targetValue completionHandler:completion];
    } else {
        [actionSet addAction:action completionHandler:completion];
    }
}

- (HMCharacteristicWriteAction *)existingActionInActionSetMatchingAction:(HMCharacteristicWriteAction *)action {
    for (HMCharacteristicWriteAction *existingAction in self.actionSet.actions) {
        if ([action.characteristic isEqual:existingAction.characteristic]) {
            return existingAction;
        }
    }
    return nil;
}

/**
 *  Iterates over a map table of HMCharacteristic -> id objects and creates
 *  an array of HMCharacteristicWriteActions based on those targets.
 *
 *  @param table An NSMapTable mapping HMCharacteristics to id's.
 *
 *  @return An array of HMCharacteristicWriteActions.
 */
- (NSArray *)actionsFromMapTable:(NSMapTable *)table {
    NSMutableArray *actions = [NSMutableArray array];
    for (HMCharacteristic *key in table) {
        HMCharacteristicWriteAction *action = [[HMCharacteristicWriteAction alloc] initWithCharacteristic:key targetValue:[table objectForKey:key]];
        [actions addObject:action];
    }
    return actions;
}

- (BOOL)containsActions {
    return self.allCharacteristics.count > 0;
}

- (NSArray *)allCharacteristics {
    NSMutableSet *characteristics = [NSMutableSet set];
    for (HMCharacteristicWriteAction *action in self.actionSet.actions) {
        [characteristics addObject:action.characteristic];
    }
    for (HMCharacteristic *characteristic in self.targetValueMap.keyEnumerator.allObjects) {
        [characteristics addObject:characteristic];
    }
    return characteristics.allObjects;
}

- (id)targetValueForCharacteristic:(HMCharacteristic *)characteristic {
    id value = [self.targetValueMap objectForKey:characteristic];
    if (!value) {
        for (HMCharacteristicWriteAction *action in self.actionSet.actions) {
            if ([action.characteristic isEqual:characteristic]) {
                value = action.targetValue;
            }
        }
    }
    return value;
}

- (void)removeTargetValueForCharacteristic:(HMCharacteristic *)characteristic completionHandler:(void (^)())completion {
    // We need to create a dispatch group here, because in many cases
    // there will be one characteristic saved in the Action Set, and one
    // in the target value map. We want to run the completion block only one time,
    // to ensure we've removed both.
    dispatch_group_t group = dispatch_group_create();
    if ([self.targetValueMap objectForKey:characteristic]) {
        // Remove the characteristic from the target value map.
        dispatch_group_async(group, dispatch_get_main_queue(), ^{
            [self.targetValueMap removeObjectForKey:characteristic];
        });
    }
    for (HMCharacteristicWriteAction *action in self.actionSet.actions) {
        if ([action.characteristic isEqual:characteristic]) {
            // Also remove the action, and only relinquish the dispatch group
            // once the action set has finished.
            dispatch_group_enter(group);
            [self.actionSet removeAction:action completionHandler:^(NSError *error) {
                if (error) {
                    NSLog(@"%@", error.hmc_localizedTranslation);
                }
                dispatch_group_leave(group);
            }];
        }
    }
    // Once we're positive both have finished, run the completion block on the main queue.
    dispatch_group_notify(group, dispatch_get_main_queue(), completion);
}

/**
 *  Receives a callback from a CharacteristicCell with a value change.
 *  Adds this value change into the targetValueMap, overwriting other value changes.
 */
- (void)characteristicCell:(CharacteristicCell *)cell didUpdateValue:(id)newValue forCharacteristic:(HMCharacteristic *)characteristic immediate:(BOOL)immediate {
    [self.targetValueMap setObject:newValue forKey:characteristic];
}

- (void)characteristicCell:(CharacteristicCell *)cell readInitialValueForCharacteristic:(HMCharacteristic *)characteristic completion:(void (^)(id, NSError *))completion {
    // Check to see if we have an action in this Action Set that matches the characteristic.
    // If we do, call the completion block with the target value.
    for (HMCharacteristic *_characteristic in self.allCharacteristics) {
        if ([_characteristic isEqual:characteristic]) {
            completion([self targetValueForCharacteristic:characteristic], nil);
            return;
        }
    }
    // If we haven't exited the function yet, fall back to just reading the value.
    [characteristic readValueWithCompletionHandler:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(characteristic.value, error);
        });
    }];
}
@end
