/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This file handles registration for CloudKit Notifications as well as processing remote notifications when
                they are received.
*/

import UIKit
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let settings = UIUserNotificationSettings(forTypes: .Alert, categories: nil)
        
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        
        if let userInfo = userInfo as? [String: NSObject] {
            let notification = CKNotification.init(fromRemoteNotificationDictionary: userInfo)
            let state = application.applicationState
            if let viewController = window?.rootViewController as? UINavigationController {
                if let tableViewController = viewController.viewControllers[0] as? MainMenuTableViewController {
                    let index = tableViewController.codeSampleGroups.count - 1
                    if let notificationSample = tableViewController.codeSampleGroups.last?.codeSamples.first as? MarkNotificationsReadSample {
                        notificationSample.cache.addNotification(notification)
                        tableViewController.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
                    }
                }
                if state == .Active {
                    if let navigationBar = viewController.navigationBar as? NavigationBar {
                        navigationBar.showNotificationAlert(notification)
                    }
                }

            }
            
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

