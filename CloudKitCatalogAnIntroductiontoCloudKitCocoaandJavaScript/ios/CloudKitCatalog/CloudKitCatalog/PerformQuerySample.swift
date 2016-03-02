/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This sample demonstrates how to retrieve Items records sorted by closest distance to
                a user-provided location using a query on the public database.
*/

import CloudKit

class PerformQuerySample: CodeSample {
    
    init() {
        super.init(
            title: "performQuery",
            className: "CKDatabase",
            methodName: ".performQuery()",
            descriptionKey: "Query.PerformQuery",
            inputs: [
                LocationInput(label: "Location", isRequired: true)
            ]
        )
    }
    
    override func run(completionHandler: (Results, NSError!) -> Void) {
        
        if let location = data["Location"] as? CLLocation {
            
            let container = CKContainer.defaultContainer()
            let publicDB = container.publicCloudDatabase
            
            let query = CKQuery(recordType: "Items", predicate: NSPredicate(value: true))
            query.sortDescriptors = [
                CKLocationSortDescriptor(key: "location", relativeLocation: location)
            ]
            
            publicDB.performQuery(query, inZoneWithID: nil) {
                (recordArray, nsError) in
                
                let results = Results(alwaysShowAsList: true)
                
                if let recordArray = recordArray {
                    switch recordArray.count {
                    case 0:
                        self.listHeading = "No matching items"
                    case 1:
                        self.listHeading = "Found 1 matching item:"
                    default:
                        self.listHeading = "Found \(recordArray.count) matching items:"
                    }
                    for record in recordArray {
                        results.items.append(record)
                    }
                }
                
                completionHandler(results, nsError)
            }
        }
        
    }
    
}
