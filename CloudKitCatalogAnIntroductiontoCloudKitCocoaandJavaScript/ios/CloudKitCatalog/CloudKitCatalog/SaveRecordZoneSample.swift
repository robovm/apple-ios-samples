/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This sample shows how to save a record zone with a provided zone name.
*/

import CloudKit

class SaveRecordZoneSample: CodeSample {
    
    init() {
        super.init(
            title: "saveRecordZone",
            className: "CKDatabase",
            methodName: ".saveRecordZone()",
            descriptionKey: "Zones.SaveRecordZone",
            inputs: [
                TextInput(label: "zoneName", value: "", isRequired: true)
            ]
        )
    }
    
    override func run(completionHandler: (Results, NSError!) -> Void) {
        
        if let zoneName = data["zoneName"] as? String {
            
            let container = CKContainer.defaultContainer()
            let privateDB = container.privateCloudDatabase

            privateDB.saveRecordZone(CKRecordZone(zoneName: zoneName)) {
                
                (recordZone, nsError) in
                
                let results = Results()
                
                if let recordZone = recordZone {
                    results.items.append(recordZone)
                }
                
                completionHandler(results, nsError)
            }
        }
        
    }
    
    
}
