/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A UITableViewDataSource that populates a CharacteristicsViewController.
 */

#import "CharacteristicsTableViewDataSource.h"
#import "HMCharacteristic+Properties.h"
#import "HMService+Readability.h"
#import "NSError+HomeKit.h"
#import "UITableView+Updating.h"

typedef NS_ENUM(NSUInteger, CharacteristicsTableViewSection) {
    CharacteristicsTableViewSectionCharacteristics,
    CharacteristicsTableViewSectionAssociatedServiceType
};

@implementation CharacteristicsTableViewDataSource

+ (instancetype)dataSourceWithService:(HMService *)service tableView:(UITableView *)tableView delegate:(id<CharacteristicCellDelegate>)delegate {
    return [[self alloc] initWithService:service tableView:tableView delegate:delegate];
}

- (instancetype)initWithService:(HMService *)service tableView:(UITableView *)tableView delegate:(id<CharacteristicCellDelegate>)delegate {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.service = service;
    self.tableView = tableView;
    self.cellDelegate = delegate;
    return self;
}

/**
 *  Registers the tableView for each of the characteristic cell subclasses as well as the ServiceTypeCell.
 */
- (void)registerReuseIdentifiers {
    [self.tableView registerNib:[UINib nibWithNibName:@"CharacteristicCell" bundle:nil] forCellReuseIdentifier:@"CharacteristicCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"SliderCharacteristicCell" bundle:nil] forCellReuseIdentifier:@"SliderCharacteristicCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"SwitchCharacteristicCell" bundle:nil] forCellReuseIdentifier:@"SwitchCharacteristicCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"SegmentedControlCharacteristicCell" bundle:nil] forCellReuseIdentifier:@"SegmentedControlCharacteristicCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ServiceTypeCell"];
}

/**
 *  2 sections if the system supports associated service types,
 *  otherwise 1 section.
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.service.hmc_supportsAssociatedService) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case CharacteristicsTableViewSectionCharacteristics:
            return self.service.characteristics.count;
        case CharacteristicsTableViewSectionAssociatedServiceType:
            return [HMService hmc_validAssociatedServiceTypes].count + 1;
        default:
            return 0;
    }
}

/**
 *  Saves the tableView that's passed in, sets its delegate, and registers it for reuse identifiers.
 *
 *  @param tableView The tableView this dataSource will control.
 */
- (void)setTableView:(UITableView *)tableView {
    _tableView = tableView;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 50.0;
    [self registerReuseIdentifiers];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case CharacteristicsTableViewSectionCharacteristics:
            return [self tableView:tableView characteristicCellForRowAtIndexPath:indexPath];
        case CharacteristicsTableViewSectionAssociatedServiceType: {
            return [self tableView:tableView associatedServiceTypeCellForRowAtIndexPath:indexPath];
        }
    }
    return nil;
}

/**
 *  Looks up the appropriate service type for the row in the list and returns a localized version,
 *  or 'None' if the row doesn't correspond to any valid service type.
 *
 *  @param row The row to look up.
 *
 *  @return The localized service type in that row, or 'None'.
 */
- (NSString *)displayedServiceTypeForRow:(NSUInteger)row {
    NSArray *serviceTypes = [HMService hmc_validAssociatedServiceTypes];
    if (row < serviceTypes.count) {
        return [HMService hmc_localizedDescriptionForServiceType:serviceTypes[row]];
    }
    return NSLocalizedString(@"None", @"None");
}

/**
 *  @return whether or not the selected row is a valid associated service type, or the 'None' row.
 *
 *  @param row The selected row.
 *
 *  @return YES if the current row is a valid service type.
 */
- (BOOL)serviceTypeIsSelectedForRow:(NSUInteger)row {
    NSArray *serviceTypes = [HMService hmc_validAssociatedServiceTypes];
    if (row >= serviceTypes.count) {
        return self.service.associatedServiceType == nil;
    }
    return [serviceTypes[row] isEqualToString:self.service.associatedServiceType];
}

/**
 *  Creates a new cell with the associated service type of the indexPath's row as the text.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView associatedServiceTypeCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ServiceTypeCell" forIndexPath:indexPath];
    cell.textLabel.text = [self displayedServiceTypeForRow:indexPath.row];
    if ([self serviceTypeIsSelectedForRow:indexPath.row]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

/**
 *  Creates a new CharacteristicCell by figuring out the best and most appropriate container
 *  for the characteristic at the given indexPath and sets its delegate.
 */
- (CharacteristicCell *)tableView:(UITableView *)tableView characteristicCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HMCharacteristic *characteristic = self.service.characteristics[indexPath.row];

    // Dequeue once, choose reuse identifiers in if/else blocks
    NSString *cellReuseIdentifier = @"CharacteristicCell";
    if (characteristic.hmc_isReadOnly || characteristic.hmc_isWriteOnly) {
        cellReuseIdentifier = @"CharacteristicCell";
    } else if (characteristic.hmc_isBoolean) {
        cellReuseIdentifier = @"SwitchCharacteristicCell";
    } else if (characteristic.hmc_hasPredeterminedValueDescriptions) {
        cellReuseIdentifier = @"SegmentedControlCharacteristicCell";
    } else if (characteristic.hmc_isNumeric) {
        cellReuseIdentifier = @"SliderCharacteristicCell";
    }
    CharacteristicCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier forIndexPath:indexPath];

    cell.delegate = self.cellDelegate;
    cell.characteristic = characteristic;

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case CharacteristicsTableViewSectionCharacteristics:
            return NSLocalizedString(@"Characteristics", @"Characteristics");
        case CharacteristicsTableViewSectionAssociatedServiceType:
            return NSLocalizedString(@"Associated Service Type", @"Associated Service Type");
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case CharacteristicsTableViewSectionCharacteristics: {
            HMCharacteristic *characteristic = self.service.characteristics[indexPath.row];
            [self didSelectCharacteristic:characteristic];
            break;
        }
        case CharacteristicsTableViewSectionAssociatedServiceType: {
            [self didSelectAssociatedServiceTypeAtIndexPath:indexPath];
            break;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/**
 *  If a characteristic is selected, and it is the 'Identify' characteristic.
 *  perform and Identify on that accessory.
 */
- (void)didSelectCharacteristic:(HMCharacteristic *)characteristic {
    if (!characteristic.hmc_isIdentify) {
        return;
    }
    [self.service.accessory identifyWithCompletionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Error identifying: %@", error.hmc_localizedTranslation);
        }
    }];
}

/**
 *  Handles selection of one of the associated service types in the list.
 *
 *  @param indexPath The selected index path.
 */
- (void)didSelectAssociatedServiceTypeAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *serviceTypes = [HMService hmc_validAssociatedServiceTypes];
    NSString *newServiceType;
    if (indexPath.row < serviceTypes.count) {
        newServiceType = serviceTypes[indexPath.row];
    }
    [self.service updateAssociatedServiceType:newServiceType completionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Error setting associated service type: %@", error);
            return;
        }
        [self didUpdateAssociatedServiceType];
    }];
}

- (void)didUpdateAssociatedServiceType {
    [self.tableView hmc_update:^(UITableView *tableView) {
        NSIndexSet *associatedServiceTypeIndexSet = [NSIndexSet indexSetWithIndex:CharacteristicsTableViewSectionAssociatedServiceType];
        [tableView reloadSections:associatedServiceTypeIndexSet withRowAnimation:UITableViewRowAnimationFade];
    }];
}

@end
