/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that demonstrates how to use UIStackView.
*/

import UIKit

class StackViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet var furtherDetailStackView: UIStackView!
    
    @IBOutlet var plusButton: UIButton!
    
    // MARK: View Life Cycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        furtherDetailStackView.hidden = true
        plusButton.hidden = false
    }
    
    // MARK: Actions
    
    @IBAction func showFurtherDetail(_: AnyObject) {
        // Animate the changes by performing them in a `UIView` animation block.
        UIView.animateWithDuration(0.25) {
            // Reveal the further details stack view and hide the plus button.
            self.furtherDetailStackView.hidden = false
            self.plusButton.hidden = true
        }
    }
    
    @IBAction func hideFurtherDetail(_: AnyObject) {
        // Animate the changes by performing them in a `UIView` animation block.
        UIView.animateWithDuration(0.25) {
            // Hide the further details stack view and reveal the plus button.
            self.furtherDetailStackView.hidden = true
            self.plusButton.hidden = false
        }
    }
}