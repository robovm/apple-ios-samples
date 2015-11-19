/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This contains all the CloudKit functions used by this sample.
 */

@import UIKit;
@import Foundation;
@import CloudKit;

@interface APLCloudManager : NSObject

+ (NSString *)PhotoRecordType;
+ (NSString *)PhotoAssetAttribute;
+ (NSString *)PhotoTitleAttribute;
+ (NSString *)PhotoDateAttribute;
+ (NSString *)PhotoLocationAttribute;

@property (NS_NONATOMIC_IOSONLY, getter=isContainerAvailable, readonly) BOOL containerAvailable;

// user info discovery
@property (readonly) CKRecordID *userRecordID;
- (void)updateUserLogin:(void (^)(void))completionHandler;
- (BOOL)userLoginIsValid;
- (void)accountAvailable:(void (^)(BOOL available))completionHandler;
- (void)fetchLoggedInUserRecord:(void (^)(CKRecordID *recordID))completionHandler;
- (void)fetchUserNameFromRecordID:(CKRecordID *)recordID completionHandler:(void (^)(NSString *firstName, NSString *lastName))completionHandler;

- (void)fetchAllUsers:(void (^)(NSArray *userRecords))completionHandler;

// fetch all records by given type
- (void)fetchRecordsWithType:(NSString *)recordType completionHandler:(void (^)(NSArray *records, NSError *error))completionHandler;

// fetch for a record by recordID
- (void)fetchRecordWithID:(CKRecordID *)recordID completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler;

// fetch for records by location
- (void)fetchRecordsNearLocation:(CLLocation *)location completionHandler:(void (^)(NSArray *records, NSError *error))completionHandler;

// fetch for records by recent date
- (void)fetchRecentRecords:(NSInteger)days completionHandler:(void (^)(NSArray *records, NSError *error))completionHandler;

// fetch for all our own records
- (void)fetchMyRecords:(void (^)(NSArray *records, NSError *error))completionHandler;

// delete and save
- (void)deleteRecordWithID:(CKRecordID *)recordID completionHandler:(void (^)(CKRecordID *recordID, NSError *error))completionHandler;
- (void)deleteRecordsWithIDs:(NSArray *)recordIDs completionHandler:(void (^)(NSArray *deletedRecordIDs, NSError *error))completionHandler;
- (void)saveRecord:(CKRecord *)record completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler;
- (void)modifyRecord:(CKRecord *)record completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler;

- (BOOL)isMyRecord:(CKRecordID *)recordID;

// subscriptions
- (void)subscribe;
- (void)unsubscribe;
- (void)forceUnsubscribe;
- (void)markNotificationsAsAlreadyRead;

@end
