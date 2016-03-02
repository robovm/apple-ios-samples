/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This sample shows how to get discoverable user information from a user record ID.
*/

import CloudKit

class DiscoverUserInfoWithUserRecordIDSample: CodeSample {
    
    init() {
        super.init(
            title: "discoverUserInfoWithUserRecordID",
            className: "CKContainer",
            methodName: ".discoverUserInfoWithUserRecordID()",
            descriptionKey: "Discoverability.DiscoverUserInfoWithUserRecordID",
            inputs: [
                TextInput(label: "recordName", value: "", isRequired: true),
                TextInput(label: "zoneName", value: CKRecordZoneDefaultName, isRequired: true)
            ]
        )
    }
    
    override func run(completionHandler: (Results, NSError!) -> Void) {
        
        if let recordName = data["recordName"] as? String, let zoneName = data["zoneName"] as? String {
            
            let container = CKContainer.defaultContainer()
        
            let zoneID = CKRecordZoneID(zoneName: zoneName, ownerName: CKOwnerDefaultName)
            let userRecordID = CKRecordID(recordName: recordName, zoneID: zoneID)
            
            container.discoverUserInfoWithUserRecordID(userRecordID) {
                
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
