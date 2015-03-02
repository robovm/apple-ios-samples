/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A View Controller that creates Timer Triggers. It contains a Name field, a switch for enabling or disabling, 
  a list of Action Sets to add or remove from the trigger, a date picker for choosing a fire date, and a list of possible recurrence intervals.
 */

#import "TriggerViewController.h"
#import "UIViewController+Convenience.h"
#import "UITableView+Updating.h"

/**
 * @enum This is a thing.
 */
typedef NS_ENUM(NSUInteger, TriggerTableViewSection) {
    /**
     *  The Action Sets section.
     */
    TriggerTableViewSectionName = 0,
    /**
     *  The Enabled section.
     */
    TriggerTableViewSectionEnabled,
    /**
     *  The Action Sets section.
     */
    TriggerTableViewSectionActionSet,
    /**
     *  The Action Sets section.
     */
    TriggerTableViewSectionDate,
    /**
     *  The Schedule section.
     */
    TriggerTableViewSectionRecurrence
};

static NSString *TriggerRecurrenceTitleEveryHour;
static NSString *TriggerRecurrenceTitleEveryDay;
static NSString *TriggerRecurrenceTitleEveryWeek;

@interface TriggerViewController ()

// Save the date that the user picked in the date picker.
@property (nonatomic) NSDate *fireDate;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UITextField *nameField;

// Keep track of which action sets the user has selected
// in order to add the right ones when we finalize the trigger.
@property (nonatomic) NSMutableArray *selectedActionSets;

@property (weak, nonatomic) IBOutlet UISwitch *enabledSwitch;

// Maintain a list of titles, for order, and then map them to the corresponding NSCalendarUnits.
@property (nonatomic) NSArray *recurrenceTitles;
@property (nonatomic) NSArray *recurrenceComponents;
@property (nonatomic) NSUInteger selectedRecurrenceIndex;

// Save a dispatch_group that we can use to verify that all dispatched tasks are completed.
@property (nonatomic) dispatch_group_t saveTriggerGroup;

@property (nonatomic) BOOL didEncounterError;

@end

@implementation TriggerViewController

+ (void)initialize {
    TriggerRecurrenceTitleEveryHour = NSLocalizedString(@"Every Hour", @"Every Hour");
    TriggerRecurrenceTitleEveryDay = NSLocalizedString(@"Every Day", @"Every Day");
    TriggerRecurrenceTitleEveryWeek = NSLocalizedString(@"Every Week", @"Every Week");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0;

    // Store the possible recurrences in an array, to maintain order.
    self.recurrenceTitles = @[TriggerRecurrenceTitleEveryHour,
                              TriggerRecurrenceTitleEveryDay,
                              TriggerRecurrenceTitleEveryWeek];
    self.recurrenceComponents = @[@(NSCalendarUnitHour),
                                  @(NSCalendarUnitDay),
                                  @(NSCalendarUnitWeekOfYear)];

    self.didEncounterError = NO;

    // If we have a trigger, set the saved properties to the current properties
    // of the passed-in trigger.
    if (self.trigger) {
        self.fireDate = self.trigger.fireDate;
        self.selectedActionSets = self.trigger.actionSets.mutableCopy;
        self.selectedRecurrenceIndex = [self recurrenceIndexFromDateComponents:self.trigger.recurrence];
        self.nameField.text = self.trigger.name;
        self.enabledSwitch.on = self.trigger.enabled;
    // Otherwise create new properties.
    } else {
        self.fireDate = [NSDate date];
        self.selectedActionSets = [NSMutableArray array];
        self.selectedRecurrenceIndex = NSNotFound;
    }
    [self enableSaveButtonIfApplicable];

    // Create a dispatch group so we can properly wait for all of the individual
    // components of the saving process to finish before dismissing.
    self.saveTriggerGroup = dispatch_group_create();

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ActionSetCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"RecurrenceCell"];
}

/**
 *  Tries to find a new trigger matching our current one.
 *  If it exists, replace our saved one and reload the table.
 */
- (void)homeStoreDidUpdateHomes {
    for (HMTimerTrigger *trigger in self.home.triggers) {
        if ([trigger.name isEqualToString:self.trigger.name]) {
            self.trigger = trigger;
        }
    }
    [super homeStoreDidUpdateHomes];
}

/**
 *  Sets the stored fireDate to the new value.
 *  HomeKit only accepts dates aligned with minute boundaries,
 *  so we use NSDateComponents to only get the appropriate pieces of information from that date.
 *  Eventually we will end up with a date following this format: "MM/dd/yyyy hh:mm"
 *
 *  @param fireDate The new initial date to fire this trigger.
 */
- (void)setFireDate:(NSDate *)fireDate {
    unsigned flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfYear | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:flags fromDate:fireDate];
    _fireDate = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
    self.datePicker.date = _fireDate;
}

- (void)hmc_displayError:(NSError *)error {
    [super hmc_displayError:error];
    self.didEncounterError = YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case TriggerTableViewSectionActionSet:
            return self.home.actionSets.count;
        case TriggerTableViewSectionRecurrence:
            return self.recurrenceTitles.count;
        default:
            return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case TriggerTableViewSectionActionSet:
            return [self tableView:tableView actionSetCellForRowAtIndexPath:indexPath];
        case TriggerTableViewSectionRecurrence:
            return [self tableView:tableView recurrenceCellForRowAtIndexPath:indexPath];
        default:
            return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

/**
 *  Creates a cell that represents either a selected or unselected action set cell.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView actionSetCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionSetCell" forIndexPath:indexPath];
    HMActionSet *actionSet = self.home.actionSets[indexPath.row];
    if ([self.selectedActionSets containsObject:actionSet]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.textLabel.text = actionSet.name;
    return cell;
}

/**
 *  Creates a cell that represents a recurrence type.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView recurrenceCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RecurrenceCell" forIndexPath:indexPath];
    NSString *title = self.recurrenceTitles[indexPath.row];
    cell.textLabel.text = title;

    // The current preferred recurrence style should have a check mark.
    if (indexPath.row == self.selectedRecurrenceIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

/**
 *  Tell the tableView to automatically size the custom rows, while using the superclass's
 *  static sizing for the static cells.
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case TriggerTableViewSectionActionSet:
        case TriggerTableViewSectionRecurrence:
            return UITableViewAutomaticDimension;
        default:
            return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

/**
 *  This is necessary for mixing static and dynamic table view cells.
 *  We return a fake index path because otherwise the superclass's implementation (which does not
 *  know about the extra cells we're adding) will cause an error.
 * 
 *  @return The superclass's indentationLevel for the first row in the provided section,
 *          instead of the provided row.
 */
- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
    return [super tableView:tableView indentationLevelForRowAtIndexPath:newIndexPath];
}

/**
 *  Any time the name field changed, reevaluate whether or not
 *  to enable the save button.
 */
- (IBAction)nameFieldDidChange:(UITextField *)sender {
    [self enableSaveButtonIfApplicable];
}

/**
 *  Enables the save button if:
 *
 *     1. The name field is not empty, and
 *     2. There will be at least one action set in the trigger after saving.
 */
- (void)enableSaveButtonIfApplicable {
    self.saveButton.enabled = [self trimmedName].length > 0 &&
                              (self.selectedActionSets.count > 0 || self.trigger.actionSets.count > 0);
}

- (NSString *)trimmedName {
    return [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/**
 *  Creates an NSDateComponent for the selected recurrence type.
 *
 *  @return An NSDateComponent where either <code>weekOfYear</code>,
 *          <code>hour</code>, or <code>day</code> is set to 1.
 */
- (NSDateComponents *)recurrenceComponentsForSelectedIndex {
    if (self.selectedRecurrenceIndex == NSNotFound) {
        return nil;
    }
    NSDateComponents *recurrenceComponents = [NSDateComponents new];
    NSCalendarUnit unit = [self.recurrenceComponents[self.selectedRecurrenceIndex] unsignedIntegerValue];
    switch (unit) {
        case NSCalendarUnitWeekOfYear:
            recurrenceComponents.weekOfYear = 1;
            break;
        case NSCalendarUnitHour:
            recurrenceComponents.hour = 1;
            break;
        case NSCalendarUnitDay:
            recurrenceComponents.day = 1;
            break;
        default:
            break;
    }
    return recurrenceComponents;
}

// Map the possible calendar units associated with recurrence titles, so we can properly
// set our recurrenceUnit when the user selects a cell.
- (NSUInteger)recurrenceIndexFromDateComponents:(NSDateComponents *)components {
    NSNumber *unit = nil;
    if (components.day == 1) {
        unit = @(NSCalendarUnitDay);
    } else if (components.weekOfYear == 1) {
        unit = @(NSCalendarUnitWeekOfYear);
    } else if (components.hour == 1) {
        unit = @(NSCalendarUnitHour);
    }
    return [self.recurrenceComponents indexOfObject:unit];
}

- (IBAction)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 *  Saves the trigger and dismisses this view controller.
 */
- (IBAction)saveAndDismiss {
    self.saveButton.enabled = NO;
    [self saveTrigger];
    dispatch_group_notify(self.saveTriggerGroup, dispatch_get_main_queue(), ^{
        self.saveButton.enabled = YES;
        if (self.didEncounterError) {
            self.didEncounterError = NO;
        } else {
            [self enableTrigger:self.trigger completionHandler:^{
                [self dismiss];
            }];
        }
    });
}

/**
 *  Creates a trigger from the data that's been selected in this view controller.
 *
 *  Specifically, creates a trigger with self.fireDate and self.recurrenceUnit (if one is selected),
 *  and adds the actions in self.actionSetsToAdd.
 *
 * @see <code> addActionSetsToTrigger:</code>
 */
- (void)saveTrigger {
    NSDateComponents *recurrenceComponents = [self recurrenceComponentsForSelectedIndex];
    NSString *name = [self trimmedName];
    NSDate *date = self.fireDate;

    if (self.trigger) {
        [self addTriggerToHomeIfNecessary:self.trigger];
        [self updateFireDateIfNecessary:date];
        [self updateRecurrenceIfNecessary:recurrenceComponents];
        [self updateNameIfNecessary:name];
    } else {
        [self createAndAddTriggerWithName:name
                                 fireDate:date
                     recurrenceComponents:recurrenceComponents];
    }
}

/**
 *  Updates the trigger's name, entering and leaving the dispatch group if necessary.
 *  If the trigger's name is already equal to the passed-in name, this method does nothing.
 *
 *  @param name The trigger's new name.
 */
- (void)updateNameIfNecessary:(NSString *)name {
    if ([self.trigger.name isEqualToString:name]) {
        return;
    }
    dispatch_group_enter(self.saveTriggerGroup);
    [self.trigger updateName:name completionHandler:^(NSError *error) {
        if (error) {
            [self hmc_displayError:error];
        }
        dispatch_group_leave(self.saveTriggerGroup);
    }];
}

/**
 *  Updates the trigger's fire date, entering and leaving the dispatch group if necessary.
 *  If the trigger's fire date is already equal to the passed-in fire date, this method does nothing.
 *
 *  @param fireDate The trigger's new fire date.
 */
- (void)updateFireDateIfNecessary:(NSDate *)fireDate {
    if ([self.trigger.fireDate isEqualToDate:fireDate]) {
        return;
    }
    dispatch_group_enter(self.saveTriggerGroup);
    [self.trigger updateFireDate:fireDate completionHandler:^(NSError *error) {
        if (error) {
            [self hmc_displayError:error];
        }
        dispatch_group_leave(self.saveTriggerGroup);
    }];
}

/**
 *  Updates the trigger's recurrence components, entering and leaving the dispatch group if necessary.
 *  If the trigger's components are already equal to the passed-in components, this method does nothing.
 *
 *  @param recurrenceComponents The trigger's new recurrence components.
 */
- (void)updateRecurrenceIfNecessary:(NSDateComponents *)recurrenceComponents {
    if ([recurrenceComponents isEqual:self.trigger.recurrence]) {
        return;
    }
    dispatch_group_enter(self.saveTriggerGroup);
    [self.trigger updateRecurrence:recurrenceComponents completionHandler:^(NSError *error) {
        if (error) {
            [self hmc_displayError:error];
        }
        dispatch_group_leave(self.saveTriggerGroup);
    }];
}

/**
 *  Creates a trigger with all of the passed-in parameters and adds it to the home, entering and
 *  leaving the dispatch group.
 *
 *  @param name                 The new trigger's name.
 *  @param fireDate             The new trigger's first fire date.
 *  @param recurrenceComponents The new trigger's recurrence components.
 */
- (void)createAndAddTriggerWithName:(NSString *)name fireDate:(NSDate *)fireDate recurrenceComponents:(NSDateComponents *)recurrenceComponents {
    self.trigger = [[HMTimerTrigger alloc] initWithName:name
                                               fireDate:fireDate
                                               timeZone:nil
                                             recurrence:recurrenceComponents
                                     recurrenceCalendar:nil];
    [self addTriggerToHomeIfNecessary:self.trigger];
}

- (void)addTriggerToHomeIfNecessary:(HMTrigger *)trigger {
    if ([self.home.triggers containsObject:trigger]) {
        [self addActionSetsToTrigger];
    } else {
        dispatch_group_enter(self.saveTriggerGroup);
        __weak typeof(self) weakSelf = self;
        [self.home addTrigger:self.trigger completionHandler:^(NSError *error) {
            if (error) {
                [weakSelf hmc_displayError:error];
            } else {
                [weakSelf addActionSetsToTrigger];
            }
            dispatch_group_leave(weakSelf.saveTriggerGroup);
        }];
    }
}

/**
 *  Adds the contents of self.selectedActionSets to the trigger and enables it.
 *
 *  @param trigger The trigger to which to add action sets.
 */
- (void)addActionSetsToTrigger {

    // Save a standard completion handler to use when
    // we either add or remove an action set.
    void (^defaultCompletion)(NSError *) = ^(NSError *error) {
        // Leave the dispatch group, to notify that we've finished this task.
        if (error) {
            [self hmc_displayError:error];
        }
        dispatch_group_leave(self.saveTriggerGroup);
    };

    // First pass, remove the action sets that have been deselected.
    for (HMActionSet *actionSet in self.trigger.actionSets) {
        if ([self.selectedActionSets containsObject:actionSet]) {
            continue;
        }
        dispatch_group_enter(self.saveTriggerGroup);
        [self.trigger removeActionSet:actionSet completionHandler:defaultCompletion];
    }

    // Second pass, add the new action sets that were just selected.
    for (HMActionSet *actionSet in self.selectedActionSets) {
        if ([self.trigger.actionSets containsObject:actionSet]) {
            continue;
        }
        dispatch_group_enter(self.saveTriggerGroup);
        [self.trigger addActionSet:actionSet completionHandler:defaultCompletion];
    }
}

/**
 *  Enable the trigger if necessary.
 */
- (void)enableTrigger:(HMTrigger *)trigger completionHandler:(void (^)())completion {
    if (trigger.enabled == self.enabledSwitch.on) {
        completion();
        return;
    }
    [trigger enable:self.enabledSwitch.on completionHandler:^(NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            return;
        }
        completion();
    }];
}

/**
 *  Reset our saved fire date to the date in the picker.
 */
- (IBAction)didChangeDate:(UIDatePicker *)picker {
    self.fireDate = picker.date;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case TriggerTableViewSectionActionSet:
            [self tableView:tableView didSelectActionSetAtIndexPath:indexPath];
            break;
        case TriggerTableViewSectionRecurrence:
            [self tableView:tableView didSelectRecurrenceComponentAtIndexPath:indexPath];
            break;
        default:
            break;
    }
}

/**
 *  Handle selection of an action set cell. If the action set is already part of the selected action sets,
 *  then remove it from the selected list. Otherwise, add it to the selected list.
 */
- (void)tableView:(UITableView *)tableView didSelectActionSetAtIndexPath:(NSIndexPath *)indexPath {
    HMActionSet *actionSet = self.home.actionSets[indexPath.row];
    if ([self.selectedActionSets containsObject:actionSet]) {
        [self.selectedActionSets removeObject:actionSet];
    } else {
        [self.selectedActionSets addObject:actionSet];
    }
    [self enableSaveButtonIfApplicable];
    [tableView hmc_update:^(UITableView *tableView) {
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

/**
 *  Handles selection of a recurrence cell. If the newly selected recurrence component is the 
 *  previously selected recurrence component, reset the current selected component to <code>NSNotFound</code>
 *  and deselect that row.
 */
- (void)tableView:(UITableView *)tableView didSelectRecurrenceComponentAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *indexPaths = @[indexPath].mutableCopy;
    if (indexPath.row == self.selectedRecurrenceIndex) {
        self.selectedRecurrenceIndex = NSNotFound;
    } else {
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:self.selectedRecurrenceIndex inSection:TriggerTableViewSectionRecurrence];
        [indexPaths addObject:selectedIndexPath];
        self.selectedRecurrenceIndex = indexPath.row;
    }
    [tableView hmc_update:^(UITableView *tableView) {
        [tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

@end
