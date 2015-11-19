/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A view controller that shows placeholder text.
*/

import UIKit

class EmptyViewController: UIViewController {
    override func loadView() {
        let view = UIView()
        view.backgroundColor = UIColor.whiteColor()
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("No Conversation Selected", comment: "No Conversation Selected")
        label.textColor = UIColor(white: 0.0, alpha: 0.4)
        label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        view.addSubview(label)
        
        let xConstraint = NSLayoutConstraint(item: label, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: label, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: 0)
        NSLayoutConstraint.activateConstraints([xConstraint, yConstraint])
        
        self.view = view
    }
}
