/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableViewDataSource that populates a CharacteristicsViewController.
 */

@import Foundation;
@import UIKit;
@import HomeKit;
#import "CharacteristicCell.h"

/**
 *  @class CharacteristicsTableViewDataSource
 *  @discussion This class acts as the data source to control characteristics.
 */
@interface CharacteristicsTableViewDataSource : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) HMService *service;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) id<CharacteristicCellDelegate> cellDelegate;

+ (instancetype)dataSourceWithService:(HMService *)service tableView:(UITableView *)tableView delegate:(id<CharacteristicCellDelegate>)delegate;

- (void)didUpdateAssociatedServiceType;

@end
