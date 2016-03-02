/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This file contains all classes and protocols relevant to a code sample and the generated results.
*/

import UIKit
import CloudKit
import CoreLocation

enum Change {
    case Modified
    case Deleted
    case Added
}

class Attribute {
    let key: String
    var value: String?
    var isNested: Bool = false
    
    var image: UIImage?
    
    init(key: String) {
        self.key = key
    }
    
    convenience init(key: String, value: String) {
        self.init(key: key)
        self.value = value
    }
    
    convenience init(key: String, value: String, isNested: Bool) {
        self.init(key: key, value: value)
        self.isNested = isNested
    }
    
    convenience init(key: String, value: String, image: UIImage) {
        self.init(key: key, value: value)
        self.image = image
    }
}

class AttributeGroup {
    var title: String
    var attributes = [Attribute]()
    
    init(title: String) {
        self.title = title
    }
    
    convenience init(title: String, attributes: [Attribute]) {
        self.init(title: title)
        self.attributes = attributes
    }
}

class Input {
    let label: String
    
    var isValid: Bool { return false }
    var isRequired = false
    var isHidden = false
    
    var toggleIndexes = [Int]()
    
    init(label: String) {
        self.label = label
    }
    
    convenience init(label: String, isRequired: Bool) {
        self.init(label: label)
        self.isRequired = isRequired
    }
    
    convenience init(label: String, toggleIndexes: [Int]) {
        self.init(label: label)
        self.toggleIndexes = toggleIndexes
    }
    
}

class SelectionInput: Input {
    
    var items: [Input] = []
    
    override var isValid: Bool { return true }
    
    var value: Int?
    
    init(label: String, items: [Input]) {
        super.init(label: label)
        self.items = items
        if self.items.count > 0 {
            self.value = 0
        }
    }
}

enum TextInputType {
    case Text
    case Email
}

class LocationInput: Input {

    var longitude: Int?
    var latitude: Int?
    
    override var isValid: Bool {
        guard let latitude = latitude else { return longitude == nil && !isRequired }
        guard let longitude = longitude else { return false }
        return -90 <= latitude && latitude <= 90 && -180 <= longitude  && longitude <= 180
    }
    
}

class ImageInput: Input {
    
    var value: NSURL?
    
    override var isValid: Bool {
        return !isRequired || value != nil
    }
    
}

class BooleanInput: Input {
    
    var value = true
    
    override var isValid: Bool {
        return true
    }
    
    init(label: String, value: Bool) {
        super.init(label: label)
        self.value = value
    }
    
    convenience init(label: String, value: Bool, isHidden: Bool) {
        self.init(label: label, value: value)
        self.isHidden = isHidden
    }
    
}

class TextInput: Input {

    var type: TextInputType = .Text

    var value = ""
    
    override var isValid: Bool {
        return !isRequired || !value.isEmpty
    }
    
    init(label: String, value: String) {
        super.init(label: label)
        self.value = value
    }
    
    convenience init(label: String, value: String, isHidden: Bool) {
        self.init(label: label, value: value)
        self.isHidden = isHidden
    }

    convenience init(label: String, value: String, isRequired: Bool) {
        self.init(label: label, value: value)
        self.isRequired = isRequired
    }
    
    convenience init(label: String, value: String, isRequired: Bool, type: TextInputType) {
        self.init(label: label, value: value, isRequired: isRequired)
        self.type = type
    }
    
}


protocol Result {
    var summaryField: String? { get }
    var attributeList: [AttributeGroup] { get }
}

class NoResults: Result {
    let summaryField: String? = nil
    var attributeList: [AttributeGroup] {
        return [ AttributeGroup(title: "No Results") ]
    }
}

class Results {
    var items: [Result]
    
    init(items: [Result] = [], alwaysShowAsList: Bool = false) {
        self.items = items
        self.alwaysShowAsList = alwaysShowAsList
    }
    
    var moreComing = false
    var added: Set<Int> = []
    var modified: Set<Int> = []
    var deleted: Set<Int> = []
    
    var alwaysShowAsList = false
    
    var showAsList: Bool {
        get {
            return items.count > 1 || alwaysShowAsList
        }
    }
    
    func reset() {
        items = []
        moreComing = false
        added = []
        modified = []
        deleted = []
    }
}

class CodeSample {
    
    let title: String
    let className: String
    let methodName: String
    let description: String
    
    var inputs: [Input]
    
    init(title: String, className: String, methodName: String, descriptionKey: String, inputs: [Input] = []) {
        self.title = title
        self.className = className
        self.methodName = methodName
        self.description = NSLocalizedString(descriptionKey, comment: "Code Sample Description")
        self.inputs = inputs
    }
    
    var listHeading = ""
    
    var error: String? { return nil }
    
    var data: [String:Any] {
        var _data = [String:Any]()
        for input in inputs {
            if let textInput = input as? TextInput {
                _data[textInput.label] = textInput.value
            } else if let location = input as? LocationInput, latitude = location.latitude, longitude = location.longitude {
                _data[location.label] = CLLocation(latitude: Double(latitude), longitude: Double(longitude))
            } else if let image = input as? ImageInput, url = image.value {
                _data[image.label] = url
            } else if let boolean = input as? BooleanInput {
                _data[boolean.label] = boolean.value
            } else if let selection = input as? SelectionInput, index = selection.value {
                _data[selection.label] = selection.items[index].label
            }

        }
        return _data
    }
    
    func run(completionHandler: (Results, NSError!) -> Void) {
        completionHandler(Results(),nil)
    }

}