/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
An extension that gives information about how view controllers will be shown, for determining disclosure indicator visibility and row deselection.
*/

import UIKit

extension UIViewController {
    /**
        Returns whether calling `showViewController(_:sender:)` would cause a
        navigation "push" to occur.
    */
    func willShowingViewControllerPushWithSender(sender: AnyObject?) -> Bool {
        // Find and ask the right view controller about showing.
        if let target = targetViewControllerForAction("willShowingViewControllerPushWithSender:", sender: sender) {
            return target.willShowingViewControllerPushWithSender(sender)
        }

        // Or if we can't find one, we won't be pushing.
        return false
    }

    /**
        Returns whether calling `showDetailViewController(_:sender:)` would cause a
        navigation "push" to occur.
    */
    func willShowingDetailViewControllerPushWithSender(sender: AnyObject?) -> Bool {
        // Find and ask the right view controller about showing.
        if let target = targetViewControllerForAction("willShowingDetailViewControllerPushWithSender:", sender: sender) {
            return target.willShowingDetailViewControllerPushWithSender(sender)
        }

        // Or if we can't find one, we won't be pushing.
        return false
    }
}

extension UINavigationController {
    override func willShowingViewControllerPushWithSender(sender: AnyObject?) -> Bool {
        // Navigation Controllers always push for `showViewController(_:sender:)`.
        return true
    }
}

extension UISplitViewController {
    override func willShowingViewControllerPushWithSender(sender: AnyObject?) -> Bool {
        // Split View Controllers never push for `showViewController(_:sender:)`.
        return false
    }
    
    override func willShowingDetailViewControllerPushWithSender(sender: AnyObject?) -> Bool {
        if collapsed {
            /*
                If we're collapsed, re-ask this question as `showViewController(_:sender:)`
                to our primary view controller.
            */
            let target = viewControllers.last
        
            return target?.willShowingViewControllerPushWithSender(sender) ?? false
        }

        // Otherwise, we don't push for `showDetailViewController(_:sender:)`.
        return false
    }
}
