/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A view controller that shows a list of conversations that can be viewed.
*/

import UIKit

class ListTableViewController: UITableViewController {
    // MARK: Properties
    
    var user: User? {
        didSet {
            if isViewLoaded() {
                tableView.reloadData()
            }
        }
    }
    
    static let conversationCellIdentifier = "ConversationCell"
    static let photoCellIdentifier = "PhotoCell"
    
    // MARK: Initialization
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showDetailTargetDidChange:", name: UIViewControllerShowDetailTargetDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Deselect any index paths that push when tapped
        for indexPath in tableView.indexPathsForSelectedRows ?? [] {
            let pushes: Bool
            
            if shouldShowConversationViewForIndexPath(indexPath) {
                pushes = willShowingViewControllerPushWithSender(self)
            }
            else {
                pushes = willShowingDetailViewControllerPushWithSender(self)
            }
            
            if pushes {
                // If we're pushing for this indexPath, deselect it when we appear.
                tableView.deselectRowAtIndexPath(indexPath, animated: animated)
            }
        }
        
        if let visiblePhoto = currentVisibleDetailPhotoWithSender(self) {
            for indexPath in tableView.indexPathsForVisibleRows ?? [] {
                let photo = photoForIndexPath(indexPath)
                
                if photo == visiblePhoto {
                    tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
                }
            }
        }
    }
    
    func showDetailTargetDidChange(notification: NSNotification) {
        /*
            Whenever the target for showDetailViewController: changes, update all
            of our cells (to ensure they have the right accessory type).
        */
        for cell in tableView.visibleCells {
            if let indexPath = tableView.indexPathForCell(cell) {
                tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)
            }
        }
    }
    
    override func containsPhoto(photo: Photo) -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let indexPath = tableView.indexPathForSelectedRow,
               conversation = conversationForIndexPath(indexPath) {
            if segue.identifier == "ShowConversation" {
                // Set up our ConversationViewController to have its conversation and title
                let destination = segue.destinationViewController as! ConversationViewController
                destination.conversation = conversation
                destination.title = conversation.name
            }
            else if segue.identifier == "ShowPhoto" {
                // Set up our PhotoViewController to have its photo and title
                let destination = segue.destinationViewController as! PhotoViewController
                destination.photo = conversation.photos.last
                destination.title = conversation.name
            }
        }
        
        if segue.identifier == "ShowAbout" {
            if presentedViewController != nil {
                // Dismiss Profile if visible.
                dismissViewControllerAnimated(true, completion: nil)
            }
        }
        else if segue.identifier == "ShowProfile" {
            // Set up our ProfileViewController to have its user
            let navigationController = segue.destinationViewController as! UINavigationController
            let destination = navigationController.topViewController as! ProfileViewController
            destination.user = user
            
            // Set self as the presentation controller's delegate so that we can adapt its appearance
            navigationController.popoverPresentationController?.delegate = self
        }
    }
    
    // MARK: Table View
    
    func conversationForIndexPath(indexPath: NSIndexPath) -> Conversation? {
        return user?.conversations[indexPath.row]
    }
    
    func photoForIndexPath(indexPath: NSIndexPath) -> Photo? {
        if shouldShowConversationViewForIndexPath(indexPath) {
            return nil
        }
        else {
            let conversation = conversationForIndexPath(indexPath)

            return conversation?.photos.last
        }
    }
    
    // Returns whether the conversation at indexPath contains more than one photo.
    func shouldShowConversationViewForIndexPath(indexPath: NSIndexPath) -> Bool {
        let conversation  = conversationForIndexPath(indexPath)
        
        return (conversation?.photos.count ?? 0) > 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return user?.conversations.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if shouldShowConversationViewForIndexPath(indexPath) {
            return tableView.dequeueReusableCellWithIdentifier(ListTableViewController.conversationCellIdentifier, forIndexPath: indexPath)
        }
        else {
            return tableView.dequeueReusableCellWithIdentifier(ListTableViewController.photoCellIdentifier, forIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // Whether to show the disclosure indicator for this cell.
        let pushes: Bool
        if shouldShowConversationViewForIndexPath(indexPath) {
            // If the conversation corresponding to this row has multiple photos.
            pushes = willShowingViewControllerPushWithSender(self)
        }
        else {
            // If the conversation corresponding to this row has a single photo.
            pushes = willShowingDetailViewControllerPushWithSender(self)
        }
        
        /*
            Only show a disclosure indicator if selecting this cell will trigger
            a push in the master view controller (the navigation controller above
            ourself).
        */
        cell.accessoryType = pushes ? .DisclosureIndicator : .None
        
        let conversation = conversationForIndexPath(indexPath)
        cell.textLabel?.text = conversation?.name ?? ""
    }
}

extension ListTableViewController: UIPopoverPresentationControllerDelegate {
    func presentationController(presentationController: UIPresentationController, willPresentWithAdaptiveStyle style: UIModalPresentationStyle, transitionCoordinator: UIViewControllerTransitionCoordinator?) {
        guard let presentedNavigationController = presentationController.presentedViewController as? UINavigationController else { return }

        // We want to show the navigation bar if we're presenting in full screen.
        
        let hidesNavigationBar = style != .FullScreen
        
        presentedNavigationController.setNavigationBarHidden(hidesNavigationBar, animated: false)
    }
}
