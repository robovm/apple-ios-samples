/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A SubmenuTableViewCell contains a text label for the code sample's function/method name.
*/
import UIKit

class SubmenuTableViewCell: UITableViewCell {
    
    @IBOutlet weak var submenuLabel: UILabel!

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
