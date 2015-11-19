/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A control that allows viewing and editing a rating.
*/

import UIKit

class RatingControl: UIControl {
    
    /*
        NOTE: Unlike OverlayView, this control does not implement `intrinsicContentSize()`.
        Instead, this control configures its auto layout constraints such that the
        size of the star images that compose it can be used by the layout engine 
        to derive the desired content size of this control. Since UIImageView will
        automatically load the correct UIImage asset for the current trait collection,
        we receive automatic adaptivity support for free just by including the images 
        for both the compact and regular size classes.
    */
    
    static let minimumRating = 0
    static let maximumRating = 4
    
    var rating = RatingControl.minimumRating {
        didSet {
            updateImageViews()
        }
    }
    
    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
    private var imageViews = [UIImageView]()
    
    // This initializer will be called if the control is created programatically.
    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }
    
    // This initializer will be called if the control is loaded from a storyboard.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }
    
    // Initialization code common to instances created programmatically as well as instances unarchived from a storyboard.
    private func commonInit() {
        backgroundView.contentView.backgroundColor = UIColor(white: 0.7, alpha: 0.3)
        addSubview(backgroundView)
        
        // Create image views for each of the sections that make up the control.
        for rating in RatingControl.minimumRating...RatingControl.maximumRating {
            let imageView = UIImageView()
            imageView.userInteractionEnabled = true
            
            // Set up our image view's images.
            imageView.image = UIImage(named: "ratingInactive")
            imageView.highlightedImage = UIImage(named: "ratingActive")
            
            let localizedStringFormat = NSLocalizedString("%d stars", comment: "X stars")
            imageView.accessibilityLabel = String.localizedStringWithFormat(localizedStringFormat, rating + 1)
            addSubview(imageView)
            imageViews.append(imageView)
        }
        
        // Setup constraints.
        var newConstraints = [NSLayoutConstraint]()
        
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        
        let views = ["backgroundView": backgroundView]
        
        // Keep our background matching our size
        newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|[backgroundView]|", options: [], metrics: nil, views: views)
        newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundView]|", options: [], metrics: nil, views: views)
        
        // Place the individual image views side-by-side with margins
        var lastImageView: UIImageView?
        for imageView in imageViews {
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            let currentImageViews: [String: AnyObject]
            
            if lastImageView != nil {
                currentImageViews = [
                    "lastImageView": lastImageView!,
                    "imageView": imageView
                ]
            }
            else {
                currentImageViews = ["imageView": imageView]
            }
            
            newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-4-[imageView]-4-|", options: [], metrics: nil, views: currentImageViews)
            
            newConstraints += [
                NSLayoutConstraint(item: imageView, attribute: .Width, relatedBy: .Equal, toItem: imageView, attribute: .Height, multiplier: 1, constant: 0)
            ]

            if lastImageView != nil {
                newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("[lastImageView][imageView(==lastImageView)]", options: [], metrics: nil, views: currentImageViews)
            }
            else {
                newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|-4-[imageView]", options: [], metrics: nil, views: currentImageViews)
            }
            
            lastImageView = imageView
        }
        
        let currentImageViews = ["lastImageView": lastImageView!]

        newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("[lastImageView]-4-|", options: [], metrics: nil, views: currentImageViews)
        
        NSLayoutConstraint.activateConstraints(newConstraints)
    }
    
    func updateImageViews() {
        for (index, imageView) in imageViews.enumerate() {
            imageView.highlighted = index + RatingControl.minimumRating <= rating
        }
    }

    // MARK: Touches

    func updateRatingWithTouches(touches: Set<UITouch>, event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let position = touch.locationInView(self)
        
        guard let touchedView = hitTest(position, withEvent: event) as? UIImageView else { return }
        
        guard let touchedIndex = imageViews.indexOf(touchedView) else { return }
        
        rating = RatingControl.minimumRating + touchedIndex

        sendActionsForControlEvents(.ValueChanged)
    }
    
    // If you override one of the touch event callbacks, you should override all of them.
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        updateRatingWithTouches(touches, event: event)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        updateRatingWithTouches(touches, event: event)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // There's no need to handle `touchesCancelled(_:withEvent:)` for this control.
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        // There's no need to handle `touchesCancelled(_:withEvent:)` for this control.
    }

    // MARK: Accessibility

    // This control is not an accessibility element but the individual images that compose it are.
    override var isAccessibilityElement: Bool {
        set { /* ignore value */ }
        
        get { return false }
    }
}
