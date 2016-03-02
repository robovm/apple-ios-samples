/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This extends CKDisoveredUserInfo to conform to the Result protocol.
*/

import CloudKit
extension CKDiscoveredUserInfo: Result {
    var attributeList: [AttributeGroup] {
        guard let displayContact = displayContact else {
            return [
                AttributeGroup(title: "No displayContact")
            ]
        }
        var contactType = "-"
        switch displayContact.contactType {
        case .Organization:
            contactType = "Organization"
        case .Person:
            contactType = "Person"
        }
        return [
            AttributeGroup(title: "Display Contact:", attributes: [
                Attribute(key: "identifier", value: displayContact.identifier),
                Attribute(key: "contactType", value: contactType),
                Attribute(key: "givenName", value: displayContact.givenName),
                Attribute(key: "familyName", value: displayContact.familyName)
            ])
        ]
    }
    
    var summaryField: String? {
        guard let displayContact = displayContact else { return userRecordID!.recordName }
        return displayContact.givenName + " " + displayContact.familyName
        
    }
}

