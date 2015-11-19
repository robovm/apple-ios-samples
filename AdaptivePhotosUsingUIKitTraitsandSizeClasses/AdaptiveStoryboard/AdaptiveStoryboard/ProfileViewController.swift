/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A view controller that shows a user's profile.
*/

import UIKit

class ProfileViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet private var imageView: UIImageView?
    @IBOutlet private var nameLabel: UILabel?
    @IBOutlet private var conversationsLabel: UILabel?
    @IBOutlet private var photosLabel: UILabel?
    
    var user: User? {
        didSet {
            if isViewLoaded() {
                updateUser()
            }
        }
    }
    
    var nameText: String? {
        return user?.name
    }
    
    var conversationsText: String {
        let conversationCount = user?.conversations.count ?? 0
        
        let localizedStringFormat = NSLocalizedString("%d conversations", comment: "X conversations")
        
        return String.localizedStringWithFormat(localizedStringFormat, conversationCount)
    }
    
    var photosText: String {
        let photoCount = user?.conversations.reduce(0) { count, conversation -> Int in
            return count + conversation.photos.count
        } ?? 0
        
        let localizedStringFormat = NSLocalizedString("%d photos", comment: "X photos")

        return String.localizedStringWithFormat(localizedStringFormat, photoCount)
    }
    
    // MARK: View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUser()
    }
    
    // MARK: IBActions
    
    @IBAction func closeProfileViewController(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Convenience
    
    // Updates the user interface with the data from the current user object.
    func updateUser() {
        nameLabel?.text = nameText
        conversationsLabel?.text = conversationsText
        photosLabel?.text = photosText
        imageView?.image = user?.lastPhoto?.image
    }
}
