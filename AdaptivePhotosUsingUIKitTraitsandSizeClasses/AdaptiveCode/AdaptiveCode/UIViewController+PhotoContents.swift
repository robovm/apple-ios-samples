/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
An extension that returns information about photos contained in view controllers.
*/

import UIKit

/*
    This extension is specific to this application. Some of the specific view
    controllers in the app override these to return the values that make sense for
    them.
*/
extension UIViewController {
    /*
        Returns the photo currently being displayed by the receiver, or `nil` if the
        receiver is not displaying a photo.
    */
    func containedPhoto() -> Photo? {
        // By default, view controllers don't contain photos.
        return nil
    }
    
    func containsPhoto(photo: Photo) -> Bool {
        // By default, view controllers don't contain photos.
        return false
    }
    
    func currentVisibleDetailPhotoWithSender(sender: AnyObject?) -> Photo? {
        // Look for a view controller that has a visible photo.
        if let target = targetViewControllerForAction("currentVisibleDetailPhotoWithSender:", sender: sender) {
            return target.currentVisibleDetailPhotoWithSender(sender)
        }
        else {
            return nil
        }
    }
}

extension UISplitViewController {
    override func currentVisibleDetailPhotoWithSender(sender: AnyObject?) -> Photo? {
        if collapsed {
            // If we're collapsed, we don't have a detail.
            return nil
        }
        else {
            // Otherwise, return our detail controller's contained photo (if any).
            let controller = viewControllers.last

            return controller?.containedPhoto()
        }
    }
}
