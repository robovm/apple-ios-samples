/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that facilitates creation of Action Sets. It contains a cell for a name, and lists accessories within a home. 
  If there are actions within the action set, it also displays a list of ActionCells displaying those actions.
  It owns an ActionSetCreator and routes events to the creator as appropriate.
 */

#import "ActionSetViewController.h"
#import "ServicesViewController.h"
#import "ActionSetCreator.h"
#import "ActionCell.h"
#import "UIViewController+Convenience.h"
#import "UITableView+Updating.h"
#import "HMCharacteristic+Readability.h"

typedef NS_ENUM(NSUInteger, ActionSetTableViewSection) {
    ActionSetTableViewSectionName = 0,
    ActionSetTableViewSectionAction,
    ActionSetTableViewSectionAccessory
};

@interface ActionSetViewController () <HMHomeDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (nonatomic) ActionSetCreator *actionSetCreator;

@end

@implementation ActionSetViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.nameField.text = self.actionSet.name;
    [self nameFieldDidChange:self.nameField];

    self.actionSetCreator = [ActionSetCreator creatorWithActionSet:self.actionSet inHome:self.home];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AccessoryCell"];
    [self.tableView registerClass:[ActionCell class] forCellReuseIdentifier:@"ActionCell"];

    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self enableSaveButtonIfApplicable];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

/**
 *  Resets the action set contained within our ActionSetCreator.
 */
- (void)homeStoreDidUpdateHomes {
    self.actionSetCreator.home = self.home;
    for (HMActionSet *actionSet in self.home.actionSets) {
        if ([actionSet.name isEqualToString:self.actionSet.name]) {
            self.actionSet = actionSet;
            self.actionSetCreator.actionSet = actionSet;
        }
    }
    [super homeStoreDidUpdateHomes];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case ActionSetTableViewSectionAccessory:
            return self.home.accessories.count;
        case ActionSetTableViewSectionAction:
            return MAX(self.actionSetCreator.allCharacteristics.count, 1);
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == ActionSetTableViewSectionAction;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.actionSetCreator removeTargetValueForCharacteristic:self.actionSetCreator.allCharacteristics[indexPath.row] completionHandler:^() {
        [tableView hmc_update:^(UITableView *tableView) {
            if (self.actionSetCreator.containsActions) {
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }];
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ActionSetTableViewSectionAccessory:
            return [self tableView:tableView accessoryCellForRowAtIndexPath:indexPath];
        case ActionSetTableViewSectionAction:
            if (self.actionSetCreator.containsActions) {
                return [self tableView:tableView actionCellForRowAtIndexPath:indexPath];
            }
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView accessoryCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AccessoryCell" forIndexPath:indexPath];
    HMAccessory *accessory = self.home.accessories[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = accessory.name;
    return cell;
}

- (ActionCell *)tableView:(UITableView *)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell" forIndexPath:indexPath];
    HMCharacteristic *characteristic = self.actionSetCreator.allCharacteristics[indexPath.row];
    id value = [self.actionSetCreator targetValueForCharacteristic:characteristic];
    [cell setCharacteristic:characteristic targetValue:value];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ActionSetTableViewSectionAccessory:
        // fallthrough
        case ActionSetTableViewSectionAction:
            return UITableViewAutomaticDimension;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *fakeIndexPath = [NSIndexPath indexPathForRow:0 inSection:ActionSetTableViewSectionName];
    return [super tableView:tableView indentationLevelForRowAtIndexPath:fakeIndexPath];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Show Services"]) {
        ServicesViewController *detailVC = segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        detailVC.accessory = self.home.accessories[indexPath.row];
        detailVC.cellDelegate = self.actionSetCreator;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.selectionStyle == UITableViewCellSelectionStyleNone) {
        return;
    }
    switch (indexPath.section) {
        case ActionSetTableViewSectionAccessory:
            [self performSegueWithIdentifier:@"Show Services" sender:cell];
            break;
        default:
            break;
    }
}

/**
 *  Creates the requested HMCharacteristicWriteActions and adds them to
 *  the action set we had passed in, then dismisses this controller.
 */
- (void)dismiss {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (IBAction)nameFieldDidChange:(UITextField *)sender {
    [self enableSaveButtonIfApplicable];
}

- (void)enableSaveButtonIfApplicable {
    // Enable the save button if the text field has something in it.
    self.saveButton.enabled = [self trimmedName].length > 0 &&
                              self.actionSetCreator.containsActions;
}

- (NSString *)trimmedName {
    return [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (IBAction)saveAndDismiss {
    NSString *name = [self trimmedName];
    self.saveButton.enabled = NO;
    [self.actionSetCreator saveActionSetWithName:name completionHandler:^(NSError *error) {
        self.saveButton.enabled = YES;
        if (error) {
            [self hmc_displayError:error];
        } else {
            [self dismiss];
        }
    }];
}

- (void)home:(HMHome *)home didRemoveAccessory:(HMAccessory *)accessory {
    [self.tableView reloadData];
}

- (void)home:(HMHome *)home didAddAccessory:(HMAccessory *)accessory {
    [self.tableView reloadData];
}

@end
