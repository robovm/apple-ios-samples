/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The top level model object. Manages a list of conversations and the user's profile.
*/

import Foundation

struct User {
    // MARK: Properties
    
    var name = ""
    var conversations = [Conversation]()
    var lastPhoto: Photo?
    
    // MARK: Initialization
    
    init() { }
    
    init?(dictionary: [String: AnyObject]) {
        guard let name = dictionary["name"] as? String else { return nil }

        self.name = name
        
        if let conversationDictionaries = dictionary["conversations"] as? [[String: AnyObject]] {
            conversations = conversationDictionaries.flatMap { conversationDictionary in
                return Conversation(dictionary: conversationDictionary)
            }
        }
        else {
            conversations = []
        }
        
        if let lastPhotoDictionary = dictionary["lastPhoto"] as? [String: AnyObject] {
            lastPhoto = Photo(dictionary: lastPhotoDictionary)
        }
    }
}
