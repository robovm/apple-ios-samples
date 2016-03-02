/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A CodeSampleGroup is a list of related code samples.
*/

import UIKit

class CodeSampleGroup {
    
    // MARK: - Properties
    
    let title: String
    let icon: UIImage
    let codeSamples: [CodeSample]
    
    // MARK: - Initialization
    
    init(title: String, icon: UIImage, codeSamples: [CodeSample]) {
        self.title = title
        self.icon = icon
        self.codeSamples = codeSamples
    }
}

