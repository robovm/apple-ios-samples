/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A view controller that shows a photo and its metadata.
*/

import UIKit

class PhotoViewController: UIViewController {
    // MARK: Properties
    
    private var imageView: UIImageView?
    private var overlayView: OverlayView?
    private var ratingControl: RatingControl?
    
    var photo: Photo
    
    // MARK: Initialization
    
    init(photo: Photo) {
        self.photo = photo

        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View Controller
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = UIColor.whiteColor()
        
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView = imageView
        view.addSubview(imageView)
        
        let ratingControl = RatingControl()
        ratingControl.translatesAutoresizingMaskIntoConstraints = false
        ratingControl.addTarget(self, action: "changeRating:", forControlEvents: .ValueChanged)
        self.ratingControl = ratingControl
        view.addSubview(ratingControl)
        
        let overlayView = OverlayView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        self.overlayView = overlayView
        view.addSubview(overlayView)
        
        updatePhoto()
        
        let views = [
            "imageView":        imageView,
            "ratingControl":    ratingControl,
            "overlayView":      overlayView
        ]

        var newConstraints = [NSLayoutConstraint]()
        
        newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|[imageView]|", options: [], metrics: nil, views: views)

        newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: [], metrics: nil, views: views)
        
        newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("[ratingControl]-20-|", options: [], metrics: nil, views: views)
        
        newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("[overlayView]-20-|", options: [], metrics: nil, views: views)
        
        newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("V:[overlayView]-[ratingControl]-20-|", options: [], metrics: nil, views: views)
        
        NSLayoutConstraint.activateConstraints(newConstraints)
        
        // Now add optional constraints.
        var optionalConstraints = [NSLayoutConstraint]()

        optionalConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|-(>=20)-[ratingControl]", options: [], metrics: nil, views: views)
        
        optionalConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|-(>=20)-[overlayView]", options: [], metrics: nil, views: views)
        
        // We want these constraints to be able to be broken if our interface is resized to be small enough that these margins don't fit.
        for constraint in optionalConstraints {
            constraint.priority = UILayoutPriorityRequired - 1
        }
        
        NSLayoutConstraint.activateConstraints(optionalConstraints)
        
        self.view = view
    }
    
    /*
        Action for a change in value from the `RatingControl` (the user choose a
        different rating for the photo).
    */
    func changeRating(sender: RatingControl) {
        photo.rating = sender.rating
    }
    
    // MARK: Convenience
    
    // Updates the image view and meta data views with the data from the current photo.
    func updatePhoto() {
        imageView?.image = photo.image
        overlayView?.text = photo.comment
        ratingControl?.rating = photo.rating
    }
    
    // This method is originally declared in the PhotoContents extension on UIViewController.
    override func containedPhoto() -> Photo? {
        return photo
    }
}
