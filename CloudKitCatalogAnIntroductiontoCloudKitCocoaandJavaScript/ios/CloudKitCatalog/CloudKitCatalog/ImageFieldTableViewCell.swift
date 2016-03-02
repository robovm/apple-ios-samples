/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An ImageFieldTableViewCell is a FormFieldTableViewCell with a UIImageView.
*/
import UIKit

class ImageFieldTableViewCell: FormFieldTableViewCell {

    // MARK: - Properties
    
    var imageInput: ImageInput!
    
    @IBOutlet weak var assetView: UIImageView!
    
    
}
