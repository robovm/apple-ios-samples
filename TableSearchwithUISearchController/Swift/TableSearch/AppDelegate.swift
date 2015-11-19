/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The application delegate class used for setting up our data model and state restoration.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: Properties

    var window: UIWindow?
    
    // MARK: - Application Life Cycle

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let products = [
            Product(hardwareType: Product.deviceTypeTitle, title: Product.Hardware.iPhone.rawValue, yearIntroduced: 2007, introPrice: 599.00),
            Product(hardwareType: Product.deviceTypeTitle, title: Product.Hardware.iPod.rawValue, yearIntroduced: 2001, introPrice: 399.00),
            Product(hardwareType: Product.deviceTypeTitle, title: Product.Hardware.iPodTouch.rawValue, yearIntroduced: 2007, introPrice: 210.00),
            Product(hardwareType: Product.deviceTypeTitle, title: Product.Hardware.iPad.rawValue, yearIntroduced: 2010, introPrice: 499.00),
            Product(hardwareType: Product.deviceTypeTitle, title: Product.Hardware.iPadMini.rawValue, yearIntroduced: 2012, introPrice: 659.00),
            Product(hardwareType: Product.desktopTypeTitle, title: Product.Hardware.iMac.rawValue, yearIntroduced: 1997, introPrice: 1299.00),
            Product(hardwareType: Product.desktopTypeTitle, title: Product.Hardware.MacPro.rawValue, yearIntroduced: 2006, introPrice: 2499.00),
            Product(hardwareType: Product.portableTypeTitle, title: Product.Hardware.MacBookAir.rawValue, yearIntroduced: 2008, introPrice: 1799.00),
            Product(hardwareType: Product.portableTypeTitle, title: Product.Hardware.MacBookPro.rawValue, yearIntroduced: 2006, introPrice: 1499.00)
        ]

        let navController = window!.rootViewController as! UINavigationController
        
        /*
            Note we want the first view controller (not the visibleViewController) in case
            we are being store from UIStateRestoration.
        */
        let tableViewController = navController.viewControllers.first as! MainTableViewController
        tableViewController.products = products

        return true
    }

    // MARK: - UIStateRestoration

    func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
}
