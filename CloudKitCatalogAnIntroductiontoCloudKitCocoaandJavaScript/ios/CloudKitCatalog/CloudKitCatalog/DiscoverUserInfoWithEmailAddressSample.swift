/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This sample shows how to get discoverable user information from an email address.
*/

import CloudKit

class DiscoverUserInfoWithEmailAddressSample: CodeSample {
    
    init() {
        super.init(
            title: "discoverUserInfoWithEmailAddress",
            className: "CKContainer",
            methodName: ".discoverUserInfoWithEmailAddress()",
            descriptionKey: "Discoverability.DiscoverUserInfoWithEmailAddress",
            inputs: [
                TextInput(label: "emailAddress", value: "", isRequired: true, type: .Email)
            ]
        )
    }
    
    override func run(completionHandler: (Results, NSError!) -> Void) {
        
        if let emailAddress = data["emailAddress"] as? String {
            
            let container = CKContainer.defaultContainer()
            
            container.discoverUserInfoWithEmailAddress(emailAddress) {
                (userInfo, nsError) in
                
                let results = Results()
                
                if let userInfo = userInfo {
                    results.items.append(userInfo)
                }
                
                completionHandler(results, nsError)
            }
        }
        
    }
}
