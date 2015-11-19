/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller manages the child view controllers: CompletedReminders, PastDueReminders and UpcomingReminders.
            It calls TimedReminderStore to check access to the Reminders application. It listens and handles TimedReminderStore notifications.
            It calls TimedReminderStore to fetch upcoming, past-due, and completed reminders. It notifies the UpcomingReminders, PastDueReminders,
            and CompletedReminders view controllers upon receiving their associated data.
 */

#import "EKRSConstants.h"
#import "EKRSHelperClass.h"
#import "TimedReminderStore.h"
#import "TimedTabBarController.h"


@interface TimedTabBarController ()
@property (nonatomic, strong) NSArray *rsObservers;

@end


@implementation TimedTabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    TimedTabBarController * __weak weakSelf = self;
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // Register for TimedReminderStore notifications
    id accessGranted = [center addObserverForName:EKRSAccessGrantedNotification
                                           object:[TimedReminderStore sharedInstance]
                                            queue:mainQueue
                                       usingBlock:^(NSNotification *note) {
                                           [weakSelf handleRSAccessGrantedNotification:note];
                                       }];
    
    
    id accessDenied = [center addObserverForName:EKRSAccessDeniedNotification
                                          object:[TimedReminderStore sharedInstance]
                                           queue:mainQueue
                                      usingBlock:^(NSNotification *note) {
                                          [weakSelf handleRSAccessDeniedNotification:note];
                                          
                                      }];
    
    
    id refreshData = [center addObserverForName:EKRSRefreshDataNotification
                                         object:[TimedReminderStore sharedInstance]
                                          queue:mainQueue
                                     usingBlock:^(NSNotification *note) {
                                         [weakSelf handleRSRefreshDataNotification:note];
                                     }];
    
    
    
    id upcoming = [center addObserverForName:EKRSUpcomingRemindersNotification
                                      object:[TimedReminderStore sharedInstance]
                                       queue:mainQueue
                                  usingBlock:^(NSNotification *note) {
                                      [weakSelf handleRSUpcomingRemindersNotification:note];
                                  }];
    
    
    id pastDue = [center addObserverForName:EKRSPastDueRemindersNotification
                                     object:[TimedReminderStore sharedInstance]
                                      queue:mainQueue
                                 usingBlock:^(NSNotification *note){
                                     
                                     [weakSelf handleRSPastDueRemindersNotification:note];
                                 }];
    
    id completed = [center addObserverForName:EKRSCompletedRemindersNotification
                                       object:[TimedReminderStore sharedInstance]
                                        queue:mainQueue
                                   usingBlock:^(NSNotification *note){
                                       [weakSelf handleRSCompletedRemindersNotification:note];
                                   }];
    
    id failure = [center addObserverForName:EKRSFailureNotification
                                     object:[TimedReminderStore sharedInstance]
                                      queue:mainQueue
                                 usingBlock:^(NSNotification *note){
                                     [weakSelf handleRSFailureNotification:note];
                                 }];
    
    // Keep track of all the created notifications
    self.rsObservers = @[accessGranted, accessDenied, refreshData, upcoming, pastDue, completed, failure];
    // Check whether EKTimedReminders has access to Reminders
    [[TimedReminderStore sharedInstance] checkEventStoreAuthorizationStatus];
}


#pragma mark - Handle Access Granted Notification

// Handle the RSAccessGrantedNotification notification
-(void)handleRSAccessGrantedNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TTBAccessGrantedNotification object:self];
    [self accessGrantedForReminders];
}


// Access was granted to Reminders. Fetch past-due, pending, and completed reminders
-(void)accessGrantedForReminders
{
    [[TimedReminderStore  sharedInstance] fetchUpcomingRemindersWithDueDate:[EKRSHelperClass dateByAddingDays:7]];
    [[TimedReminderStore  sharedInstance] fetchPastDueRemindersWithDateStarting:[EKRSHelperClass dateByAddingDays:-7]];
    
    [[TimedReminderStore  sharedInstance] fetchCompletedRemindersWithDueDateStarting:[EKRSHelperClass dateByAddingDays:-7]
                                                                              ending:[EKRSHelperClass dateByAddingDays:7]];
}


#pragma mark - Handle Access Denied Notification

// Handle the RSAccessDeniedNotification notification
-(void)handleRSAccessDeniedNotification:(NSNotification *)notification
{
    UIAlertController *alert = [EKRSHelperClass alertWithTitle:NSLocalizedString(@"Access Status", nil)
                                                       message:NSLocalizedString(@"Access was not granted for Reminders.", nil)];
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - Handle Refresh Data Notification

// Handle the RSRefreshDataNotification notification
-(void)handleRSRefreshDataNotification:(NSNotification *)notification
{
    [self accessGrantedForReminders];
}


#pragma mark - Handle Failure Notification

// Handle the RSFailureNotification notification.
// An error has occured. Display an alert with the error message.
-(void)handleRSFailureNotification:(NSNotification *)notification
{
    TimedReminderStore *myNotification = (TimedReminderStore *)notification.object;
    
    UIAlertController *alert = [EKRSHelperClass alertWithTitle:NSLocalizedString(@"Status", nil)
                                                       message:myNotification.errorMessage];
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - Handle Upcoming Reminders Notification

// Handle the RSUpcomingRemindersNotification notification
-(void)handleRSUpcomingRemindersNotification:(NSNotification *)notification
{
    TimedReminderStore *myNotification = (TimedReminderStore *) notification.object;
    
    // Update the number of upcoming reminders in the tab bar
    ((self.tabBar.items)[0]).badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)myNotification.upcomingReminders.count];
    // Notify the listener that there are past-due reminders
    [[NSNotificationCenter defaultCenter] postNotificationName:TTBUpcomingRemindersNotification object:self];
}


#pragma mark - Handle Past-Due Reminders Notification

// Handle the RSPastDueRemindersNotification notification
-(void)handleRSPastDueRemindersNotification:(NSNotification *)notification
{
    TimedReminderStore *myNotification = (TimedReminderStore *)notification.object;
    
    // Update the number of past-due reminders in the tab bar
    ((self.tabBar.items)[1]).badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)myNotification.pastDueReminders.count];
    // Notify the listener that there are past-due reminders
    [[NSNotificationCenter defaultCenter] postNotificationName:TTBPastDueRemindersNotification object:self];
}


#pragma mark - Handle Completed Reminders Notification

// Handle the RSCompletedRemindersNotification notification
-(void)handleRSCompletedRemindersNotification:(NSNotification *)notification
{
    TimedReminderStore *myNotification = (TimedReminderStore *)notification.object;
    
    // Update the number of completed reminders in the tab bar
    ((self.tabBar.items)[2]).badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)myNotification.completedReminders.count];
    // Notify the listener that there are completed reminders
    [[NSNotificationCenter defaultCenter] postNotificationName:TTBCompletedRemindersNotification object:self];
}



#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)dealloc
{
    // Unregister for all observers saved in rsObservers
    for (id anObserver in self.rsObservers)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:anObserver];
    }
}
@end
