/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller displays all completed reminders. It shows the title and completion date of each reminder
            using EKReminder's title and completionDate properties and calls TimedReminderStore to remove reminders.
 */

#import "CustomCell.h"
#import "EKRSConstants.h"
#import "EKRSHelperClass.h"
#import "CompletedReminders.h"
#import "TimedReminderStore.h"
#import "TimedTabBarController.h"


// Cell identifier
static NSString * EKTRCompletedRemindersCellID = @"completedCellID";

@interface CompletedReminders ()
// Keep track of all completed reminders
@property (nonatomic, strong) NSMutableArray *completed;

@end



@implementation CompletedReminders

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // Register for TimedTabBarController notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleTTBCompletedRemindersNotification:)
                                                     name:TTBCompletedRemindersNotification
                                                   object:nil];
        
        _completed = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.toolbarItems = @[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Delete All", nil) style:UIBarButtonItemStylePlain target:self action:@selector(deleteAll:)]];
}


-(void)showOrHideEditButton
{
    // Show the Edit button if there are complete timed-based reminders and hide it, otherwise.
    self.navigationItem.leftBarButtonItem = (self.completed.count > 0) ? self.editButtonItem : nil;
}


- (void)deleteAll:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:NSLocalizedString(@"Are you sure you want to remove all these reminders?", nil)
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         for (EKReminder *reminder in self.completed)
                                                         {
                                                             [[TimedReminderStore sharedInstance] remove:reminder];
                                                         }
                                                         
                                                         [self.tableView reloadData];
                                                         [self setEditing:NO animated:YES];
                                                     }];
    [alert addAction:OKAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - Handle TimedTabBarController Notification

// Refresh the UI with complete timed-based reminders and enable the Edit button
-(void)handleTTBCompletedRemindersNotification:(NSNotification *)notification
{
    NSMutableArray *result = [NSMutableArray arrayWithArray:[TimedReminderStore sharedInstance].completedReminders];
    if (![self.completed isEqualToArray:result])
    {
        self.completed = result;
        [self.tableView reloadData];
        [self showOrHideEditButton];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.completed.count;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    EKReminder *reminder = (self.completed)[indexPath.row];
    
    // Display the reminder's title
    cell.textLabel.text = reminder.title;
    // Display the reminder's completion date
    cell.detailTextLabel.text = [[EKRSHelperClass dateFormatter] stringFromDate:reminder.completionDate];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:EKTRCompletedRemindersCellID forIndexPath:indexPath];
}


// Used to delete a reminder
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        EKReminder *reminder = (self.completed)[indexPath.row];
        
        // Remove the selected reminder from the UI
        [self.completed removeObject:reminder];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        // Called to remove the selected reminder from event store
        [[TimedReminderStore sharedInstance] remove:reminder];
    }
}


#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}


#pragma mark - UITableView

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    // Remove the Edit button if there are no reminders
    if (self.completed.count == 0)
    {
        self.navigationItem.leftBarButtonItem = nil;
    }
    self.navigationController.toolbarHidden = !editing;
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
                                                    name:TTBCompletedRemindersNotification
                                                  object:nil];
}

@end
