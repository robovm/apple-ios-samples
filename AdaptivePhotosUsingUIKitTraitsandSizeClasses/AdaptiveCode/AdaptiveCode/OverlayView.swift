/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A view that shows a textual overlay whose margins change with its vertical size class.
*/

import UIKit

class OverlayView: UIView {
    // MARK: Properties
    
    var text: String? {
        /*
            Custom implementations of the getter and setter for the comment propety. 
            Changes to this property are forwarded to the label and the intrinsic
            content size is invalidated.
        */
        get {
            return label.text
        }

        set {
            label.text = newValue
        }
    }
    
    private var label = UILabel()
    
    // MARK: Initialization
    
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
    
    /*
        Initialization code common to instances created programmatically as well
        as instances unarchived from a storyboard.
    */
    private func commonInit() {
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        backgroundView.contentView.backgroundColor = UIColor(white: 0.7, alpha: 0.3)
        addSubview(backgroundView)
        
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        addSubview(label)
        
        // Setup constraints.
        var newConstraints = [NSLayoutConstraint]()
        
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["backgroundView": backgroundView]

        newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("|[backgroundView]|", options: [], metrics: nil, views: views)
        
        newConstraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundView]|", options: [], metrics: nil, views: views)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        newConstraints += [
            NSLayoutConstraint(item: label, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0),
            
            NSLayoutConstraint(item: label, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)
        ]
        
        NSLayoutConstraint.activateConstraints(newConstraints)
        
        /*
            Listening for changes to the user's preferred text size and updating 
            the relevant views is necessary to fully support Dynamic Type in your 
            view or control.  The user may adjust their preferred text style while
            your application is suspended.  Upon returning to the foreground, your
            application will receive a `UIContentSizeCategoryDidChangeNotification`
            should a change to the user's preferred text size have occurred.
        */
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contentSizeCategoryDidChange:", name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Content Size Handling
    
    func contentSizeCategoryDidChange(notification: NSNotification) {
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)

        invalidateIntrinsicContentSize()
    }
    
    override func intrinsicContentSize() -> CGSize {
        var size = label.intrinsicContentSize()
        
        // Add a horizontal margin whose size depends on our horizontal size class.
        if traitCollection.horizontalSizeClass == .Compact {
            size.width += 8.0
        }
        else {
            size.width += 40.0
        }
        
        // Add a vertical margin whose size depends on our vertical size class.
        if traitCollection.verticalSizeClass == .Compact {
            size.height += 8.0
        }
        else {
            size.height += 40.0
        }
        
        return size
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass ||
              traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass else { return }
        
        /*
            If our size class has changed, then our intrinsic content size will
            need to be updated.
        */
        invalidateIntrinsicContentSize()
    }
}
