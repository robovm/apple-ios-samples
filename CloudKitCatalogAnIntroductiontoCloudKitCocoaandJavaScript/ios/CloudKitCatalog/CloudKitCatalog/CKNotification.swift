/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This extends CKNotification to conform to the Result protocol.
*/

import CloudKit

extension CKNotification: Result {
    var summaryField: String? {
        let subscriptionID = self.subscriptionID ?? "unknown subscription"
        return alertBody ?? "\(notificationTypeString) notification for \(subscriptionID)."
    }
    
    var notificationTypeString: String {
        switch notificationType {
        case .Query:
            return "Query"
        case .ReadNotification:
            return "ReadNotification"
        case .RecordZone:
            return "RecordZone"
        }
    }
    
    var attributeList: [AttributeGroup] {
        return [
            AttributeGroup(title: "", attributes: [
                Attribute(key: "notificationID.hashValue", value: String(notificationID!.hashValue)),
                Attribute(key: "notificationType", value: notificationTypeString),
                Attribute(key: "alertBody", value: alertBody ?? "-"),
                Attribute(key: "soundName", value: soundName ?? "-"),
                Attribute(key: "badge", value: badge != nil ? String(badge) : "-"),
                Attribute(key: "category", value: category ?? "-"),
                Attribute(key: "subscriptionID", value: subscriptionID ?? "-")
            ])
        ]
    }
}
