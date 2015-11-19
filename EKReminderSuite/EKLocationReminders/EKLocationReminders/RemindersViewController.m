/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller displays incomplete location reminders if your app has access to Reminders.
            It uses the alarms and title properties of EKReminder and EKAlarm's proximity and structuredLocation
            ones to provide information about a reminder. Tap any reminder to remove it.
 */

#import "EKRSConstants.h"
#import "EKRSHelperClass.h"
#import "LocationReminderStore.h"
#import "RemindersViewController.h"
#import "LocationTabBarController.h"
#import "EKRSReminderStoreUtilities.h"

// Cell identifier
static NSString * EKLRRemindersCellID = @"remindersCellID";

@interface RemindersViewController ()
@property (nonatomic, strong) NSMutableArray *reminders;

@end

@implementation RemindersViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleLTBControllerNotification:)
                                                     name:LTBRemindersFetchedNotification
                                                   object:nil];
        
        _reminders = [[NSMutableArray alloc] initWithCapacity:0];
        
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.toolbarItems = @[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Delete All", nil) style:UIBarButtonItemStylePlain target:self action:@selector(deleteAll:)]];
}


- (void)deleteAll:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:NSLocalizedString(@"Are you sure you want to remove all these reminders?", nil)
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    UIAlertAction *OKAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         for (EKReminder *reminder in self.reminders)
                                                         {
                                                             [[LocationReminderStore sharedInstance] remove:reminder];
                                                         }
                                                         
                                                         [self.tableView reloadData];
                                                         [self setEditing:NO animated:YES];
                                                     }];
    [alert addAction:OKAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}


-(void)showOrHideEditButton
{
    // Show the Edit button if there are incomplete location-based reminders and hide it, otherwise.
    self.navigationItem.leftBarButtonItem = (self.reminders.count > 0) ? self.editButtonItem : nil;
}


#pragma mark - Handle LocationTabBarController Notification

-(void)handleLTBControllerNotification:(NSNotification *)notification
{
    NSMutableArray *result = [NSMutableArray arrayWithArray:[LocationReminderStore sharedInstance].locationReminders];
    
    // Refresh the UI
    if (![self.reminders isEqualToArray:result])
    {
        self.reminders = result;
        [self.tableView reloadData];
        [self showOrHideEditButton];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.reminders.count;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    EKReminder *reminder = (self.reminders)[indexPath.row];
    EKAlarm *alarm = [NSArray arrayWithArray:reminder.alarms].firstObject;
    
    NSString *proximity = [alarm nameMatchingProximity:alarm.proximity];
    double radius = (alarm.structuredLocation.radius)/kMeter;
    
    cell.textLabel.text = reminder.title;
    cell.detailTextLabel.text = (radius > 0) ? [NSString stringWithFormat:@"%@: within %.2f miles of %@",proximity,radius,alarm.structuredLocation.title] : [NSString stringWithFormat:@"%@: %@",proximity,alarm.structuredLocation.title];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:EKLRRemindersCellID forIndexPath:indexPath];
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        EKReminder *reminder = (self.reminders)[indexPath.row];
        
        [self.reminders removeObject:reminder];
        // Update the table view
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [[LocationReminderStore sharedInstance] remove:reminder];
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
    if (self.reminders.count == 0)
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
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:LTBRemindersFetchedNotification
                                                  object:nil];
}

@end
