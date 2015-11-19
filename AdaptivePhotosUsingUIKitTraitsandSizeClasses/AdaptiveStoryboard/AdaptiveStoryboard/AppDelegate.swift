/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The application delegate and split view controller delegate.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Load the conversations from disk and create our root model object.
        
        let user: User
        if let url = NSBundle.mainBundle().URLForResource("User", withExtension: "plist"),
            userDictionary = NSDictionary(contentsOfURL: url) as? [String: AnyObject],
            loadedUser = User(dictionary: userDictionary) {
                user = loadedUser
        }
        else {
            user = User()
        }
        
        if let splitViewController = window?.rootViewController as? UISplitViewController {
            splitViewController.delegate = self
            splitViewController.preferredDisplayMode = .AllVisible

            if let masterNavController = splitViewController.viewControllers.first as? UINavigationController,
                   masterViewController = masterNavController.topViewController as? ListTableViewController {
                masterViewController.user = user
            }
        }
        
        window?.makeKeyAndVisible()
        
        return true
    }
}

extension AppDelegate: UISplitViewControllerDelegate {
    // Collapse the secondary view controller onto the primary view controller.
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        /*
            The secondary view is not showing a photo. Return true to tell the
            splitViewController to use its default behavior: just hide the
            secondaryViewController and show the primaryViewController.
        */
        guard let photo = secondaryViewController.containedPhoto() else { return true }

        /*
            The secondary view is showing a photo. Set the primary navigation
            controller to contain a path of view controllers that lead to that photo.
        */
        if let primaryNavController = primaryViewController as? UINavigationController {
            let viewControllersLeadingToPhoto = primaryNavController.viewControllers.filter { $0.containsPhoto(photo) }
            
            primaryNavController.viewControllers = viewControllersLeadingToPhoto
        }

        /*
            We handled the collapse. Return false to tell the splitViewController
            not to do anything else.
        */
        return false
    }
    
    // Separate the secondary view controller from the primary view controller.
    func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController primaryViewController: UIViewController) -> UIViewController? {
        
        if let primaryNavController = primaryViewController as? UINavigationController {
            /*
                One of the view controllers in the navigation stack is showing a
                photo. Return nil to tell the splitViewController to use its
                default behavior: show the secondary view controller that was
                present when it collapsed.
            */
            let anyViewControllerContainsPhoto = primaryNavController.viewControllers.contains { controller in
                return controller.containedPhoto() != nil
            }
            
            if anyViewControllerContainsPhoto {
                return nil
            }
        }
        
        /* 
            None of the view controllers in the navigation stack contained a photo,
            so show a new empty view controller as the secondary.
        */
        return primaryViewController.storyboard?.instantiateViewControllerWithIdentifier("EmptyViewController")
    }
}
