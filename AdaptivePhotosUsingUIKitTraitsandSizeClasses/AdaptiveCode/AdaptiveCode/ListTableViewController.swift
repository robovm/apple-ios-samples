/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A view controller that shows a list of conversations that can be viewed.
*/

import UIKit

class ListTableViewController: UITableViewController {
    // MARK: Properties

    let user: User
    
    static let cellIdentifier = "ConversationCell"
    
    // MARK: Initialization
    
    init(user: User) {
        self.user = user

        super.init(style: .Plain)

        title = NSLocalizedString("Conversations", comment: "Conversations")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("About", comment: "About"), style: .Plain, target: self, action: "showAboutViewController:")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Profile", comment: "Profile"), style: .Plain, target: self, action: "showProfileViewController:")
        
        clearsSelectionOnViewWillAppear = false
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: ListTableViewController.cellIdentifier)
        
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

    // MARK: About

    func showAboutViewController(sender: UIBarButtonItem) {
        if presentedViewController != nil {
            // Dismiss Profile if visible
            dismissViewControllerAnimated(true, completion: nil)
        }
        
        let aboutViewController = AboutViewController()
        aboutViewController.navigationItem.title = NSLocalizedString("About", comment: "About")
        aboutViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "closeAboutViewController:")

        let navController = UINavigationController(rootViewController: aboutViewController)
        navController.modalPresentationStyle = .FullScreen
        presentViewController(navController, animated: true, completion: nil)
    }

    func closeAboutViewController(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: Profile
    
    func showProfileViewController(sender: UIBarButtonItem) {
        let profileController = ProfileViewController(user: user)
        profileController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "closeProfileViewController:")
        
        let profileNavController = UINavigationController(rootViewController: profileController)
        profileNavController.modalPresentationStyle = .Popover
        profileNavController.popoverPresentationController?.barButtonItem = sender
        
        // Set self as the presentation controller's delegate so that we can adapt its appearance
        profileNavController.popoverPresentationController?.delegate = self

        presentViewController(profileNavController, animated: true, completion:nil)
    }

    func closeProfileViewController(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: Table View
    
    func conversationForIndexPath(indexPath: NSIndexPath) -> Conversation {
        return user.conversations[indexPath.row]
    }
    
    func photoForIndexPath(indexPath: NSIndexPath) -> Photo? {
        if shouldShowConversationViewForIndexPath(indexPath) {
            return nil
        }
        else {
            let conversation = conversationForIndexPath(indexPath)
            
            return conversation.photos.last
        }
    }
    
    // Returns whether the conversation at indexPath contains more than one photo.
    func shouldShowConversationViewForIndexPath(indexPath: NSIndexPath) -> Bool {
        let conversation  = conversationForIndexPath(indexPath)

        return conversation.photos.count > 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return user.conversations.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier(ListTableViewController.cellIdentifier, forIndexPath: indexPath)
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
        cell.textLabel?.text = conversation.name
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let conversation = conversationForIndexPath(indexPath)
        
        if shouldShowConversationViewForIndexPath(indexPath) {
            let controller = ConversationViewController(conversation: conversation)
            controller.title = conversation.name
            
            // If this row has a conversation, we just want to show it.
            showViewController(controller, sender: self)
        }
        else {
            if let photo = conversation.photos.last {
                let controller = PhotoViewController(photo: photo)
                controller.title = conversation.name
                
                // If this row has a single photo, then show it as the detail (if possible).
                showDetailViewController(controller, sender: self)
            }
        }
    }
}

extension ListTableViewController: UIPopoverPresentationControllerDelegate {
    func presentationController(presentationController: UIPresentationController, willPresentWithAdaptiveStyle style: UIModalPresentationStyle, transitionCoordinator: UIViewControllerTransitionCoordinator?) {
        guard let presentedNavigationController = presentationController.presentedViewController as? UINavigationController else { return }
        
        // We want to hide the navigation bar if we're presenting in our original style (Popover)
        let hidesNavigationBar = style == .None
        
        presentedNavigationController.setNavigationBarHidden(hidesNavigationBar, animated: false)
    }
}
