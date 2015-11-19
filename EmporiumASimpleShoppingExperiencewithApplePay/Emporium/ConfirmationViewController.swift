/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Simple confirmation view controller.
*/

import UIKit

class ConfirmationViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet weak var confirmationLabel: UILabel!
    
    var transactionIdentifier: String!
    
    // MARK: View Controller

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        confirmationLabel.text = transactionIdentifier
    }
}
