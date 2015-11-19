/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A view controller that shows text about this app, using readable margins.
*/

import UIKit

class AboutViewController: UIViewController {
    // MARK: Properties

    var headlineLabel: UILabel?
    var label: UILabel?
    
    // MARK: View Controller
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = UIColor.whiteColor()

        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        headlineLabel.numberOfLines = 1
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headlineLabel)
        self.headlineLabel = headlineLabel

        let label = UILabel()
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        label.numberOfLines = 0

        if let url = NSBundle.mainBundle().URLForResource("Text", withExtension: "txt") {
            do {
                let text = try String(contentsOfURL: url, usedEncoding: nil)
                label.text = text
            } catch let error {
                print("Error loading text: \(error)")
            }
        }
        
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        self.label = label
        
        self.view = view
        
        var constraints = [NSLayoutConstraint]()

        let viewsAndGuides: [String: AnyObject] = [
            "topLayoutGuide":       topLayoutGuide,
            "bottomLayoutGuide":    bottomLayoutGuide,
            "headlineLabel":        headlineLabel,
            "label":                label
        ]

        // Position our labels in the center, respecting the readableContentGuide if it is available
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:[topLayoutGuide]-[headlineLabel]-[label]-[bottomLayoutGuide]|", options: [], metrics: nil, views: viewsAndGuides)

        if #available(iOS 9.0, *) {
            // Use `readableContentGuide` on iOS 9.
            let readableContentGuide = view.readableContentGuide
           
            constraints += [
                label.leadingAnchor.constraintEqualToAnchor(readableContentGuide.leadingAnchor),
                label.trailingAnchor.constraintEqualToAnchor(readableContentGuide.trailingAnchor),
                headlineLabel.leadingAnchor.constraintEqualToAnchor(readableContentGuide.leadingAnchor),
                headlineLabel.trailingAnchor.constraintEqualToAnchor(readableContentGuide.trailingAnchor)
            ]
        }
        else {
            // Fallback on earlier versions.
            constraints += NSLayoutConstraint.constraintsWithVisualFormat("20-[label]-20|", options: [], metrics:nil, views: viewsAndGuides)
            
            constraints += NSLayoutConstraint.constraintsWithVisualFormat("20-[headlineLabel]-20|", options: [], metrics:nil, views: viewsAndGuides)
        }

        NSLayoutConstraint.activateConstraints(constraints)
        updateLabelsForTraitCollection(traitCollection)
    }
    
    // MARK: Transition
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator:coordinator)
        
        updateLabelsForTraitCollection(newCollection)
    }
    
    private func updateLabelsForTraitCollection(collection: UITraitCollection) {
        if collection.horizontalSizeClass == .Regular {
            headlineLabel?.text = "Regular Width"
        }
        else {
            headlineLabel?.text = "Compact Width"
        }
    }
    
    // MARK: IBActions
    
    @IBAction func closeAboutViewController(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
