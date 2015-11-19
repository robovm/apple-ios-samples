/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller displays all reminders whose due date is within the next 7 days.
            It shows the title, due date, priority, and frequency of each reminder using EKReminder's title,
            dueDateComponents, and priority properties and EKRecurrenceRule, respectively.
            It allows you to create a reminder and mark a reminder as completed.
 */

#import "CustomCell.h"
#import "EKRSConstants.h"
#import "EKRSHelperClass.h"
#import "AddTimedReminder.h"
#import "UpcomingReminders.h"
#import "TimedReminderStore.h"
#import "TimedTabBarController.h"
#import "EKRSReminderStoreUtilities.h"


// Cell identifier
static NSString *EKTRUpcomingRemindersCellID = @"upcomingCellID";


@interface UpcomingReminders ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
// Keep track of all upcoming reminders
@property (nonatomic, strong) NSMutableArray *upcoming;

@end


@implementation UpcomingReminders

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // Register for TimedTabBarController notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleTTBAccessGrantedNotification:)
                                                     name:TTBAccessGrantedNotification
                                                   object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleTTBUpcomingRemindersNotification:)
                                                     name:TTBUpcomingRemindersNotification
                                                   object:nil];
        
        _upcoming = [[NSMutableArray alloc] initWithCapacity:0];
        
    }
    return self;
}


#pragma mark - Handle TimedTabBarController Notifications

// Enable the addButton button when access was granted to Reminders
-(void)handleTTBAccessGrantedNotification:(NSNotification *)notification
{
    self.addButton.enabled = YES;
}


// Refresh the UI with all upcoming reminders
-(void)handleTTBUpcomingRemindersNotification:(NSNotification *)notification
{
    // Refresh the UI with all upcoming reminders
    self.upcoming = [TimedReminderStore sharedInstance].upcomingReminders;
    [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.upcoming.count;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    EKReminder *reminder = (self.upcoming)[indexPath.row];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    // Fetch the date by which the reminder should be completed
    NSDate *date = [gregorian dateFromComponents:reminder.dueDateComponents];
    NSString *formattedDateString = [[EKRSHelperClass dateFormatter] stringFromDate:date];
    NSString *frequency;
    
    // If the reminder is a recurring one, only show its first recurrence rule
    if (reminder.hasRecurrenceRules)
    {
        // Fetch all recurrence rules associated with this reminder
        NSArray *recurrencesRules = reminder.recurrenceRules;
        EKRecurrenceRule *rule = recurrencesRules.firstObject;
        frequency = [rule nameMatchingRecurrenceRuleWithFrequency:rule.frequency interval:rule.interval];
    }
    
    // Use the hasRecurrenceRules property to determine whether to show the recurrence pattern for this reminder
    NSString *dateAndFrequency = (reminder.hasRecurrenceRules) ? [NSString stringWithFormat:@"%@, %@",formattedDateString,frequency] : [NSString stringWithFormat:@"%@",formattedDateString];
    
    CustomCell *myCell = (CustomCell *)cell;
    
    myCell.checkBox.checked = NO;
    myCell.title.text = reminder.title;
    
    // Display the due date and frequency of the reminder
    myCell.dateAndFrequency.text = dateAndFrequency;
    
    // Show the reminder's priority
    myCell.priority.text = [reminder symbolMatchingPriority:reminder.priority];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (CustomCell *)[tableView dequeueReusableCellWithIdentifier:EKTRUpcomingRemindersCellID];
}


#pragma mark - UITableViewDelegate

// Called when tapping a reminder. Briefly select its checkbox, then remove this reminder.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Find the cell being touched
    CustomCell *targetCustomCell = (CustomCell *)[tableView cellForRowAtIndexPath:indexPath];
    // Add a checkmarck for this reminder
    targetCustomCell.checkBox.checked = !targetCustomCell.checkBox.checked;
    // Let's mark the selected reminder as completed
    [self completeReminderAtIndexPath:indexPath];
}



#pragma mark - Unwind Segues

// Called when tapping the Cancel button in the AddTimedReminder view controller
- (IBAction)cancel:(UIStoryboardSegue*)sender
{
}


// Called when tapping the Done button in the AddTimedReminder view controller
- (IBAction)done:(UIStoryboardSegue*)sender
{
    AddTimedReminder *addTimedReminder = (AddTimedReminder *)sender.sourceViewController;
    // Called to create a timed-based reminder
    [[TimedReminderStore sharedInstance] createTimedReminder:addTimedReminder.reminder];
}


#pragma mark - Managing Selections

// Called when tapping a checkbox. Briefly select it, then remove its associated reminder.
- (IBAction)checkBoxTapped:(id)sender forEvent:(UIEvent *)event
{
    NSSet *touches = event.allTouches;
    UITouch *touch = touches.anyObject;
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    
    // Lookup the index path of the cell whose checkbox was modified.
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:currentTouchPosition];
    
    if (indexPath != nil)
    {
        // Let's mark the selected reminder as completed
        [self completeReminderAtIndexPath:indexPath];
    }
}


// Call TimedReminderStore to mark the selected reminder as completed
-(void)completeReminderAtIndexPath:(NSIndexPath *)indexPath
{
    EKReminder *reminder = (self.upcoming)[indexPath.row];
    // Remove the selected reminder from the UI
    [self.upcoming removeObject:reminder];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    // Tell TimedReminderStore to mark the selected reminder as completed
    [[TimedReminderStore sharedInstance] complete:reminder];
}


#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    // Unregister for TimedTabBarController notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:TTBAccessGrantedNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:TTBUpcomingRemindersNotification
                                                  object:nil];
}

@end
