/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Struct that models an individual product.
*/

import Foundation

/// A struct that maps to the products contained inside the ProductsList.plist file.
struct Product {
    // MARK: Types
    
    /// Allowable keys for a `Product`'s dictionary representation.
    enum DictionaryKey: String {
        case Name           = "name"
        case Description    = "description"
        case Price          = "price"
    }
    
    // MARK: Properties
    
    var name: String
    var description: String
    var price: String
    
    // MARK: Initialization
    
    init(dictionary: [String: AnyObject]) {
        self.name = dictionary[DictionaryKey.Name.rawValue] as! String
        self.description = dictionary[DictionaryKey.Description.rawValue] as! String
        self.price = dictionary[DictionaryKey.Price.rawValue] as! String
    }
}
