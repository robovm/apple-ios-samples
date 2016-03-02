/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    An ErrorViewController displays an NSError.
*/

import UIKit

class ErrorViewController: ResultOrErrorViewController {

    // Mark: - Properties
    
    @IBOutlet weak var errorCode: UILabel!

    @IBOutlet weak var errorText: UITextView!
    
    var error: NSError?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let error = error {
            errorCode.text = "Error Code: \(error.code)"
            errorText.text = error.localizedDescription
            errorText.textContainer.lineFragmentPadding = 0;
            errorText.textContainerInset = UIEdgeInsetsZero;
        } else {
            errorCode.text = "An unexpected error occurred."
        }
        
    }


}
