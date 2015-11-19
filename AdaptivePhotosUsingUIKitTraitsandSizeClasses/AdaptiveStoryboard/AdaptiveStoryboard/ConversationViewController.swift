/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A view controller that shows the contents of a conversation.
*/

import UIKit

class ConversationViewController: UITableViewController {
    // MARK: Properties
    
    var conversation: Conversation?
    
    static let cellIdentifier = "PhotoCell"
    
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
        
        for indexPath in tableView.indexPathsForSelectedRows ?? [] {
            let indexPathPushes = willShowingDetailViewControllerPushWithSender(self)

            if indexPathPushes {
                // If we're pushing for this indexPath, deselect it when we appear.
                tableView.deselectRowAtIndexPath(indexPath, animated: animated)
            }
        }
        
        let visiblePhoto = currentVisibleDetailPhotoWithSender(self)
        
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            let photo = photoForIndexPath(indexPath)
            
            if photo == visiblePhoto {
                tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let indexPath = tableView.indexPathForSelectedRow,
                  photo = photoForIndexPath(indexPath)
              where segue.identifier == "ShowPhoto" else { return }

        let destination = segue.destinationViewController as! PhotoViewController
        destination.photo = photo
        let photoNumber = indexPath.row + 1
        let photoCount = conversation?.photos.count ?? 0
        
        let localizedStringFormat = NSLocalizedString("%d of %d", comment: "X of X")
        destination.title = String.localizedStringWithFormat(localizedStringFormat, photoNumber, photoCount)
    }
    
    // This method is originally declared in the PhotoContents extension on `UIViewController`.
    override func containsPhoto(photo: Photo) -> Bool {
        return conversation?.photos.contains(photo) ?? false
    }
    
    func showDetailTargetDidChange(notification: NSNotification) {
        for cell in tableView.visibleCells {
            if let indexPath = tableView.indexPathForCell(cell) {
                tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)
            }
        }
    }
    
    // MARK: Table View
    
    func photoForIndexPath(indexPath: NSIndexPath) -> Photo? {
        return conversation?.photos[indexPath.row]
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversation?.photos.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier(ConversationViewController.cellIdentifier, forIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let pushes = willShowingDetailViewControllerPushWithSender(self)
        
        // Only show a disclosure indicator if we're pushing.
        cell.accessoryType = pushes ? .DisclosureIndicator : .None
        
        let photo = photoForIndexPath(indexPath)
        
        cell.textLabel?.text = photo?.comment ?? ""
    }
}
