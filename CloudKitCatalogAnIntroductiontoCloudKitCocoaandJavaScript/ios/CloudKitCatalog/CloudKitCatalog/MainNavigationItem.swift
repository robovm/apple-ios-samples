/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the navigation item that holds the CloudKit logo as its titleView.
*/

import UIKit

class MainNavigationItem: UINavigationItem {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        titleView = UIImageView(image: UIImage(named: "Title"))
    }
}
