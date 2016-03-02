/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This sample demonstrates how to fetch all record zones of the private database.
*/

import CloudKit

class FetchAllRecordZonesSample: CodeSample {
    
    init() {
        super.init(
            title: "fetchAllRecordZonesWithCompletionHandler",
            className: "CKDatabase",
            methodName: ".fetchAllRecordZonesWithCompletionHandler()",
            descriptionKey: "Zones.FetchAllRecordZones"
        )
    }
    
    override func run(completionHandler: (Results, NSError!) -> Void) {
        
        let container = CKContainer.defaultContainer()
        let privateDB = container.privateCloudDatabase
        
        privateDB.fetchAllRecordZonesWithCompletionHandler {
            (zones, nsError) in
            
            let results = Results(alwaysShowAsList: true)
            
            if let zones = zones where zones.count > 0 {
                for zone in zones {
                    results.items.append(zone)
                }
                self.listHeading = "Zones:"
            } else {
                self.listHeading = "No Zones"
            }
            
            completionHandler(results, nsError)
            
        }
        
    }
}
