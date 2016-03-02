/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This code sample demonstrates how to save a subscription to the private database.
*/

import CloudKit

class SaveSubscriptionSample: CodeSample {
    
    init() {
        super.init(
            title: "saveSubscription",
            className: "CKDatabase",
            methodName: ".saveSubscription()",
            descriptionKey: "Subscriptions.SaveSubscription",
            inputs: [
                SelectionInput(label: "subscriptionType", items: [
                    Input(label: "RecordZone", toggleIndexes: [1]),
                    Input(label: "Query", toggleIndexes: [2,3,4,5,6])
                    ]),
                TextInput(label: "zoneName", value: ""),
                TextInput(label: "name BEGINSWITH", value: "", isHidden: true),
                BooleanInput(label: "FiresOnRecordCreation", value: true, isHidden: true),
                BooleanInput(label: "FiresOnRecordUpdate", value: true, isHidden: true),
                BooleanInput(label: "FiresOnRecordDeletion", value: true, isHidden: true),
                BooleanInput(label: "FiresOnce", value: false, isHidden: true)
            ]
        )
    }
    
    override var error: String? {
        if let subscriptionType = data["subscriptionType"] as? String where subscriptionType == "RecordZone", let zoneName = data["zoneName"] as? String {
            if zoneName.isEmpty {
                return "zoneName cannot be empty"
            } else if zoneName == CKRecordZoneDefaultName {
                return "Cannot create a subscription on the Default Zone"
            }
        }
        return nil
    }
    
    override func run(completionHandler: (Results, NSError!) -> Void) {
        
        if let subscriptionType = data["subscriptionType"] as? String {
            
            let container = CKContainer.defaultContainer()
            let privateDB = container.privateCloudDatabase
            
            let subscription: CKSubscription
            
            let notificationInfo = CKNotificationInfo()
            
            let recordType = "Items"
            
            notificationInfo.shouldBadge = true
            
            if let zoneName = data["zoneName"] as? String where subscriptionType == "RecordZone" {
                
                let zoneID = CKRecordZoneID(zoneName: zoneName, ownerName: CKOwnerDefaultName)
                subscription = CKSubscription(zoneID: zoneID, options: CKSubscriptionOptions(rawValue: 0))
                
                notificationInfo.alertBody = "Zone \(zoneName) has changed."
                subscription.notificationInfo = notificationInfo
                
            } else {
                let predicate: NSPredicate
                
                var subscriptionOptions = CKSubscriptionOptions(rawValue: 0)
                if let firesOnRecordCreation = data["FiresOnRecordCreation"] as? Bool where firesOnRecordCreation {
                    subscriptionOptions.unionInPlace(CKSubscriptionOptions.FiresOnRecordCreation)
                }
                if let firesOnRecordUpdate = data["FiresOnRecordUpdate"] as? Bool where firesOnRecordUpdate {
                    subscriptionOptions.unionInPlace(CKSubscriptionOptions.FiresOnRecordUpdate)
                }
                if let firesOnRecordDeletion = data["FiresOnRecordDeletion"] as? Bool where firesOnRecordDeletion {
                    subscriptionOptions.unionInPlace(CKSubscriptionOptions.FiresOnRecordDeletion)
                }
                if let firesOnce = data["FiresOnce"] as? Bool where firesOnce {
                    subscriptionOptions.unionInPlace(CKSubscriptionOptions.FiresOnce)
                }
                
                if let beginsWithText = data["name BEGINSWITH"] as? String {
                    predicate = NSPredicate(format: "name BEGINSWITH %@", beginsWithText)
                } else {
                    predicate = NSPredicate(value: true)
                }
                subscription = CKSubscription(recordType: recordType, predicate: predicate, options: subscriptionOptions)
                
                notificationInfo.alertBody = "Changed \(recordType) satisfying \(predicate.predicateFormat)"
                subscription.notificationInfo = notificationInfo
            }
            
            privateDB.saveSubscription(subscription) {
                
                (subscription, nsError) in
                
                let results = Results()
                
                if let subscription = subscription {
                    results.items.append(subscription)
                }
                
                completionHandler(results, nsError)
            }
            
        }
        
    }
    
    
}
