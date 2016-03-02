/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This extends CKRecordZoneID to conform to the Result protocol.
*/

import CloudKit

extension CKRecordZoneID: Result {
    var summaryField: String? {
        return zoneName
    }
    
    var attributeList: [AttributeGroup] {
        return [
            AttributeGroup(title: "Record Zone ID:", attributes: [
                Attribute(key: "zoneName", value: zoneName),
                Attribute(key: "ownerName", value: ownerName)
            ])
        ]
    }
}
