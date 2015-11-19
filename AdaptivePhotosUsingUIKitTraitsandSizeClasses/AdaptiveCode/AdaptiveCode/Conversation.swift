/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The model object that represents a conversation.
*/

import Foundation

struct Conversation {
    // MARK: Properties
    
    var name = ""
    var photos = [Photo]()
    
    // MARK: Initialization
    
    init() {}
    
    init?(dictionary: [String: AnyObject]) {
        guard let name = dictionary["name"] as? String else { return nil }
        self.name = name
        
        if let photoDictionaries = dictionary["photos"] as? [[String: AnyObject]] {
            photos = photoDictionaries.flatMap { photoDictionary in
                return Photo(dictionary: photoDictionary)
            }
        }
        else {
            photos = []
        }
    }
}
