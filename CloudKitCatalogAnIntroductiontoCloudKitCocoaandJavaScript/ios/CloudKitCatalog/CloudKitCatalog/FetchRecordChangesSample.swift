/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This file contains a class which manages an in-memory cache of changed records from the result of
                a FetchRecordChangesOperation, as well as a code sample demonstrating how to fetch record changes 
                and paginate through the results on the server using the moreComing property on the response.
*/

import CloudKit

class ChangedRecords {
    var changeToken: CKServerChangeToken?
    
    private var results: Results = Results(alwaysShowAsList: true)
    private var recordsByID: [CKRecordID: CKRecord] = [:]
    
    func getRecordByID(recordID: CKRecordID) -> CKRecord? {
        return recordsByID[recordID]
    }
    
    func getRecords() -> Results {
        return results
    }
    
    func addRecord(record: CKRecord) {
        results.items.append(record)
        recordsByID[record.recordID] = record
        results.added.insert(results.items.count - 1)
    }
    
    private func indexOfRecordByRecordID(recordID: CKRecordID) -> Int? {
        return results.items.indexOf { result in
            if let result = result as? CKRecord {
                return result.recordID == recordID
            } else {
                return false
            }
        }
    }
    
    func markRecordAsModified(record: CKRecord) {
        if let index = indexOfRecordByRecordID(record.recordID) {
            results.modified.insert(index)
        }
    }
    
    func markRecordAsDeleted(recordID: CKRecordID) {
        if let index = indexOfRecordByRecordID(recordID) {
            results.deleted.insert(index)
        }
    }
    
    private func removeDeletedRecords() {
        for index in results.deleted {
            let record = results.items.removeAtIndex(index) as! CKRecord
            recordsByID[record.recordID] = nil
        }
    }
    
    func setMoreComing(bool: Bool) {
        results.moreComing = bool
    }
    
    func removeChanges() {
        removeDeletedRecords()
        results.added = []
        results.deleted = []
        results.modified = []
    }
    
    func reset() {
        changeToken = nil
        results.reset()
        recordsByID = [:]
    }
    
    
}

class FetchRecordChangesSample: CodeSample {
    
    init() {
        super.init(
            title: "CKFetchChangesOperation",
            className: "CKFetchChangesOperation",
            methodName: ".init(recordZoneID:previousServerChangeToken:)",
            descriptionKey: "Sync.FetchRecordChanges",
            inputs: [
                TextInput(label: "zoneName", value: "", isRequired: true),
                BooleanInput(label: "cache", value: true)
            ]
        )
        listHeading = "Records:"
    }
    
    var recordCache = [CKRecordZoneID: ChangedRecords]()
    
    override func run(completionHandler: (Results, NSError!) -> Void) {
        
        if let zoneName = data["zoneName"] as? String, shouldCache = data["cache"] as? Bool {
            
            let zoneID = CKRecordZoneID(zoneName: zoneName, ownerName: CKOwnerDefaultName)
            var cache = recordCache[zoneID]
            
            if cache == nil {
                cache = ChangedRecords()
                recordCache[zoneID] = cache
            }
            
            cache!.removeChanges()
            
            if !cache!.results.moreComing && !shouldCache {
                cache!.reset()
            }
            
            var changeToken: CKServerChangeToken? = nil
            
            if let token = cache!.changeToken where shouldCache || cache!.results.moreComing {
                changeToken = token
            }
            
            let operation = CKFetchRecordChangesOperation(recordZoneID: zoneID, previousServerChangeToken: changeToken)
        
            operation.desiredKeys = [ "name", "location" ]
            operation.resultsLimit = 2
                
            operation.recordChangedBlock = {
                (record) in
                
                if let cachedRecord = cache!.getRecordByID(record.recordID) {
                    for key in record.allKeys() {
                        cachedRecord.setObject(record.objectForKey(key), forKey: key)
                    }
                    cache!.markRecordAsModified(cachedRecord)
                } else {
                    cache!.addRecord(record)
                }
            }
            
            operation.recordWithIDWasDeletedBlock = {
                (recordID) in
                
                cache!.markRecordAsDeleted(recordID)
                
            }
            
            operation.fetchRecordChangesCompletionBlock = {
                (changeToken, nsData, nsError) in
                
                if nsError == nil {
                    cache!.changeToken = changeToken
                    
                    cache!.setMoreComing(operation.moreComing)
                }
                
                completionHandler(cache!.getRecords(),nsError)
                
            }

            operation.start()
        }
        
    }
}
