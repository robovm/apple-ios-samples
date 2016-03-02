/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A BooleanFieldTableViewCell is a FormFieldTableViewCell with a UISwitch to toggle a boolean value.
*/

import UIKit

class BooleanFieldTableViewCell: FormFieldTableViewCell {

    // MARK: - Properties
    
    @IBOutlet weak var booleanField: UISwitch!
    
    var booleanInput: BooleanInput!

    // MARK: - Actions
    
    
    @IBAction func changeValue(sender: UISwitch) {
        booleanInput.value = sender.on
    }
    
}
