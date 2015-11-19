/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 UIApplicationDelegate for this sample
 */

#import "APLAppDelegate.h"
#import "APLMainTableViewController.h"
#import "APLCloudManager.h"

@implementation APLAppDelegate

// The app delegate must implement the window @property
// from UIApplicationDelegate @protocol to use a main storyboard file.
//
@synthesize window;

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // for the sake of UIStateRestoration (we restore early in the launch process)
    // and
    // APLMainTableViewController may be loaded before we have a chance to setup our CloudManager object so create it earlier here
    //
    // create our cloud manager object responsible for all CloudKit operations
    _cloudManager = [[APLCloudManager alloc] init];
    
    // listen for user login token changes so we can refresh and reflect our UI based on user login
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(iCloudAccountAvailabilityChanged:)
                                                 name:NSUbiquityIdentityDidChangeNotification
                                               object:nil];
    return YES;
}

// If this app was not already running, yet we have an incoming notification arriving, then this method is called and passed info about that notification.
//
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Register for push notifications (from CloudKit)
    // Necessary to receive local or remove notifications.
    //
    // note: this will not work in the simulator
    // note: for this to work you need to enable push for this app ID in the Portal,
    //          create a cert for push, and generate a new provisioning profile.
    //
    // note: without registering, sound and badging won't show up for your app in: Settings -> Notifications -> <our app>,
    //          and you won't have permission to badge or show alerts.
    //
    // User permissions can later be adjuste in Settings -> Notifications -> <our app>
    //

    // To reset the Push Notifications Permissions Alert on iOS:
    //    1. Delete your app from the device.
    //    2. Turn the device off completely and turn it back on.
    //    3. Go to Settings > General > Date & Time: and set the date ahead a day or more.
    //    4. Turn the device off completely again and turn it back on.
    //
    UIUserNotificationSettings *notificationSettings =
        [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound
                                          categories:nil];
    [application registerUserNotificationSettings:notificationSettings];
    [application registerForRemoteNotifications];
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    //NSLog(@"CloudPhotos: Registered for Push notifications with token: %@\n", deviceToken);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    //NSLog(@"CloudPhotos: Push subscription failed\n%@", error);
}


#pragma mark - Utilities

- (APLMainTableViewController *)mainViewController
{
    UINavigationController *rootVC = (UINavigationController *)self.window.rootViewController;
    return (APLMainTableViewController *)rootVC.viewControllers[0];
}


#pragma mark - NSNotifications

- (void)iCloudAccountAvailabilityChanged:(NSNotification *)notif
{
    // the user signs out of iCloud (such as by turning off Documents & Data in Settings),
    // or
    // has signed back in:
    // so we need to refresh our UI, this will update our UI to reflect user login
    //
    [CloudManager updateUserLogin:^() {

        // always tell our main table (visible or not) to update based on account changes
        APLMainTableViewController *mainTableViewController = [self mainViewController];
        [mainTableViewController iCloudAccountAvailabilityChanged];
        
        // is the current visible view controller our detail vc?  If so, just ask for it to update
        UINavigationController *rootVC = (UINavigationController *)self.window.rootViewController;
        UIViewController *currentViewController = rootVC.visibleViewController;
        if ([currentViewController isKindOfClass:[APLDetailTableViewController class]])
        {
            // notify the detail view controller to update based on account changes
            [(APLDetailTableViewController *)currentViewController iCloudAccountAvailabilityChanged];
        }
    }];
}


#pragma mark - Push Notifications

// attempt to find the owner of that recordID from this CKQueryNotification and report it (for debugging purposes)
//
- (void)reportUserFromNotification:(CKQueryNotification *)queryNotification
{
    CKRecordID *recordID = [queryNotification recordID];
    
    // note you can't create a CKRecord from a CKQueryNotification, so we need to do a lookup instead
    [CloudManager fetchRecordWithID:recordID completionHandler:^(CKRecord *foundRecord, NSError *error) {
        
        if (foundRecord != nil)
        {
            // find out the user who affected this record
            [CloudManager fetchUserNameFromRecordID:foundRecord.creatorUserRecordID completionHandler:^(NSString *firstName, NSString *lastName) {
                
                NSString *userName = NSLocalizedString(@"Notif Unknown User Name", nil);
                if (firstName != nil && lastName != nil)
                {
                    userName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                }
                
                // we are only interested in the kPhotoTitle attribute
                //  (because we set the CKSubscription's CKNotificationInfo 'desiredKeys' when we subscribed earlier)
                NSDictionary *recordFields = [queryNotification recordFields];
                NSString *photoTitle = recordFields[[APLCloudManager PhotoTitleAttribute]];
                
                // here we can examine the title of the photo record without a query
                CKQueryNotificationReason reason = [queryNotification queryNotificationReason];
                NSString *baseMessage = nil;
                switch (reason)
                {
                    case CKQueryNotificationReasonRecordCreated:
                        baseMessage = NSLocalizedString(@"Photo Added Notif Message", nil);
                        break;
                        
                    case CKQueryNotificationReasonRecordUpdated:
                        baseMessage = NSLocalizedString(@"Photo Changed Notif Message", nil);
                        break;
                        
                    case CKQueryNotificationReasonRecordDeleted:
                        baseMessage = NSLocalizedString(@"Photo Removed Notif Message", nil);
                        break;
                }
                if (baseMessage != nil)
                {
                    NSString *message = [NSString stringWithFormat:baseMessage, photoTitle, userName];
                    NSLog(@"%@", message);
                }
            }];
        }
    }];
}

- (void)handlePush:(NSDictionary *)userInfo
{
    [CloudManager markNotificationsAsAlreadyRead];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
    {
        //NSLog(@"incoming push notification: app is active");
    }
    else if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        //NSLog(@"incoming push notification: app is the background");
    }
    
    CKNotification *cloudKitNotification = [CKNotification notificationFromRemoteNotificationDictionary:userInfo];
    CKNotificationType notifType = [cloudKitNotification notificationType];
    
    // for debugging:
    //CKNotificationID *notificationID = [cloudKitNotification notificationID];
    //NSString *containerIdentifier = [cloudKitNotification containerIdentifier];
    //NSLog(@"CloudPhotos: Push notification received: %@", [cloudKitNotification alertBody]);
    //NSLog(@"notifType = %ld, notifID = %@, containerID = %@", (long)notifType, notificationID, containerIdentifier);
    
    if (notifType == CKNotificationTypeQuery)
    {
        // a notification generated based on the conditions set forth in a subscription object (NSPredicate, in our case a "true" predicate)
        CKQueryNotification *queryNotification = (CKQueryNotification *)[CKNotification notificationFromRemoteNotificationDictionary:userInfo];
        
        // find out which photo was modified
        CKRecordID *recordID = [queryNotification recordID];

        // we are only interested in the kPhotoTitle attribute
        //  (because we set the CKSubscription's CKNotificationInfo 'desiredKeys' when we subscribed earlier)
        NSDictionary *recordFields = [queryNotification recordFields];
        NSString *photoTitle = recordFields[[APLCloudManager PhotoTitleAttribute]];
        
        // here we can examine the title of the photo record without a query
        CKQueryNotificationReason reason = [queryNotification queryNotificationReason];
        NSString *baseMessage;
        NSString *finalMessage;
        switch (reason)
        {
            case CKQueryNotificationReasonRecordCreated:
                baseMessage = NSLocalizedString(@"Photo Generic Added Notif Message", nil);
                break;
                
            case CKQueryNotificationReasonRecordUpdated:
                baseMessage = NSLocalizedString(@"Photo Generic Changed Notif Message", nil);
                break;
                
            case CKQueryNotificationReasonRecordDeleted:
                baseMessage = NSLocalizedString(@"Photo Generic Removed Notif Message", nil);
                break;
        }
        if (baseMessage != nil)
        {
            finalMessage = [NSString stringWithFormat:baseMessage, photoTitle];
            NSLog(@"%@", finalMessage);
        }
 
        UINavigationController *rootVC = (UINavigationController *)self.window.rootViewController;
        
        // always tell our main table (visible or not) to update for "any" kind incoming notification no mater the notification or what state we are in
        APLMainTableViewController *mainTableViewController = [self mainViewController];
        [mainTableViewController handlePushWithRecordID:recordID reason:reason];
        
        // is the current view controller our detail vc?  If so, just ask for it to update
        UIViewController *currentViewController = rootVC.visibleViewController;
        if ([currentViewController isKindOfClass:[APLDetailTableViewController class]])
        {
            // notify the detail view controller of this record change, but only if it's their record being viewed
            //
            if ([recordID isEqual:((APLDetailTableViewController *)currentViewController).record.recordID])
            {
                [(APLDetailTableViewController *)currentViewController handlePushWithRecordID:recordID
                                                                                       reason:reason
                                                                                reasonMessage:(NSString *)finalMessage];
            }
        }
        else
        {
            // we are at the primary table view, so we want to go to the detail VC to show that record from our push notification,
            // only when the app was in the background.  If the app is in the foreground, do nothing further
            //
            if (reason != CKQueryNotificationReasonRecordDeleted &&
                [UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
            {
                // go to the detail view controller showing the incoming record
                //
                APLDetailTableViewController *detailViewController =
                    [mainTableViewController.storyboard instantiateViewControllerWithIdentifier:@"APLDetailTableViewController"];
                detailViewController.delegate = mainTableViewController;   // so the table be notified when a record was changed
                
                [CloudManager fetchRecordWithID:recordID completionHandler:^(CKRecord *foundRecord, NSError *error) {
                    if (foundRecord != nil)
                    {
                        detailViewController.record = foundRecord; // hand off the current CKRecord to the detail view controller
                        rootVC.viewControllers = @[mainTableViewController, detailViewController];
                    }
                }];
            }
        }
        
        // for debugging, just for fun - attempt to find the owner of that recordID from this notification
        [self reportUserFromNotification:queryNotification];
    }
}

// didReceiveRemoteNotification:
//
// This is called when:
// 1) the app is actively running (no push alert will appear)
// or
// 2) the app is in the background (push banner will appear, user taps the banner to open our app)
//
// If this app was not already running, then "didFinishLaunchingWithOptions" is called and passed info about the notification.
// So didFinishLaunchingWithOptions needs to handle the incoming notification by itself.
//
// To receive background notifications, this has to be turned on in Xcode:
//      Capabilities -> Background Modes: Remote Notifications
//          where this is added to the Info.plist as a result:
//              	<key>UIBackgroundModes</key>
//                  <array>
//                  <string>remote-notification</string>
//                  </array>
//
// Note:
// To test of the app was actually relaunched due to the push receive,
// use Instrument's Activity Monitor to test if it was truly launched (by checking the "running processes" for that device).
//
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    // note: userInfo must have this:
    //      "content-available" = 1;
    // also: In Info.plist:
    //          <key>UIBackgroundModes</key>
    //          <array>
    //          <string>remote-notification</string>
    //          </array>
    //
    // NOTE:
    // The content-available property with a value of 1 lets the remote notification act as a “silent” notification.
    // When a silent notification arrives, iOS wakes up your app in the background so that you can get new data from
    // your server or do background information processing. Users aren’t told about the new or changed information
    // that results from a silent notification, but they can find out about it the next time they open your app.
    //
    // NOTE:
    // If the notification has 1) alert, 2) badge, or 3) soundKey, then CloudKit uses priority 10, otherwise is uses 5.
    //
    [self handlePush:userInfo];
    
    // this must be called at the end
    completionHandler(UIBackgroundFetchResultNewData);
}


#pragma mark - UIStateRestoration

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return YES;
}

@end
