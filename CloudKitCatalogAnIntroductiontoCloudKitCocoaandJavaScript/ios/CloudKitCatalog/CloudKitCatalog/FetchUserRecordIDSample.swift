/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This sample shows how to fetch the signed in user's user record ID.
*/

import CloudKit

class FetchUserRecordIDSample: CodeSample {
    
    init() {
        super.init(
            title: "fetchUserRecordIDWithCompletionHandler",
            className: "CKContainer",
            methodName: ".fetchUserRecordIDWithCompletionHandler()",
            descriptionKey: "Discoverability.FetchUserRecordID"
        )
    }
    
    override func run(completionHandler: (Results, NSError!) -> Void) {
        
        let container = CKContainer.defaultContainer()
        
        container.fetchUserRecordIDWithCompletionHandler {
            (recordID, nsError) in
            
            let results = Results()

            if let recordID = recordID {
                results.items.append(recordID)
            }
            
            completionHandler(results, nsError)
        }
        
    }
    
}
