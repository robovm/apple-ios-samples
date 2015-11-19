/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller allows you to select a recurrence frequency for a reminder, which is Never, Daily, Weekly, Biweekly, Monthly, or Yearly.
            It passes the selected frequency to the AddTimedReminder view controller via the prepareForSegue:sender: method.
 */

#import "EKRSConstants.h"
#import "RepeatViewController.h"

static NSString *EKTRFrequenciesListExtension = @"plist";
static NSString *EKTRFrequenciesList = @"FrequenciesList";

// Cell identifier
static NSString *EKTRRepeatViewControllerCellID = @"frequencyCellID";


@interface RepeatViewController ()
@property (nonatomic, strong) NSArray *frequencies;
@property (nonatomic, strong) NSDictionary *currentFrequencyOption;

@end

@implementation RepeatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Fetch all frequency and description values
    NSURL *plistURL = [[NSBundle mainBundle] URLForResource:EKTRFrequenciesList withExtension:EKTRFrequenciesListExtension];
    self.frequencies = [NSArray arrayWithContentsOfURL:plistURL];
}


#pragma mark - Utilities

// Return the description matching a given frequency's title
-(NSString *)descriptionMatchingTitle:(NSString *)title
{
    NSString *description = nil;
    for (NSDictionary *dictionary in self.frequencies)
    {
        if ([dictionary[EKRSTitle] isEqualToString:title])
        {
            description = dictionary[EKRSDescription];
        }
    }
    return description;
}


// Return the frequency's title matching a given description
-(NSString *)titleMatchingDescription:(NSString *)description
{
    NSString *title = nil;
    for (NSDictionary *dictionary in self.frequencies)
    {
        if ([dictionary[EKRSDescription] isEqualToString:description])
        {
            title = dictionary[EKRSTitle];
        }
    }
    return title;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.frequencies.count;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dictionary = (self.frequencies)[indexPath.row];
    
    // Add a checkmark for the selected row
    if ([dictionary[EKRSTitle] isEqualToString:self.displayedFrequency])
    {
        self.currentFrequencyOption = dictionary;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    cell.textLabel.text = dictionary[EKRSDescription];
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:EKTRRepeatViewControllerCellID forIndexPath:indexPath];;
}



#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger indexOfDisplayedFrequency = [self.frequencies indexOfObject:self.currentFrequencyOption];
    
    // Check whether the same row was selected and return, if it was.
    if (indexOfDisplayedFrequency == indexPath.row)
    {
        return;
    }
    
    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:indexOfDisplayedFrequency inSection:0];
    
    UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
    if (newCell.accessoryType == UITableViewCellAccessoryNone)
    {
        newCell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.currentFrequencyOption = (self.frequencies)[indexPath.row];
    }
    
    UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
    if (oldCell.accessoryType == UITableViewCellAccessoryCheckmark)
    {
        oldCell.accessoryType = UITableViewCellAccessoryNone;
    }
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Fetch the index for the current selected row
    NSIndexPath *indexPath = (self.tableView).indexPathForSelectedRow;
    // Update the displayed frequency with the one selected by the user
    self.displayedFrequency = [(self.frequencies)[indexPath.row] valueForKeyPath:EKRSTitle];
}


#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
