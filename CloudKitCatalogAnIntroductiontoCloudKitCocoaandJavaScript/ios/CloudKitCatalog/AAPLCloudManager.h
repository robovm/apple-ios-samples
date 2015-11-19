/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This contains all the CloudKit functions used by the View Controllers
*/

@import UIKit;
@import Foundation;
@import CloudKit;

@class AAPLUsers;

extern NSString * const NameField;
extern NSString * const ParentField;
extern NSString * const PhotoAssetField;
extern NSString * const LocationField;
extern NSString * const ReferenceItemsRecordType;
extern NSString * const ReferenceSubItemsRecordType;

@interface AAPLCloudManager : NSObject

- (void)requestDiscoverabilityPermission:(void (^)(BOOL discoverable))completionHandler;
- (void)discoverUserInfo:(void (^)(CKDiscoveredUserInfo *user))completionHandler;

- (void)uploadAssetWithURL:(NSURL *)assetURL completionHandler:(void (^)(CKRecord *record))completionHandler;
- (void)addRecordWithName:(NSString *)name location:(CLLocation *)location inZone:(CKRecordZone*) zone completionHandler:(void (^)(CKRecord *record))completionHandler;

- (void)fetchRecordWithID:(NSString *)recordID completionHandler:(void (^)(CKRecord *record))completionHandler;
- (void)queryForRecordsNearLocation:(CLLocation *)location completionHandler:(void (^)(NSArray *records))completionHandler;

- (void)saveRecord:(CKRecord *)record;
- (void)deleteRecord:(CKRecord *)record;
- (void)fetchRecordsWithType:(NSString *)recordType completionHandler:(void (^)(NSArray *records))completionHandler;
- (void)queryForRecordsWithReferenceNamed:(NSString *)referenceRecordName completionHandler:(void (^)(NSArray *records))completionHandler;

@property (nonatomic, readonly, getter=isSubscribed) BOOL subscribed;
- (void)subscribe;
- (void)unsubscribe;

@end
