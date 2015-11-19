/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller manages the child view controllers: MapViewController and RemindersViewController.
     It calls LocationReminderStore to check access to the Reminders application.
 */


#import "EKRSConstants.h"
#import "EKRSHelperClass.h"
#import "LocationReminderStore.h"
#import "LocationTabBarController.h"


@interface LocationTabBarController ()
@property (nonatomic, strong) NSArray *rsObservers;

@end


@implementation LocationTabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    LocationTabBarController * __weak weakSelf = self;
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // Register for access granted and denied, refresh data, location, and failure notifications
    id accessGranted = [center addObserverForName:EKRSAccessGrantedNotification
                                           object:[LocationReminderStore sharedInstance]
                                            queue:mainQueue
                                       usingBlock:^(NSNotification *note) {
                                           [weakSelf handleEKRSAccessGrantedNotification:note];
                                       }];
    
    
    id accessDenied = [center addObserverForName:EKRSAccessDeniedNotification
                                          object:[LocationReminderStore sharedInstance]
                                           queue:mainQueue
                                      usingBlock:^(NSNotification *note) {
                                          [weakSelf handleEKRSAccessDeniedNotification:note];
                                          
                                      }];
    
    
    id refreshData = [center addObserverForName:EKRSRefreshDataNotification
                                         object:[LocationReminderStore sharedInstance]
                                          queue:mainQueue
                                     usingBlock:^(NSNotification *note) {
                                         [weakSelf handleEKRSRefreshDataNotification:note];
                                     }];
    
    id reminders = [center addObserverForName:EKRSLocationRemindersNotification
                                       object:[LocationReminderStore sharedInstance]
                                        queue:mainQueue
                                   usingBlock:^(NSNotification *note) {
                                       [weakSelf handleEKRSLocationRemindersNotification:note];
                                   }];
    
    id failure = [center addObserverForName:EKRSFailureNotification
                                     object:[LocationReminderStore sharedInstance]
                                      queue:mainQueue
                                 usingBlock:^(NSNotification *note){
                                     [weakSelf handleEKRSFailureNotification:note];
                                 }];
    
    // Keep track of our observers
    self.rsObservers = @[accessGranted, accessDenied, refreshData, reminders, failure];
    // Check whether EKLocationReminders has access to Reminders
    [[LocationReminderStore sharedInstance] checkEventStoreAuthorizationStatus];
}


#pragma mark - Handle Access Granted Notification

// Handle the EKRSAccessGrantedNotification notification
-(void)handleEKRSAccessGrantedNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:LTBAccessGrantedNotification object:self];
    [[LocationReminderStore sharedInstance] fetchLocationReminders];
}


#pragma mark - Handle Access Denied Notification

// Handle the EKRSAccessDeniedNotification notification
-(void)handleEKRSAccessDeniedNotification:(NSNotification *)notification
{
    UIAlertController *alert = [EKRSHelperClass alertWithTitle:NSLocalizedString(@"Privacy Warning", nil)
                                                       message:NSLocalizedString(@"Access was not granted for Reminders.", nil)];
    
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark - Handle Refresh Data Notification

// Handle the EKRSRefreshDataNotification notification
-(void)handleEKRSRefreshDataNotification:(NSNotification *)notification
{
    [[LocationReminderStore sharedInstance] fetchLocationReminders];
}


#pragma mark - Handle Failure Notification

// Handle the EKRSFailureNotification notification. Display the error message encountered
-(void)handleEKRSFailureNotification:(NSNotification *)notification
{
    LocationReminderStore *myNotification = (LocationReminderStore *)notification.object;
    [EKRSHelperClass alertWithTitle:NSLocalizedString(@"Status", nil)
                            message:myNotification.errorMessage];
}


#pragma mark - Handle Incomplete Reminders Notification

// Handle the EKRSLocationRemindersNotification notification
-(void)handleEKRSLocationRemindersNotification:(NSNotification *)notification
{
    LocationReminderStore *myNotification = (LocationReminderStore *)notification.object;
    
    // Update the number of the reminders in the tab bar
    ((self.tabBar.items)[1]).badgeValue = [NSString stringWithFormat:@"%lu",(unsigned long)myNotification.locationReminders.count];
    // Notify the listener that there are location reminders
    [[NSNotificationCenter defaultCenter] postNotificationName:LTBRemindersFetchedNotification
                                                        object:self];
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
        [[NSNotificationCenter defaultCenter] removeObserver: anObserver];
    }
}

@end
