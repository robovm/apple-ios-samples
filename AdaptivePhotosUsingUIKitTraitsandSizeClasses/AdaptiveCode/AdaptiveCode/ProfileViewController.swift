/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A view controller that shows a user's profile.
*/

import UIKit

class ProfileViewController: UIViewController {
    // MARK: Properties
    
    private var imageView: UIImageView?
    private var nameLabel: UILabel?
    private var conversationsLabel: UILabel?
    private var photosLabel: UILabel?
    
    // Holds the current constraints used to position the subviews.
    private var constraints = [NSLayoutConstraint]()
    
    let user: User
    
    var nameText: String {
        return user.name
    }
    
    var conversationsText: String {
        let conversationCount = user.conversations.count
        
        let localizedStringFormat = NSLocalizedString("%d conversations", comment: "X conversations")
        
        return String.localizedStringWithFormat(localizedStringFormat, conversationCount)
    }
    
    var photosText: String {
        let photoCount = user.conversations.reduce(0) { count, conversation in
            return count + conversation.photos.count
        }
        
        let localizedStringFormat = NSLocalizedString("%d photos", comment: "X photos")
        
        return String.localizedStringWithFormat(localizedStringFormat, photoCount)
    }
    
    // MARK: Initialization
    
    init(user: User) {
        self.user = user
        
        super.init(nibName: nil, bundle: nil)

        title = NSLocalizedString("Profile", comment: "Profile")
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View Controller
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = UIColor.whiteColor()
        
        // Create an image view
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView = imageView
        view.addSubview(imageView)
        
        // Create a label for the profile name
        let nameLabel = UILabel()
        nameLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.nameLabel = nameLabel
        view.addSubview(nameLabel)
        
        // Create a label for the number of conversations
        let conversationsLabel = UILabel()
        conversationsLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        conversationsLabel.translatesAutoresizingMaskIntoConstraints = false
        self.conversationsLabel = conversationsLabel
        view.addSubview(conversationsLabel)
        
        // Create a label for the number of photos
        let photosLabel = UILabel()
        photosLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        photosLabel.translatesAutoresizingMaskIntoConstraints = false
        self.photosLabel = photosLabel
        view.addSubview(photosLabel)
        
        self.view = view
        
        // Update all of the visible information
        updateUser()
        updateConstraintsForTraitCollection(traitCollection)
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)

        // When the trait collection changes, change our views' constraints and animate the change
        coordinator.animateAlongsideTransition({ _ in
            self.updateConstraintsForTraitCollection(newCollection)
            self.view.setNeedsLayout()
        }, completion: nil)
    }
    
    // Applies the proper constraints to the subviews for the size class of the given trait collection.
    func updateConstraintsForTraitCollection(collection: UITraitCollection) {
        let views: [String: AnyObject] = [
            "topLayoutGuide":       topLayoutGuide,
            "imageView":            imageView!,
            "nameLabel":            nameLabel!,
            "conversationsLabel":   conversationsLabel!,
            "photosLabel":          photosLabel!
        ]
        
        // Make our new set of constraints for the current traits
        var newConstraints = [NSLayoutConstraint]()
        
        if collection.verticalSizeClass == .Compact {
            // When we're vertically compact, show the image and labels side-by-side
            newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|[imageView]-[nameLabel]-|", options: [], metrics: nil, views: views)
            
            newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("[imageView]-[conversationsLabel]-|", options: [], metrics: nil, views: views)
            
            newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("[imageView]-[photosLabel]-|", options: [], metrics: nil, views: views)
            
            newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[topLayoutGuide]-[nameLabel]-[conversationsLabel]-[photosLabel]", options: [], metrics: nil, views: views)
            
            newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[topLayoutGuide][imageView]|", options: [], metrics: nil, views: views)
            
            newConstraints += [
                NSLayoutConstraint(item: imageView!, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 0.5, constant: 0)
            ]
        }
        else {
            // When we're vertically compact, show the image and labels top-and-bottom
            newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|[imageView]|", options: [], metrics: nil, views: views)
            
            newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|-[nameLabel]-|", options: [], metrics: nil, views: views)
            
            newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|-[conversationsLabel]-|", options: [], metrics: nil, views: views)
            
            newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|-[photosLabel]-|", options: [], metrics: nil, views: views)
            
            newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("V:[topLayoutGuide]-[nameLabel]-[conversationsLabel]-[photosLabel]-20-[imageView]|", options: [], metrics: nil, views: views)
        }
        
        // Change to our new constraints
        NSLayoutConstraint.deactivateConstraints(constraints)
        constraints = newConstraints
        NSLayoutConstraint.activateConstraints(newConstraints)
    }
    
    // MARK: Convenience
    
    // Updates the user interface with the data from the current user object.
    func updateUser() {
        nameLabel?.text = nameText
        conversationsLabel?.text = conversationsText
        photosLabel?.text = photosText
        imageView?.image = user.lastPhoto?.image
    }
}
