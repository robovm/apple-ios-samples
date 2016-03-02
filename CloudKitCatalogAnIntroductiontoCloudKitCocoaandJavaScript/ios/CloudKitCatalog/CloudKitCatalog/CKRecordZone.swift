/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This extends CKRecordZone to conform to the Result protocol.
*/

import CloudKit

extension CKRecordZone: Result {
    var summaryField: String? {
        return zoneID.zoneName
    }
    var attributeList: [AttributeGroup] {
        return [
            AttributeGroup(title: "Record Zone:", attributes: [
                Attribute(key: "zoneID"),
                Attribute(key: "zoneName", value: zoneID.zoneName, isNested: true),
                Attribute(key: "ownerName", value: zoneID.ownerName, isNested: true),
                Attribute(key: "capabilities"),
                Attribute(key: "FetchChanges", value: capabilities.contains(.FetchChanges) ? "true" : "false", isNested: true),
                Attribute(key: "Atomic", value: capabilities.contains(.Atomic) ? "true" : "false", isNested: true)
            ])
        ]
    }
}
