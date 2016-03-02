/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A TextFieldTableViewCell is a FormFieldTableViewCell with a UITextField.
*/

import UIKit

class TextFieldTableViewCell: FormFieldTableViewCell {

    // Mark: - Properties
    
    @IBOutlet weak var textField: UITextField!
    var textInput: TextInput!
    
}
