/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A SelectionFieldTableViewCell is a FormFieldTableViewCell which contains a dropdown list of items and a
                unique selected item.
*/

import UIKit

class SelectionFieldTableViewCell: FormFieldTableViewCell {

    // MARK: - Properties
    
    @IBOutlet weak var selectedItemLabel: UILabel!
    
    var selectionInput: SelectionInput!
}
