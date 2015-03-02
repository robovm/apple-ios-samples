/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A CharacteristicCellDelegate that builds an HMActionSet when it receives delegate callbacks.
 */
@import Foundation;
#import "CharacteristicCell.h"

@interface ActionSetCreator : NSObject <CharacteristicCellDelegate>

/**
 *  @return YES if the Action Set contains actions, either already added to
 *  the action set or are waiting to be added.
 */
@property (nonatomic, readonly) BOOL containsActions;

/**
 *  @return all of the characteristics applying to this action set, saved or unsaved.
 */
@property (nonatomic, readonly) NSArray *allCharacteristics;

/**
 *  The home to which this action set will be added.
 */
@property (nonatomic) HMHome *home;

/**
 *  The action set which will be updated by this creator.
 */
@property (nonatomic) HMActionSet *actionSet;

/**
 *  Creates a new ActionSetCreator with an optional actionSet and required home.
 *
 *  @param actionSet An existing action set, if one is being modified.
 *  @param home      A Home to which to add the action set.
 *
 *  @return A new ActionSetCreator.
 */
+ (instancetype)creatorWithActionSet:(HMActionSet *)actionSet inHome:(HMHome *)home;

/**
 *  Looks through the unsaved or already-saved characteristics and returns the target
 *  value for that characteristic in this action set.
 *
 *  @param characteristic The characteristic to look up.
 *
 *  @return The target value, with unsaved changes taking precedence.
 */
- (id)targetValueForCharacteristic:(HMCharacteristic *)characteristic;

/**
 *  Saves the action set and adds all pending target values to the action set.
 *
 *  @param name       The new name for the Action Set
 *  @param completion A block to call once saving has completed.
 */
- (void)saveActionSetWithName:(NSString *)name completionHandler:(void (^)(NSError *))completion;

/**
 *  Removes a target value for a characteristic. If the characteristic has been saved,
 *  then it calls <code>removeAction:completionHandler:</code>, otherwise it removes
 *  the entry from the <code>targetValueMap</code>
 *
 *  @param characteristic The characteristic to remove.
 *  @param completion     A block to call once the characteristic has been removed. This may be called multiple times.
 */
- (void)removeTargetValueForCharacteristic:(HMCharacteristic *)characteristic completionHandler:(void (^)())completion;

@end
