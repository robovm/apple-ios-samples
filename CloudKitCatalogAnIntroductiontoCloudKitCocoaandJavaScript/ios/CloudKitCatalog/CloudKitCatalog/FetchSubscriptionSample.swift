/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This code sample demonstrates how to fetch a subscription by ID.
*/

import CloudKit

class FetchSubscriptionSample: CodeSample {
    
    
    init() {
        super.init(
            title: "fetchSubscriptionWithID",
            className: "CkDatabase",
            methodName: ".fetchSubscriptionWithID()",
            descriptionKey: "Subscriptions.FetchSubscription",
            inputs: [
                TextInput(label: "subscriptionID", value: "", isRequired: true)
            ]
        )
    }
    
    override func run(completionHandler: (Results, NSError!) -> Void) {
        
        if let subscriptionID = data["subscriptionID"] as? String {
            
            let container = CKContainer.defaultContainer()
            let privateDB = container.privateCloudDatabase
            
            privateDB.fetchSubscriptionWithID(subscriptionID) {
                
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
