/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This sample demonstrates how to get the discoverable user information of each user of the app
                in the signed in user's address book.
*/

import CloudKit

class DiscoverAllContactUserInfosSample: CodeSample {
    
    init() {
        super.init(
            title: "discoverAllContactUserInfosWithCompletionHandler",
            className: "CKContainer",
            methodName: ".discoverAllContactUserInfosWithCompletionHandler()",
            descriptionKey: "Discoverability.DiscoverAllContactUserInfos"
        )
    }
    
    override func run(completionHandler: (Results, NSError!) -> Void) {
        
        let container = CKContainer.defaultContainer()
        
        container.discoverAllContactUserInfosWithCompletionHandler {
            (userInfos, nsError) in
            
            let results = Results(alwaysShowAsList: true)
            
            if let userInfos = userInfos where userInfos.count > 0 {
                for userInfo in userInfos {
                    results.items.append(userInfo)
                }
                self.listHeading = "Discovered User Infos:"
            } else {
                self.listHeading = "No Discoverable Users Found"
            }
            
            completionHandler(results, nsError)
            
        }
        
    }
}
