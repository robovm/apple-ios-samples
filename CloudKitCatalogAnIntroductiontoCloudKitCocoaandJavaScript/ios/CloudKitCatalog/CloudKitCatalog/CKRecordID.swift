/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This extends CKRecordID to conform to the Result protocol.
*/

import CloudKit

extension CKRecordID: Result {
    var summaryField: String? { return recordName }
    var attributeList: [AttributeGroup] {
        let zoneName = zoneID.zoneName
        let ownerName = zoneID.ownerName
        return [
            AttributeGroup(title: "Record ID:", attributes: [
                Attribute(key: "recordName", value: recordName),
                Attribute(key: "zoneID"),
                Attribute(key: "zoneName", value: zoneName, isNested: true),
                Attribute(key: "ownerName", value: ownerName, isNested: true)
            ])
        ]
    }
}
