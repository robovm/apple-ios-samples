/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The model object that represents an individual photo.
*/

import UIKit

class Photo: NSObject {
    // MARK: Properties

    var comment = ""
    var rating = 0

    var image: UIImage? {
        /*
            Custom implementation of the getter for the image property. The image
            property is a derived property. The image corresponding to `imageName`
            is loaded upon request. Note that if you had to load the image over a 
            network, you should instead define a method that takes a completion 
            handler, which is called when the image has been downloaded. See the
            LazyTableImages sample for an example.
        
            https://developer.apple.com/library/ios/samplecode/LazyTableImages/Introduction/Intro.html
        */
        if let path = NSBundle.mainBundle().pathForResource(imageName, ofType: "jpg") {
            return UIImage(contentsOfFile: path)
        }
        else {
            return nil
        }
    }
    
    var imageName: String?
    
    // MARK: Initialization

    override init() { }

    init(dictionary: [String: AnyObject]) {
        imageName = dictionary["imageName"] as? String
        comment = dictionary["comment"] as? String ?? ""
        rating = dictionary["rating"] as? Int ?? 0
    }
}
