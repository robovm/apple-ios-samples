/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This code sample shows how to fetch all subscriptions from the private database.
*/

import CloudKit

class FetchAllSubscriptionsSample: CodeSample {
    
    init() {
        super.init(
            title: "fetchAllSubscriptionsWithCompletionHandler",
            className: "CKDatabase",
            methodName: ".fetchAllSubscriptionsWithCompletionHandler()",
            descriptionKey: "Subscriptions.FetchAllSubscriptions"
        )
    }
    
    override func run(completionHandler: (Results, NSError!) -> Void) {
            
        let container = CKContainer.defaultContainer()
        let privateDB = container.privateCloudDatabase
        
        privateDB.fetchAllSubscriptionsWithCompletionHandler {
            
            (subscriptions, nsError) in
            
            let results = Results(alwaysShowAsList: true)
            
            if let subscriptions = subscriptions {
                if subscriptions.count == 0 {
                    self.listHeading = "No Subscriptions"
                } else {
                    self.listHeading = "Subscriptions:"
                    for subscription in subscriptions {
                        results.items.append(subscription)
                    }
                }
            }
            
            completionHandler(results, nsError)
        }
        
    }
    
    
    
}

