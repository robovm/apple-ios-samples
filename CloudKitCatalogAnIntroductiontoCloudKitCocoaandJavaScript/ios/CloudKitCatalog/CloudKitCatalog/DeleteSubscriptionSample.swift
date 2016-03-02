/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This code sample demonstrates how to delete a subscription by ID.
*/

import CloudKit

class SubscriptionIDResult: Result {
    let subscriptionID: String
    
    init(subscriptionID: String) {
        self.subscriptionID = subscriptionID
    }
    
    var summaryField: String? = nil
    
    var attributeList: [AttributeGroup] {
        return [
            AttributeGroup(title: "", attributes: [
                Attribute(key: "subscriptionID", value: subscriptionID)
            ])
        ]
    }
    
}

class DeleteSubscriptionSample: CodeSample {
    
    init() {
        super.init(
            title: "deleteSubscription",
            className: "CKDatabase",
            methodName: ".deleteSubscriptionWithID()",
            descriptionKey: "Subscriptions.DeleteSubscription",
            inputs: [
                TextInput(label: "subscriptionID", value: "", isRequired: true)
            ]
        )
    }
    
    override func run(completionHandler: (Results, NSError!) -> Void) {
        
        if let subscriptionID = data["subscriptionID"] as? String {
            
            let container = CKContainer.defaultContainer()
            let privateDB = container.privateCloudDatabase
            
            privateDB.deleteSubscriptionWithID(subscriptionID) {
                
                (subscriptionID, nsError) in
                
                let results = Results()
                
                if let subscriptionID = subscriptionID {
                    results.items.append(SubscriptionIDResult(subscriptionID: subscriptionID))
                }
                
                completionHandler(results, nsError)
            }
            
        }
        
    }
    
    
}
