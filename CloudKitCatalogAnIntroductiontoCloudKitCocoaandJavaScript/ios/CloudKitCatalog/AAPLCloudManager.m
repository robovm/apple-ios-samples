/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This contains all the CloudKit functions used by the View Controllers
 */

@import CloudKit;
#import "AAPLCloudManager.h"

NSString * const NameField = @"name";
NSString * const ParentField = @"parent";
NSString * const PhotoAssetField = @"photo";
NSString * const LocationField = @"location";
NSString * const ReferenceItemsRecordType = @"ReferenceItems";
NSString * const ReferenceSubItemsRecordType = @"ReferenceSubitems";

static NSString * const ItemRecordType = @"Items";
static NSString * const PhotoAssetRecordType = @"Photos";
static NSString * const subscriptionIDkey = @"subscriptionID";

@interface AAPLCloudManager ()

@property (readonly) CKContainer *container;
@property (readonly) CKDatabase *privateDatabase;

@end

@implementation AAPLCloudManager

- (id)init {
    self = [super init];
    if (self) {
        _container = [CKContainer defaultContainer];
        _privateDatabase = [_container privateCloudDatabase];
    }
    
    return self;
}

- (void)requestDiscoverabilityPermission:(void (^)(BOOL discoverable)) completionHandler {
    
    // Request permission to use discoverability. This will prompt the user.
    [self.container requestApplicationPermission:CKApplicationPermissionUserDiscoverability
                               completionHandler:^(CKApplicationPermissionStatus applicationPermissionStatus, NSError *error) {
                                   if (error) {
                                       // In your app, handle this error really beautifully.
                                       NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                                       abort();
                                   } else {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           completionHandler(applicationPermissionStatus == CKApplicationPermissionStatusGranted);
                                       });
                                   }
                               }];
}

- (void)discoverUserInfo:(void (^)(CKDiscoveredUserInfo *user))completionHandler {
    
    // Get the RecordID of the user that is logged into iCloud.
    [self.container fetchUserRecordIDWithCompletionHandler:^(CKRecordID *recordID, NSError *error) {
        
        if (error) {
            // In your app, handle this error in an awe-inspiring way.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            // Discover user info (first name and last name) using the user's RecordID.
            [self.container discoverUserInfoWithUserRecordID:recordID
                                           completionHandler:^(CKDiscoveredUserInfo *user, NSError *error) {
                                               if (error) {
                                                   // In your app, handle this error deftly.
                                                   NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                                                   abort();
                                               } else {
                                                   dispatch_async(dispatch_get_main_queue(), ^(void){
                                                       completionHandler(user);
                                                   });
                                               }
                                           }];
        }
    }];
}

- (void)uploadAssetWithURL:(NSURL *)assetURL completionHandler:(void (^)(CKRecord *record))completionHandler {
    
    // Create a CKRecord and set the CKAsset in the "photo" asset field.
    CKRecord *assetRecord = [[CKRecord alloc] initWithRecordType:PhotoAssetRecordType];
    CKAsset *photo = [[CKAsset alloc] initWithFileURL:assetURL];
    assetRecord[PhotoAssetField] = photo;
    
    // Save the CKRecord to the private database.
    [self.privateDatabase saveRecord:assetRecord completionHandler:^(CKRecord *record, NSError *error) {
        if (error) {
            // In your app, masterfully handle this error.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(record);
            });
        }
    }];
}

- (void)addRecordWithName:(NSString *)name location:(CLLocation *)location inZone:(CKRecordZone*) zone completionHandler:(void (^)(CKRecord *record))completionHandler {
    
    // Create a CKRecord and set the "name" and "location" fields.
    CKRecord *record = [[CKRecord alloc] initWithRecordType:ItemRecordType zoneID:zone.zoneID];
    record[NameField] = name;
    record[LocationField] = location;
    
    // Save the CKRecord to the private database.
    [self.privateDatabase saveRecord:record completionHandler:^(CKRecord *record, NSError *error) {
        if (error) {
            // In your app, handle this error like a pro.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(record);
            });
        }
    }];
}

- (void)fetchRecordWithID:(NSString *)recordID completionHandler:(void (^)(CKRecord *record))completionHandler {
    
    // Create a CKRecord with the RecordName.
    CKRecordID *current = [[CKRecordID alloc] initWithRecordName:recordID];
    
    // Fetch the CKRecord from the private database.
    [self.privateDatabase fetchRecordWithID:current completionHandler:^(CKRecord *record, NSError *error) {
        
        if (error) {
            // In your app, handle this error gracefully.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(record);
            });
        }
    }];
}

- (void)queryForRecordsNearLocation:(CLLocation *)location completionHandler:(void (^)(NSArray *records))completionHandler {
    
    CGFloat radiusInKilometers = 5;
    
    // Create a NSPredicate to get records near the location.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"distanceToLocation:fromLocation:(location, %@) < %f", location, radiusInKilometers];
    
    // Create a CKQuery with the NSPredicate.
    CKQuery *query = [[CKQuery alloc] initWithRecordType:ItemRecordType predicate:predicate];
    
    // Create a CKQueryOperation with the query.
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    // Add records to the results array as they come back.
    [queryOperation setRecordFetchedBlock:^(CKRecord *record) {
        [results addObject:record];
    }];
    
    // The query completion block will be called after all records are fetched.
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (error) {
            // In your app, handle this error with such perfection that your users will never realize an error occurred.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(results);
            });
        }
    };
    
    [self.privateDatabase addOperation:queryOperation];
}

- (void)saveRecord:(CKRecord *)record {
    
    // Save the CKRecord to the private database.
    [self.privateDatabase saveRecord:record completionHandler:^(CKRecord *record, NSError *error) {
        if (error) {
            // In your app, handle this error awesomely.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            NSLog(@"Successfully saved record");
        }
    }];
}

- (void)deleteRecord:(CKRecord *)record {
    
    // Delete the CKRecord from the private database.
    [self.privateDatabase deleteRecordWithID:record.recordID completionHandler:^(CKRecordID *recordID, NSError *error) {
        if (error) {
            // In your app, handle this error. Please.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            NSLog(@"Successfully deleted record");
        }
    }];
}

- (void)fetchRecordsWithType:(NSString *)recordType completionHandler:(void (^)(NSArray *records))completionHandler {
    
    NSPredicate *truePredicate = [NSPredicate predicateWithValue:YES];
    
    // Create a CKQuery with true predicate. This returns all records.
    CKQuery *query = [[CKQuery alloc] initWithRecordType:recordType predicate:truePredicate];
    
    // Create a CKQueryOperation with the query.
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    // Just request the name field for all records.
    queryOperation.desiredKeys = @[NameField];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    // Add results to the results array as they come back.
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
    };
    
    // The query completion block will be called after all records are fetched.
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (error) {
            // In your app, this error needs love and care.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(results);
            });
        }
    };
    
    // Add the operation to the private database. The operation will be executed immediately.
    [self.privateDatabase addOperation:queryOperation];
}

- (void)queryForRecordsWithReferenceNamed:(NSString *)referenceRecordName completionHandler:(void (^)(NSArray *records))completionHandler {
    
    // Create a CKRecordID with the RecordName.
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:referenceRecordName];
    
    // Create a CKReference with the parent RecordID.
    CKReference *parent = [[CKReference alloc] initWithRecordID:recordID action:CKReferenceActionNone];
    
    // Create a NSPredicate that checks the "parent" reference field.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", parent];
    
    // Create a query with the predicate.
    CKQuery *query = [[CKQuery alloc] initWithRecordType:ReferenceSubItemsRecordType predicate:predicate];
    
    // Create a CKQueryOperation with the query.
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    // Just request the name field for all records.
    queryOperation.desiredKeys = @[NameField];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    // Add results to the results array as they come back.
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
    };
    
    // The query completion block will be called after all records are fetched.
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (error) {
            // In your app, you should do the Right Thing
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            abort();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(results);
            });
        }
    };
    
    // Add the operation to the private database. The operation will be executed immediately.
    [self.privateDatabase addOperation:queryOperation];
}

- (void)subscribe {
    
    if (self.subscribed == NO) {
        
        NSPredicate *truePredicate = [NSPredicate predicateWithValue:YES];
        
        // Create a CKSubscription with true predicate. The subscription will be triggered when any record is added to the RecordType.
        CKSubscription *itemSubscription = [[CKSubscription alloc] initWithRecordType:ItemRecordType
                                                                            predicate:truePredicate
                                                                              options:CKSubscriptionOptionsFiresOnRecordCreation];
        
        // Create CKNotificationInfo which is the payload for the push notification.
        CKNotificationInfo *notification = [[CKNotificationInfo alloc] init];
        notification.alertBody = @"New Item Added!";
        itemSubscription.notificationInfo = notification;
        
        // Save the subscription to the private database.
        [self.privateDatabase saveSubscription:itemSubscription completionHandler:^(CKSubscription *subscription, NSError *error) {
            if (error) {
                // In your app, handle this error appropriately.
                NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                abort();
            } else {
                NSLog(@"Subscribed to Item");
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setBool:YES forKey:@"subscribed"];
                [defaults setObject:subscription.subscriptionID forKey:subscriptionIDkey];
            }
        }];
    }
}

- (void)unsubscribe {
    if (self.subscribed == YES) {
        
        NSString *subscriptionID = [[NSUserDefaults standardUserDefaults] objectForKey:subscriptionIDkey];
        
        // Create an operation to modify the subscription with the subscriptionID.
        CKModifySubscriptionsOperation *modifyOperation = [[CKModifySubscriptionsOperation alloc] init];
        modifyOperation.subscriptionIDsToDelete = @[subscriptionID];
        
        // The completion block will be executed after the modify operation is executed.
        modifyOperation.modifySubscriptionsCompletionBlock = ^(NSArray *savedSubscriptions, NSArray *deletedSubscriptionIDs, NSError *error) {
            if (error) {
                // In your app, handle this error beautifully.
                NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                abort();
            } else {
                NSLog(@"Unsubscribed to Item");
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:subscriptionIDkey];
            }
        };
        
        // Add the operation to the private database. The operation will be executed immediately.
        [self.privateDatabase addOperation:modifyOperation];
    }
}

- (BOOL)isSubscribed {
    return [[NSUserDefaults standardUserDefaults] objectForKey:subscriptionIDkey] != nil;
}

@end
