/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableViewCell subclass that displays the current value of an HMCharacteristic and 
  notifies its delegate of changes. Subclasses of this class will provide additional controls to display different kinds of data.
 */

@import UIKit;
@import HomeKit;

@class CharacteristicCell;

@protocol CharacteristicCellDelegate <NSObject>
/**
 *  Called whenever the control within the cell updates its value.
 *
 *  @param cell           The cell which has updated its value.
 *  @param newValue       The new value represented by the cell's control.
 *  @param characteristic The characteristic the cell represents.
 *  @param immediate      Whether or not to update external values immediately.
 *                        For example, Slider cells should not update immediately upon value change,
 *                        so their values are cached and updates are coalesced. Subclasses can decide
 *                        whether or not their values are meant to be updated immediately.
 */
- (void)characteristicCell:(CharacteristicCell *)cell didUpdateValue:(id)newValue forCharacteristic:(HMCharacteristic *)characteristic immediate:(BOOL)immediate;

/**
 *  Called when the characteristic cell needs to reload its value from an external source.
 *  Consider using this call to look up values in memory or query them from an accessory.
 *
 *  @param cell           The cell requesting a value update.
 *  @param characteristic The characteristic for whose value the cell is asking.
 *  @param completion     The block that the cell provides to be called when values have been read successfully.
 */
- (void)characteristicCell:(CharacteristicCell *)cell readInitialValueForCharacteristic:(HMCharacteristic *)characteristic completion:(void (^)(id, NSError *))completion;

@end

@interface CharacteristicCell : UITableViewCell

/**
 *  The delegate to receive cell update notifications.
 */
@property (weak, nonatomic) id<CharacteristicCellDelegate> delegate;

/**
 *  The label that holds the textual value.
 */
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

/**
 *  The label that holds the characteristic type.
 */
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;

/**
 *  The characteristic associated with the cell.
 */
@property (weak, nonatomic) HMCharacteristic *characteristic;

/**
 *  The cell's characteristic's value..
 */
@property (nonatomic) id value;

- (void)setValue:(id)newValue notify:(BOOL)notify;

+ (BOOL)updatesImmediately;

@end
