/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller displays all reminders whose due date was within the last 7 days.
            It shows the title, due date, frequency, and priority of each reminder using EKReminder's title, dueDateComponents, and priority properties
            and EKRecurrenceRule, respectively. It also allows you to mark a reminder as completed.
 */

#import "CustomCell.h"
#import "EKRSConstants.h"
#import "EKRSHelperClass.h"
#import "PastDueReminders.h"
#import "TimedReminderStore.h"
#import "EKRSReminderStoreUtilities.h"


// Cell identifier
static NSString *EKTRPastDueRemindersCellID = @"pastDueCellID";

@interface PastDueReminders ()
// Keep track of all past-due reminders
@property (nonatomic, strong) NSMutableArray *pastDue;
@end


@implementation PastDueReminders

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // Register for TimedTabBarController notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleTTBPastDueRemindersNotification:)
                                                     name:TTBPastDueRemindersNotification
                                                   object:nil];
        
        _pastDue = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}


#pragma mark - Handle TimedTabBarController Notification

// Update the UI
-(void)handleTTBPastDueRemindersNotification:(NSNotification *)notification
{
    self.pastDue = [TimedReminderStore sharedInstance].pastDueReminders;
    [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.pastDue.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    EKReminder *reminder = (self.pastDue)[indexPath.row];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    // Fetch the date by which this reminder should be completed
    NSDate *date = [gregorian dateFromComponents:reminder.dueDateComponents];
    NSString *formattedDateString = [[EKRSHelperClass dateFormatter] stringFromDate:date];
    
    // Fetch the recurrence rule
    NSArray *recurrence = reminder.recurrenceRules;
    EKRecurrenceRule *rule = recurrence.firstObject;
    
    // Create a string comprising of the date and frequency
    NSString *dateAndFrequency = (recurrence.count > 0) ? [NSString stringWithFormat:@"%@, %@",formattedDateString,[rule nameMatchingFrequency:rule.frequency]] : [NSString stringWithFormat:@"%@",formattedDateString];
    
    CustomCell *myCell = (CustomCell *)cell;
    myCell.checkBox.checked = NO;
    myCell.title.text = reminder.title;
    myCell.dateAndFrequency.text = dateAndFrequency;
    myCell.priority.text = [reminder symbolMatchingPriority:reminder.priority];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:EKTRPastDueRemindersCellID];
}



#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Find the cell being touched
    CustomCell *targetCustomCell = (CustomCell *)[tableView cellForRowAtIndexPath:indexPath];
    // Add a checkmark for this reminder
    targetCustomCell.checkBox.checked = !targetCustomCell.checkBox.checked;
    // Let's mark the selected reminder as completed
    [self completeReminderIndexPath:indexPath];
}


#pragma mark - Managing Selections

- (IBAction)checkBoxTapped:(id)sender forEvent:(UIEvent *)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    
    // Lookup the index path of the cell whose checkbox was modified.
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:currentTouchPosition];
    
    if (indexPath != nil)
    {
        // Let's mark the selected reminder as completed
        [self completeReminderIndexPath:indexPath];
    }
}


// Call TimedReminderStore to mark the selected reminder as completed
-(void)completeReminderIndexPath:(NSIndexPath *)indexPath
{
    EKReminder *reminder = (self.pastDue)[indexPath.row];
    // Remove the selected reminder from the UI
    [self.pastDue removeObject:reminder];
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
    // Unregister for TimedTabBarController notification
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:TTBPastDueRemindersNotification
                                                  object:nil];
}

@end
