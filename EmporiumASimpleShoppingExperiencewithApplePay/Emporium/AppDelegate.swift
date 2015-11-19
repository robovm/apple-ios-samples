/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Main application entry point.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: Properties
    
    var window: UIWindow?
    
    var rootViewController: UINavigationController? {
        return window?.rootViewController as? UINavigationController
    }
    
    // MARK: Handoff
    
    /* 
        Here we handle our WatchKit activity handoff request. We'll take the dictionary
        passed in as part of the activity's userInfo property, and immediately
        present a payment sheet. If you're using handoff to allow WatchKit apps to
        request Apple Pay payments you try to display the payment sheet as soon as
        possible.
    */
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: [AnyObject]? -> Void) -> Bool {
        
        // Create a new product detail view controller using the supplied product.
        if let productDictionary = userActivity.userInfo?["product"] as? [String: AnyObject] {
            let product = Product(dictionary: productDictionary)
            
            // Firstly, we'll create a product detail page. We can instantiate it from our storyboard...
            let viewController = rootViewController?.storyboard?.instantiateViewControllerWithIdentifier("ProductTableViewController") as! ProductTableViewController
            
            // Manually set the product we want to display.
            viewController.product = product
            
            // The rootViewController should be a navigation controller. Pop to it if needed.
            rootViewController?.popToRootViewControllerAnimated(false)
            
            // Push the view controller onto our app, so it's the first thing the user sees.
            rootViewController?.pushViewController(viewController, animated: false)
            
            // We also want to immediately show the payment sheet, so we'll trigger that too.
            viewController.applePayButtonPressed()
        }
        
        return true
    }
}
