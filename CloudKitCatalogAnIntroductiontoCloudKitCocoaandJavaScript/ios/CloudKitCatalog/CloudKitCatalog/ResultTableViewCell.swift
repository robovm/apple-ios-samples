/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A ResultTableViewCell contains a text label for a Result object's summaryField, 
                and a label marking its change state:
                modified=M, deleted=D, added=A.
*/

import UIKit

class ResultTableViewCell: UITableViewCell {
    
    // MARK: - Properties

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var changeLabel: UILabel!
    
    @IBOutlet weak var changeLabelWidthConstraint: NSLayoutConstraint!
    
    
}
