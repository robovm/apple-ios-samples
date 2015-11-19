/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller allows you to enter the title, priority, and alarm (time and frequency) information for a new reminder.
 */

#import "EKRSHelperClass.h"
#import "AddTimedReminder.h"
#import "RepeatViewController.h"


const NSInteger EKTRAddTimedReminderTitleTag = 10;      // View tag identifying the title cell
const NSInteger EKTRAddTimedReminderDatePickerTag = 11; // View tag identifying the date picker view
const NSInteger EKTRAddTimedReminderPriorityTag = 12;   // View tag identifying the priority segmented control

const NSInteger EKTRAddTimedReminderMeOnDateRow = 0;  // Index of row containing the "Remind me on" cell
const NSInteger EKTRAddTimedReminderNumberOfRowsWithDatePicker = 3;  // Number of rows when the date picker is shown
const NSInteger EKTRAddTimedReminderNumberOfRowsWithoutDatePicker = 2;  // Number of rows when the date picker is hidden

static NSString *EKTRAddTimedReminderTitleCellID = @"titleCellID"; // Cell containing the title
static NSString *EKTRAddTimedReminderDateCellID = @"dateCellID";     // Cell containing the start date
static NSString *EKTRAddTimedReminderDatePickerID = @"datePickerCellID"; // Cell containing the date picker view
static NSString *EKTRAddTimedReminderFrequencyCellID = @"frequencyCellID"; // Cell with the frequency
static NSString *EKTRAddTimedReminderPriorityCellID = @"priorityCellID"; // Cell containing the priority segmented control

static NSString *EKTRAddTimedReminderAlarmSection = @"ALARM";
static NSString *EKTRAddTimedReminderPrioritySection = @"PRIORITY";

static NSString *EKTRAddTimedReminderShowSegue = @"showRepeatViewController";
static NSString *EKTRAddTimedReminderUnwindSegue = @"unwindToReminders";


@interface AddTimedReminder () <UITextFieldDelegate>
@property (nonatomic, copy) NSDate *displayedDate;
// Height of the date picker view
@property (assign) NSInteger pickerCellRowHeight;
// keep track of which indexPath points to the cell with UIDatePicker
@property (nonatomic, strong) NSIndexPath *datePickerIndexPath;

@end


@implementation AddTimedReminder

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.displayedDate = [NSDate date];
    UITableViewCell *pickerViewCellToCheck = [self.tableView dequeueReusableCellWithIdentifier:EKTRAddTimedReminderDatePickerID];
    self.pickerCellRowHeight = pickerViewCellToCheck.frame.size.height;
}


#pragma mark - Handle User Text Input

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    UITableViewCell *titleCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITextField *myTextField = (UITextField *)[titleCell viewWithTag:EKTRAddTimedReminderTitleTag];
    
    // When the user presses return, take focus away from the text field so that the keyboard is dismissed.
    if (textField == myTextField)
    {
        [textField resignFirstResponder];
    }
    // Enable the Done button if and only if the user has entered a title for the reminder
    if (myTextField.text.length > 0)
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    return YES;
}


#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  ([self indexPathHasPicker:indexPath] && (indexPath.section == 1))? self.pickerCellRowHeight : self.tableView.rowHeight;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 3;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionHeaderTitle = nil;
    switch (section)
    {
        case 1:
            sectionHeaderTitle = EKTRAddTimedReminderAlarmSection;
            break;
        case 2:
            sectionHeaderTitle = EKTRAddTimedReminderPrioritySection;
            
        default:
            break;
    }
    return sectionHeaderTitle;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 1;
    if (section == 1)
    {
        // Show 3 rows if the date picker is shown and 2, otherwise
        numberOfRows = ([self hasInlineDatePicker])? EKTRAddTimedReminderNumberOfRowsWithDatePicker: EKTRAddTimedReminderNumberOfRowsWithoutDatePicker;
    }
    // Return the number of rows in the section
    return numberOfRows;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == 1) && [self indexPathHasDate:indexPath])
    {
        cell.detailTextLabel.text = [[EKRSHelperClass dateFormatter] stringFromDate:self.displayedDate];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellID = nil;
    switch (indexPath.section)
    {
        case 0:
            cellID = EKTRAddTimedReminderTitleCellID;
            break;
        case 1:
        {
            if ([self indexPathHasPicker:indexPath])
            {
                cellID = EKTRAddTimedReminderDatePickerID;
            }
            else if ([self indexPathHasDate:indexPath])
            {
                cellID = EKTRAddTimedReminderDateCellID;
            }
            else
            {
                cellID = EKTRAddTimedReminderFrequencyCellID;
            }
        }
            break;
        case 2:
            cellID = EKTRAddTimedReminderPriorityCellID;
            break;
            
        default:
            break;
    }
    
    return [tableView dequeueReusableCellWithIdentifier:cellID];;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.reuseIdentifier == EKTRAddTimedReminderDateCellID)
    {
        [self displayDatePickerInlineForRowAtIndexPath:indexPath];
    }
}


#pragma mark - Handle Date Picker

// Determines if the UITableViewController has a UIDatePicker in any of its cells.
- (BOOL)hasInlineDatePicker
{
    return (self.datePickerIndexPath != nil);
}


// Determines if the given indexPath points to a cell that contains the UIDatePicker.
- (BOOL)indexPathHasPicker:(NSIndexPath *)indexPath
{
    return ([self hasInlineDatePicker] && self.datePickerIndexPath.row == indexPath.row);
}


// Determines if the given indexPath points to a cell that contains the start/end dates.
- (BOOL)indexPathHasDate:(NSIndexPath *)indexPath
{
    BOOL hasDate = NO;
    
    if ((indexPath.row == EKTRAddTimedReminderMeOnDateRow))
    {
        hasDate = YES;
    }
    return hasDate;
}


// Reveals the date picker inline for the given indexPath, called by "didSelectRowAtIndexPath"
-(void)displayDatePickerInlineForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView beginUpdates];
    
    // Show the picker if date cell was selected and picker is not shown
    if ([self hasInlineDatePicker])
    {
        [self hideDatePickerAtIndexPath:indexPath];
        self.datePickerIndexPath = nil;
    }
    // Hide the picker if date cell was selected and picker is shown
    else
    {
        [self addDatePickerAtIndexPath:indexPath];
        self.datePickerIndexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:1];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.tableView endUpdates];
    [self updateDatePicker];
}


// Add the date picker view to the UI
-(void)addDatePickerAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row+1 inSection:1]];
    [self.tableView insertRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationFade];
}


// Remove the date picker view to the UI
-(void)hideDatePickerAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row+1 inSection:1]];
    [self.tableView deleteRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationFade];
}


// Update the UIDatePicker's value to match with the date of the cell above it
- (void)updateDatePicker
{
    if (self.datePickerIndexPath != nil)
    {
        UITableViewCell *datePickerCell = [self.tableView cellForRowAtIndexPath:self.datePickerIndexPath];
        
        UIDatePicker *datePicker = (UIDatePicker *)[datePickerCell viewWithTag:EKTRAddTimedReminderDatePickerTag];
        if (datePicker != nil)
        {
            datePicker.date = self.displayedDate;
        }
    }
}


// Called when the user selects a date from the date picker view. Update the displayed date.
- (IBAction)datePickerValueChanged:(id)sender
{
    if ([self hasInlineDatePicker])
    {
        NSIndexPath *dateCellIndexPath = [NSIndexPath indexPathForRow:self.datePickerIndexPath.row-1 inSection:1];
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:dateCellIndexPath];
        UIDatePicker *datePicker = (UIDatePicker *)sender;
        // Update the displayed date
        cell.detailTextLabel.text = [[EKRSHelperClass dateFormatter] stringFromDate:datePicker.date];
        self.displayedDate = datePicker.date;
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:EKTRAddTimedReminderShowSegue])
    {
        RepeatViewController *repeatViewController = (RepeatViewController *)segue.destinationViewController;
        UITableViewCell *frequencyCell = nil;
        
        if ([self hasInlineDatePicker])
        {
            frequencyCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
        }
        else
        {
            frequencyCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
        }
        
        repeatViewController.displayedFrequency = frequencyCell.detailTextLabel.text;
    }
    else if ([segue.identifier isEqualToString:EKTRAddTimedReminderUnwindSegue])
    {
        UITableViewCell *titleCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        UITextField *textField = (UITextField *)[titleCell viewWithTag:EKTRAddTimedReminderTitleTag];
        
        
        UITableViewCell *dateCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        NSDate *date = [[EKRSHelperClass dateFormatter] dateFromString:dateCell.detailTextLabel.text];
        
        
        UITableViewCell *frequencyCell = nil;
        if ([self hasInlineDatePicker])
        {
            frequencyCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
        }
        else
        {
            frequencyCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
        }
        
        UITableViewCell *priorityCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
        UISegmentedControl *prioritySegmentControl = (UISegmentedControl *)[priorityCell viewWithTag:EKTRAddTimedReminderPriorityTag];
        NSString *priority = [prioritySegmentControl titleForSegmentAtIndex:prioritySegmentControl.selectedSegmentIndex];
        
        
        
        self.reminder = [[TimedReminder alloc] initWithTitle:textField.text
                                                   startDate:date
                                                   frequency:frequencyCell.detailTextLabel.text
                                                    priority:priority];
    }
}


// Unwind action from the Repeat view controller
- (IBAction)unwindToAddTimedReminders:(UIStoryboardSegue*)sender
{
    RepeatViewController *repeatViewController = (RepeatViewController *)sender.sourceViewController;
    UITableViewCell *frequencyCell = nil;
    
    // The frequency cell is at row 2 when the date picker is shown and at row 1, otherwise
    if ([self hasInlineDatePicker])
    {
        frequencyCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
    }
    else
    {
        frequencyCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    }
    // Display the frequency value
    frequencyCell.detailTextLabel.text = repeatViewController.displayedFrequency;
}


#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
