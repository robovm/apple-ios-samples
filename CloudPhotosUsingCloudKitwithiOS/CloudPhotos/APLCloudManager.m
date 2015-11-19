/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This contains all the CloudKit functions used by this sample.
 */

@import CloudKit;

#import "APLCloudManager.h"

NSString * const kPhotoRecordType = @"PhotoRecord";     // our CKRecord type
NSString * const kPhotoAsset = @"PhotoAsset";           // CKAsset
NSString * const kPhotoTitle = @"PhotoTitle";           // NSString
NSString * const kPhotoDate = @"PhotoDate";             // NSDate
NSString * const kPhotoLocation = @"PhotoLocation";     // CLLocation


// generic, reusable utility routine for reporting possible CloudKit errors
void CloudKitErrorLog(int lineNumber, NSString *functionName, NSError *error)
{
    if (error != noErr)
    {
        NSMutableString *message = [NSMutableString stringWithFormat:@"ERROR[%@:%ld] ", error.domain, (long)error.code];
        if (error.localizedDescription != nil)
        {
            [message appendFormat:@"%@", error.localizedDescription];
        }
        if (error.localizedFailureReason != nil)
        {
            [message appendFormat:@", %@", error.localizedFailureReason];
        }
        
        if (error.userInfo[NSUnderlyingErrorKey] != nil)
        {
            [message appendFormat:@", %@", error.userInfo[NSUnderlyingErrorKey]];
        }
        
        if (error.localizedRecoverySuggestion != nil)
        {
            [message appendFormat:@", %@", error.localizedRecoverySuggestion];
        }
        [message appendFormat:@" - %@%d\n", functionName, lineNumber];
        NSLog(@"%@", message);
    }
}

@interface APLCloudManager ()

@property (readonly) CKContainer *container;
@property (readonly) CKDatabase *publicDatabase;

@property (readonly) CKDiscoveredUserInfo *userInfo;    // the current login user's information (first and last name)

@property (NS_NONATOMIC_IOSONLY, readonly, getter=isSubscribed) BOOL subscribed;

// used for marking notifications as "read", this token tells the server what portions of the records to fetch and return to your app
@property (nonatomic, strong) CKServerChangeToken *serverChangeToken;

@end


#pragma mark -

@implementation APLCloudManager

+ (NSString *)PhotoRecordType { return kPhotoRecordType; }
+ (NSString *)PhotoAssetAttribute { return kPhotoAsset; }
+ (NSString *)PhotoTitleAttribute { return kPhotoTitle; }
+ (NSString *)PhotoDateAttribute { return kPhotoDate; }
+ (NSString *)PhotoLocationAttribute { return kPhotoLocation; }

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _container = [CKContainer defaultContainer];
        _publicDatabase = [_container publicCloudDatabase];
    }
    return self;
}

- (BOOL)isContainerAvailable
{
    return (self.container != nil && self.publicDatabase != nil);
}


#pragma mark - Fetching

// fetch for a single record by record ID
//
- (void)fetchRecordWithID:(CKRecordID *)recordID completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler
{
    [self.publicDatabase fetchRecordWithID:recordID completionHandler:^(CKRecord *record, NSError *error) {
        
        // report any error but "record not found"
        if (error.code != CKErrorUnknownItem)
        {
            CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
        }
        
        // call the completion handler on the main queue
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(record, error);
        });
    }];
}

// fetch for multiple records by type
//
// We submit our CKQuery to a CKQueryOperation. The CKQueryOperation has the concept of cursor and a resultsLimit.
// This will allow you to bundle your query results into chunks, avoiding very long query times.
// In our case we limit to 10 at a time, and keep refetching more if available.
//
#define kResultsLimit 20

- (void)fetchRecordsWithType:(NSString *)recordType completionHandler:(void (^)(NSArray *records, NSError *error))completionHandler
{
    NSPredicate *truePredicate = [NSPredicate predicateWithValue:YES];  // find "all" records
    CKQuery *query = [[CKQuery alloc] initWithRecordType:recordType predicate:truePredicate];
    
    // note: if we want to sort by creationDate, use this: (the Dashboard needs to set this field as sortable)
    // query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    //
    // but in our case we sort alphabetically by the "kPhotoTitle" field
    query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:kPhotoTitle ascending:YES]];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    queryOperation.resultsLimit = kResultsLimit;
    queryOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    // request these attributes (important to get all attributes in favor if our APLDetailViewController)
    queryOperation.desiredKeys = @[kPhotoTitle, kPhotoAsset, kPhotoDate, kPhotoLocation];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    // defined our fetched record block so we can add records to our results array
    __block void (^recordFetchedBlock)(CKRecord *) = ^(CKRecord *record) {
        // found a record
        [results addObject:record];
    };
    queryOperation.recordFetchedBlock = recordFetchedBlock;
    
    // define and add our completion block to fetch possibly more records, or finish by calling our caller's completion block
    __weak __block void (^block_self)(CKQueryCursor *, NSError *);
    void (^myCompletionBlock)(CKQueryCursor *, NSError *) = [^(CKQueryCursor *cursor, NSError *error) {
        
        CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
        
        if (cursor != nil)
        {
            // there's more fetching to do
            CKQueryOperation *continuedQueryOperation = [[CKQueryOperation alloc] initWithCursor:cursor];
            continuedQueryOperation.queryCompletionBlock = block_self;
            continuedQueryOperation.recordFetchedBlock = recordFetchedBlock;
            [self.publicDatabase addOperation:continuedQueryOperation];
        }
        else
        {
            // back on the main queue, call our completion handler
            dispatch_async(dispatch_get_main_queue(), ^(void) {

                // call the completion handler
                completionHandler(results, error);
            });
        }
    } copy];
    block_self = myCompletionBlock;
    
    queryOperation.queryCompletionBlock = block_self;
    [self.publicDatabase addOperation:queryOperation];
}

// fetch for all records within a 30 kilometer radius of the input "location"
//
- (void)fetchRecordsNearLocation:(CLLocation *)location completionHandler:(void (^)(NSArray *records, NSError *error))completionHandler
{
    CGFloat radiusInKilometers = 30;
    NSPredicate *locationSearchPredicate =
        [NSPredicate predicateWithFormat:@"distanceToLocation:fromLocation:(PhotoLocation, %@) < %f", location, radiusInKilometers];
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType:kPhotoRecordType predicate:locationSearchPredicate];
    
    // note: if we want to sort by creationDate, use this: (the Dashboard needs to set this field as sortable)
    // query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    //
    // but in our case we sort alphabetically by the "kPhotoTitle" field
    query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:kPhotoTitle ascending:YES]];
    
    CKQueryOperation *photosNearQueryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    NSArray *desiredKeys = @[kPhotoTitle, kPhotoAsset, kPhotoDate, kPhotoLocation];
    photosNearQueryOperation.desiredKeys = desiredKeys;
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    // defined our fetched record block so we can add records to our results array
    __block void (^recordFetchedBlock)(CKRecord *) = ^(CKRecord *record) {
        // found a record
        [results addObject:record];
    };
    photosNearQueryOperation.recordFetchedBlock = recordFetchedBlock;
    
    // define and add our completion block to fetch possibly more records, or finish by calling our caller's completion block
    __weak __block void (^block_self)(CKQueryCursor *, NSError *);
    void (^myCompletionBlock)(CKQueryCursor *, NSError *) = [^(CKQueryCursor *cursor, NSError *error) {

        CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
        
        if (cursor != nil)
        {
            // there's more fetching to do
            CKQueryOperation *continuedQueryOperation = [[CKQueryOperation alloc] initWithCursor:cursor];
            continuedQueryOperation.desiredKeys = desiredKeys;
            continuedQueryOperation.queryCompletionBlock = block_self;
            continuedQueryOperation.recordFetchedBlock = recordFetchedBlock;
            [self.publicDatabase addOperation:continuedQueryOperation];
        }
        
        // back on the main queue, call our completion handler
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(results, error);
        });
    } copy];
    
    block_self = myCompletionBlock;
    
    photosNearQueryOperation.queryCompletionBlock = block_self;
    [self.publicDatabase addOperation:photosNearQueryOperation];
}

// fetch for all recent records whose photo asset was created within the last number of "days" as input
//
- (void)fetchRecentRecords:(NSInteger)days completionHandler:(void (^)(NSArray *records, NSError *error))completionHandler
{
    NSDate *now = [NSDate date];
    NSTimeInterval secondsForDays = days * 24 * 60 * 60;
    NSDate *lastDate = [NSDate dateWithTimeInterval:-secondsForDays sinceDate:now];

    NSPredicate *startDatePredicate = [NSPredicate predicateWithFormat:@"%K >= %@", kPhotoDate, lastDate];
    NSPredicate *endDatePredicate = [NSPredicate predicateWithFormat:@"%K <= %@", kPhotoDate, now];
    NSCompoundPredicate *recentPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[startDatePredicate, endDatePredicate]];
    
    CKQuery *query = [[CKQuery alloc] initWithRecordType:[APLCloudManager PhotoRecordType] predicate:recentPredicate];
    query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:kPhotoTitle ascending:YES]];
    
    CKQueryOperation *recentsQueryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    
    // request these attributes (important to get all attributes in favor if our APLDetailViewController)
    NSArray *desiredKeys = @[kPhotoTitle, kPhotoAsset, kPhotoDate, kPhotoLocation];
    recentsQueryOperation.desiredKeys = desiredKeys;
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    // defined our fetched record block so we can add records to our results array
    __block void (^recordFetchedBlock)(CKRecord *) = ^(CKRecord *record) {
        // found a record
        [results addObject:record];
    };
    recentsQueryOperation.recordFetchedBlock = recordFetchedBlock;
    
    __weak __block void (^block_self)(CKQueryCursor *, NSError *);
    void (^myCompletionBlock)(CKQueryCursor *, NSError *) = [^(CKQueryCursor *cursor, NSError *error) {
    
        CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
        
        if (cursor != nil)
        {
            // there's more fetching to do
            CKQueryOperation *continuedQueryOperation = [[CKQueryOperation alloc] initWithCursor:cursor];
            continuedQueryOperation.desiredKeys = desiredKeys;
            continuedQueryOperation.queryCompletionBlock = block_self;
            continuedQueryOperation.recordFetchedBlock = recordFetchedBlock;
            [self.publicDatabase addOperation:continuedQueryOperation];
        }
        
        // back on the main queue, call our completion handler
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(results, error);
        });
    } copy];
    
    block_self = myCompletionBlock;
    
    recentsQueryOperation.queryCompletionBlock = block_self;
    [self.publicDatabase addOperation:recentsQueryOperation];
}

// fetch for all our own records
//
- (void)fetchMyRecords:(void (^)(NSArray *records, NSError *error))completionHandler
{
    [self fetchLoggedInUserRecord:^(CKRecordID *loggedInUserRecordID) {
        
        CKRecordID *ourLoggedInRecordID = [[CKRecordID alloc] initWithRecordName:loggedInUserRecordID.recordName];
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"creatorUserRecordID", ourLoggedInRecordID];
        
        CKQuery *query = [[CKQuery alloc] initWithRecordType:[APLCloudManager PhotoRecordType] predicate:searchPredicate];
        CKQueryOperation *myPhotosQueryOperation = [[CKQueryOperation alloc] initWithQuery:query];
        
        NSArray *desiredKeys = @[kPhotoTitle, kPhotoAsset, kPhotoDate, kPhotoLocation];
        myPhotosQueryOperation.desiredKeys = desiredKeys;
        
        NSMutableArray *results = [[NSMutableArray alloc] init];

        __block void (^recordFetchedBlock)(CKRecord *) = ^(CKRecord *record) {
            // found a record
            [results addObject:record];
        };
        myPhotosQueryOperation.recordFetchedBlock = recordFetchedBlock;
        
        __weak __block void (^block_self)(CKQueryCursor *, NSError *);
        void (^myCompletionBlock)(CKQueryCursor *, NSError *) = [^(CKQueryCursor *cursor, NSError *error) {

            CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
 
            if (cursor != nil)
            {
                // there's more fetching to do
                CKQueryOperation *continuedQueryOperation = [[CKQueryOperation alloc] initWithCursor:cursor];
                continuedQueryOperation.desiredKeys = desiredKeys;
                continuedQueryOperation.queryCompletionBlock = block_self;
                continuedQueryOperation.recordFetchedBlock = recordFetchedBlock;
                [self.publicDatabase addOperation:continuedQueryOperation];
            }
            
            // back on the main queue, call our completion handler
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
                // we find only one CKRecord (matching incoming recordID)
                completionHandler(results, error);
            });
        } copy];
        
        block_self = myCompletionBlock;
        myPhotosQueryOperation.queryCompletionBlock = block_self;
        
        [self.publicDatabase addOperation:myPhotosQueryOperation];
    }];
}

- (BOOL)isMyRecord:(CKRecordID *)recordID;
{
    return [recordID.recordName isEqual:CKOwnerDefaultName];
}


#pragma mark - Deleting and Saving

- (void)deleteRecordWithID:(CKRecordID *)recordID completionHandler:(void (^)(CKRecordID *recordID, NSError *error))completionHandler
{
    [self.publicDatabase deleteRecordWithID:recordID completionHandler:^(CKRecordID *recordID, NSError *error) {
        
        CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
        
        // back on the main queue, call our completion handler
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(recordID, error);
        });
    }];
}

- (void)deleteRecordsWithIDs:(NSArray *)recordIDs completionHandler:(void (^)(NSArray *deletedRecordIDs, NSError *error))completionHandler
{
    // we use CKModifyRecordsOperation to delete multiple records
    CKModifyRecordsOperation *operation =
        [[CKModifyRecordsOperation alloc] initWithRecordsToSave:nil recordIDsToDelete:recordIDs];
    operation.savePolicy = CKRecordSaveIfServerRecordUnchanged;
    operation.queuePriority = NSOperationQueuePriorityHigh;
    
    // The following Quality of Service (QoS) is used to indicate to the system the nature and importance of this work.
    // Higher QoS classes receive more resources than lower ones during resource contention.
    //
    operation.qualityOfService = NSQualityOfServiceUserInitiated;
    
    // add the completion for the entire delete operation
    operation.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *error) {

        CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
        
        // back on the main queue, call our completion handler
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(deletedRecordIDs, error);
        });
    };

    // start the operation
    [self.publicDatabase addOperation:operation];
}

- (void)saveRecord:(CKRecord *)record completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler
{
    [self.publicDatabase saveRecord:record completionHandler:^(CKRecord *record, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
            
            // back on the main queue, call our completion handler
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionHandler(record, error);
            });
        });
    }];
}

- (void)modifyRecord:(CKRecord *)recordToModify completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler
{
    // we use CKModifyRecordsOperation to delete records permanently from a database
    CKModifyRecordsOperation *operation =
        [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[recordToModify] recordIDsToDelete:nil];
    operation.savePolicy = CKRecordSaveIfServerRecordUnchanged;
    operation.queuePriority = NSOperationQueuePriorityHigh;

    // The following Quality of Service (QoS) is used to indicate to the system the nature and importance of this work.
    // Higher QoS classes receive more resources than lower ones during resource contention.
    //
    operation.qualityOfService = NSQualityOfServiceUserInitiated;

    // report the progress on a per record basis
    operation.perRecordProgressBlock = ^(CKRecord *record, double progress) {
        NSLog(@"modifying record: %.0f%% complete", progress*100);
    };
    
    // callback for each record modified
    operation.perRecordCompletionBlock = ^(CKRecord *record, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            if (error != nil)
            {
                CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);

                if (error.code == CKErrorServerRecordChanged)
                {
                    // CKRecordChangedErrorAncestorRecordKey:
                    // Key to the original CKRecord that you used as the basis for making your changes.
                    CKRecord *ancestorRecord = error.userInfo[CKRecordChangedErrorAncestorRecordKey];
                    
                    // CKRecordChangedErrorServerRecordKey:
                    // Key to the CKRecord that was found on the server. Use this record as the basis for merging your changes.
                    CKRecord *serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey];
                    
                    // CKRecordChangedErrorClientRecordKey:
                    // Key to the CKRecord that you tried to save.
                    // This record is based on the record in the CKRecordChangedErrorAncestorRecordKey key but contains the additional changes you made.
                    CKRecord *clientRecord = error.userInfo[CKRecordChangedErrorClientRecordKey];
                    
                    NSAssert(ancestorRecord != nil || serverRecord != nil || clientRecord != nil,
                             @"Error CKModifyRecordsOperation, can't obtain ancestor, server or client records to resolve conflict.");
                    
                    // important to use the server's record as a basis for our changes,
                    // apply our current record to the server's version
                    //
                    serverRecord[kPhotoTitle] = clientRecord[kPhotoTitle];
                    serverRecord[kPhotoAsset] = clientRecord[kPhotoAsset];
                    serverRecord[kPhotoDate] = clientRecord[kPhotoDate];
                    serverRecord[kPhotoLocation] = clientRecord[kPhotoLocation];
                
                    // save the newer record
                    [self.publicDatabase saveRecord:serverRecord completionHandler:^(CKRecord *savedRecord, NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            // success, return the saved record
                            completionHandler(savedRecord, error);
                        });
                    }];
                }
                else
                {
                    // for all other errors just report it back in our completion
                    completionHandler(record, error);
                }
            }
            else
            {
                // no errors, call our completion with the saved record
                completionHandler(record, error);
            }
        });
    };
    
    // start the modify operation
    [self.publicDatabase addOperation:operation];
}


#pragma mark - Subscriptions and Notifications

// subscription keys used when tracking/storing to NSUserDefaults
static NSString * const kSubscriptionIDKey = @"subscriptionID";

- (BOOL)isSubscribed
{
    return ([[NSUserDefaults standardUserDefaults] objectForKey:kSubscriptionIDKey] != nil);
}

- (void)saveSubscription:(CKSubscription *)subscriptionInfo
         subscriptionKey:(NSString *)subscriptionKey
       completionHandler:(void (^)(NSError *error))completionHandler
{
    // save the subscription, note this requires iCloud drive log in to work
    [self.publicDatabase saveSubscription:subscriptionInfo completionHandler:^(CKSubscription *subscription, NSError *error) {
        if (error != nil)
        {
            // note: if you are not logged in you can get this:
            //      error code 9
            //
            //      An error occured in subscribe:
            //          <CKError 0x7ffe8a46d710: "Not Authenticated" (9/1002);
            //          "This request requires an authenticated account"; Retry after 3.0 seconds>
            //
            //      or
            //
            //      CKRetryAfter = 3;
            //      NSDebugDescription = "CKInternalErrorDomain: 1002";
            //      NSLocalizedDescription = "This request requires an authenticated account";
            //      NSUnderlyingError = "<CKError 0x7ffe8a622200: \"Unknown Error\" (1002); Retry after 3.0 seconds>";
            //
            CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
            
            if (error.code == CKErrorServerRejectedRequest)
            {
                // save subscription request rejected!
                // trying to save a subscribution (subscribe) failed (probably because we already have a subscription saved)
                //
                // this is likely due to the fact that the app was deleted and reinstalled to the device,
                // so assume we have a subscription already registed with the server
                //
            }
            else if (error.code == CKErrorNotAuthenticated)
            {
                // could not subscribe (not authenticated)
                //NSLog(@"User not authenticated (could not subscribe to record changes)");
            }
        }

        // back on the main queue, store as a default and call our completion handler
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            // remember our subscription ID for next time
            NSLog(@"Subscribed with id = %@", subscription.subscriptionID);
            [[NSUserDefaults standardUserDefaults] setObject:subscription.subscriptionID forKey:subscriptionKey];
            
            completionHandler(error);  // we are done
        });
    }];
}

- (void)startSubscriptions
{
    // subscribe to deletion, update and creation of our record type
    //
    NSPredicate *truePredicate = [NSPredicate predicateWithValue:YES];  // we are interested in "all" changes to kRecordType
 
    // 1) subscribe to record creations
    __block CKSubscription *itemSubscription =
        [[CKSubscription alloc] initWithRecordType:kPhotoRecordType
                                         predicate:truePredicate
                                           options:CKSubscriptionOptionsFiresOnRecordCreation | CKSubscriptionOptionsFiresOnRecordUpdate | CKSubscriptionOptionsFiresOnRecordDeletion];

    CKNotificationInfo *notification = [[CKNotificationInfo alloc] init];
    
    // set the notification content:
    //
    // note: if you don't set "alertBody", "soundName" or "shouldBadge", it will make the notification a priority, sent at an opportune time
    //
    notification.alertBody = NSLocalizedString(@"Notif alert body", nil);
    
    // allows the action to launch the app if it’s not running. Once launched, the notifications will be delivered,
    // and the app will be given some background time to process them.
    //
    // Indicates that the notification should be sent with the "content-available" flag
    // to allow for background downloads in the application. Default value is NO.
    //
    notification.shouldSendContentAvailable = YES;

    // optional
    notification.soundName = @"Hero.aiff";   // or default: UILocalNotificationDefaultSoundName

    // below identifies an image in your bundle to be shown as an alternate launch image
    // when launching from the notification, this is used on this case:
    //      1. app is launched
    //      2. device is turned off and on again
    //      3. change CKRecord on another device
    //      4. notif arrives, tap open or tap banner and the launch image (all pink) shows
    //
    //notification.alertLaunchImage = @"<your launch image>.png";

    // a list of keys from the matching record to include in the notification payload,
    // here are are only interested in the title (kPhotoAsset can't be a desired key, unsupported)
    //
    notification.desiredKeys = @[kPhotoTitle];

    // set our CKNotificationInfo to our CKSubscription
    itemSubscription.notificationInfo = notification;

    // save our subscription,
    // note: that if saving multiple subscriptions, they should be saved in succession, and not independently
    //
    [self saveSubscription:itemSubscription subscriptionKey:kSubscriptionIDKey completionHandler:^(NSError *error) {
        
        CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
    }];
}

- (void)updateUserDefaults:(NSString *)subscriptionID
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSubscriptionIDKey];
    [[NSUserDefaults standardUserDefaults] setObject:subscriptionID forKey:kSubscriptionIDKey];
 
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)subscribe
{
    // first check if we already have our 1 subscription registered on the server, and adjust our NSUserDefaults
    // we are using CKFetchSubscriptionsOperation, or we could also use CKDatabase's "fetchAllSubscriptionsWithCompletionHandler"
    //
    CKFetchSubscriptionsOperation *fetchSubscriptionsOperation = [CKFetchSubscriptionsOperation fetchAllSubscriptionsOperation];
    fetchSubscriptionsOperation.fetchSubscriptionCompletionBlock = ^(NSDictionary *subscriptionsBySubscriptionID, NSError *operationError) {
        if (operationError != nil)
        {
            // error in fetching our subscription
            CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), operationError);
            
            if (operationError.code == CKErrorNotAuthenticated)
            {
                // try again after 3 seconds if we don't have a retry hint
                //
                NSNumber *retryAfter = operationError.userInfo[CKErrorRetryAfterKey] ? : @3;
                NSLog(@"Error: %@. Recoverable, retry after %@ seconds", [operationError description], retryAfter);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(retryAfter.intValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self subscribe];
                });
            }
        }
        else
        {
            if (self.subscribed == NO)
            {
                // our user defaults says we haven't subscribed yet
                //
                if (subscriptionsBySubscriptionID != nil && subscriptionsBySubscriptionID.count > 0)
                {
                    // we already have our one CKSubscription registered with the server that we didn't know about
                    // (not kept track in our NSUserDefaults) from a past app install perhaps,
                    //
                    NSArray *allSubscriptionIDKeys = [subscriptionsBySubscriptionID allKeys];
                    if (allSubscriptionIDKeys != nil)
                    {
                        [self updateUserDefaults:allSubscriptionIDKeys[0]];
                    }
                }
                else
                {
                    // no subscriptions found on the server, so subscribe
                    [self startSubscriptions];
                }
            }
            else
            {
                // our user defaults says we have already subscribed, so check if the subscription ID matches ours
                //
                if (subscriptionsBySubscriptionID != nil && subscriptionsBySubscriptionID.count > 0)
                {
                    // we already have our one CKSubscription registered with the server that
                    // we didn't know about (not kept track in our NSUserDefaults) from a past app install perhaps,
                    //
                    NSArray *allSubscriptionIDKeys = [subscriptionsBySubscriptionID allKeys];
                    if (allSubscriptionIDKeys != nil)
                    {
                        NSString *ourSubscriptionID = [[NSUserDefaults standardUserDefaults] objectForKey:kSubscriptionIDKey];
                        if (![allSubscriptionIDKeys[0] isEqualToString:ourSubscriptionID])
                        {
                            // our subscription ID doesn't match what is on the server, to update our to match
                            [self updateUserDefaults:allSubscriptionIDKeys[0]];
                        }
                        else
                        {
                            // they match, no more work here
                        }
                    }
                }
            }
        }
    };
    [self.publicDatabase addOperation:fetchSubscriptionsOperation];
}

- (void)unsubscribeByKey:(NSString *)key
{
    // we want to modify our current subscription and delete the subscription ID from it
    NSString *subscriptionID = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    CKModifySubscriptionsOperation *modifyOperation = [[CKModifySubscriptionsOperation alloc] init];
    if (subscriptionID != nil)
    {
        modifyOperation.subscriptionIDsToDelete = @[subscriptionID];
        
        modifyOperation.modifySubscriptionsCompletionBlock = ^(NSArray *savedSubscriptions, NSArray *deletedSubscriptionIDs, NSError *error) {
            if (error != nil)
            {
                CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
            }
            else
            {
                NSLog(@"Unsubscribed to ItemID: %@[%@]", subscriptionID, key);
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        };
        
        [self.publicDatabase addOperation:modifyOperation];
    }
}

// unsubscribe all our known CKSubscriptions (based from NSUserDefaults)
- (void)unsubscribe
{
    if (self.subscribed == YES)
    {
        [self unsubscribeByKey:kSubscriptionIDKey];
    }
    else
    {
        // we are already unsubscribed, no need to do anything further here
    }
}

// use this method to remove the subscription and reset NSUserDefaults regardless of what NSUserDefaults tells us.
//
// note that direct removal of subscriptions can be done in CloudKit Dashboard,
// and removal of NSUserDefaults can be done by removing the app from the device.
//
- (void)forceUnsubscribe
{
    CKFetchSubscriptionsOperation *fetchSubscriptionsOperation = [CKFetchSubscriptionsOperation fetchAllSubscriptionsOperation];
    fetchSubscriptionsOperation.fetchSubscriptionCompletionBlock = ^(NSDictionary *subscriptionsBySubscriptionID, NSError *operationError) {
        if (operationError != nil)
        {
            CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), operationError);
        }
        else
        {
            if (subscriptionsBySubscriptionID != nil && subscriptionsBySubscriptionID.count > 0)
            {
                // we already have one or more CKSubscriptions registered with the server that
                // we didn't know about (not kept track in NSUserDefaults) from a past app install perhaps,
                //
                [self unsubscribeByKey:kSubscriptionIDKey];
            }
        }
    };
    [self.publicDatabase addOperation:fetchSubscriptionsOperation];
}

- (void)markNotificationsAsAlreadyRead
{
    [self markNotificationsAsAlreadyRead:self.serverChangeToken];
}

- (void)markNotificationsAsAlreadyRead:(CKServerChangeToken *)serverChangeToken
{
    // each item in the notification queue need to be marked as "read" so next time we won't be concerned about them
    //
    __block NSMutableArray *array = [NSMutableArray array];
    
    // this operation will fetch all notification changes,
    // if a change anchor from a previous CKFetchNotificationChangesOperation is passed in,
    // only the notifications that have changed since that anchor will be fetched.
    //
    CKFetchNotificationChangesOperation *fetchChangesOperation =
        [[CKFetchNotificationChangesOperation alloc] initWithPreviousServerChangeToken:serverChangeToken];
    
    __weak CKFetchNotificationChangesOperation *weakFetchChangesOperation = fetchChangesOperation;
    
    fetchChangesOperation.fetchNotificationChangesCompletionBlock = ^ (CKServerChangeToken *newerServerChangeToken, NSError *operationError) {
        if (operationError != nil)
        {
            CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), operationError);
        }
        else
        {
            // If "moreComing" is set then the server wasn't able to return all the changes in this response,
            // another CKFetchNotificationChangesOperation operation should be run with the updated serverChangeToken token from this operation.
            //
            if (weakFetchChangesOperation.moreComing)
            {
                [self markNotificationsAsAlreadyRead:newerServerChangeToken];
            }
            else
            {
                _serverChangeToken = newerServerChangeToken;
            }
        }
    };
    
    // this block processes a single push notification
    fetchChangesOperation.notificationChangedBlock = ^(CKNotification *notification) {
        if (notification.notificationType != CKNotificationTypeReadNotification)
        {
            [array addObject:notification.notificationID];  // add it to our array so that it can be marked as read
        }
    };
    
    // this block is executed after all requested notifications are fetched
    fetchChangesOperation.completionBlock = ^{
        //NSLog(@"found %lu items in the change notif queue", (unsigned long)array.count);
        
        // mark all of them as "read"
        CKMarkNotificationsReadOperation *markNotifsReadOperation = [[CKMarkNotificationsReadOperation alloc] initWithNotificationIDsToMarkRead:array];
        
        markNotifsReadOperation.markNotificationsReadCompletionBlock = ^ (NSArray *notificationIDsMarkedRead, NSError *operationError) {
            if (operationError != nil)
            {
                CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), operationError);
      
                //NSLog(@"Unable to mark notifs as read: %@", operationError);
            }
            else
            {
                // finished marking the notifications as "read"
                //NSLog(@"items marked as read = %lu", (unsigned long)notificationIDsMarkedRead.count);
            }
        };
        
        [self.container addOperation:markNotifsReadOperation];
    };
    
    [self.container addOperation:fetchChangesOperation];
}


#pragma mark - User Discoverability

- (BOOL)userLoginIsValid
{
    return (self.userRecordID != nil);
}

// check the user account status (are we logged in?)
- (void)accountAvailable:(void (^)(BOOL available))completionHandler
{
    [[CKContainer defaultContainer] accountStatusWithCompletionHandler:^(CKAccountStatus accountStatus, NSError *error) {
    
        CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
        
        // back on the main queue, call our completion handler
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            // note: accountStatus could be "CKAccountStatusAvailable", and at the same time there could be no network,
            // in this case the user should not be able to add, remove or modify photos
            //
            completionHandler(accountStatus == CKAccountStatusAvailable);
        });
    }];
}

// Asks for discoverability permission from the user.
//
// This will bring up an alert: "Allow people using "CloudPhotos" to look you up by email?",
// clicking "Don't Allow" will not make you discoverable.
//
// The first time you request a permission on any of the user’s devices, the user is prompted to grant or deny the request.
// Once the user grants or denies a permission, subsequent requests for the same permission
// (on the same or separate devices) do not prompt the user again.
//
- (void)requestDiscoverabilityPermission:(void (^)(BOOL discoverable)) completionHandler {
    
    [self.container requestApplicationPermission:CKApplicationPermissionUserDiscoverability
                               completionHandler:^(CKApplicationPermissionStatus applicationPermissionStatus, NSError *error) {

        CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
                                   
        // back on the main queue, call our completion handler
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(applicationPermissionStatus == CKApplicationPermissionStatusGranted);
        });
    }];
}

// obtain information on all users in our Address Book
// how this is called:
//
//  [self fetchAllUsers:^(NSArray *userInfoRecords) { }];
//
- (void)fetchAllUsers:(void (^)(NSArray *userInfoRecords))completionHandler
{
    // find all discoverable users in the device's address book
    //
    CKDiscoverAllContactsOperation *op = [[CKDiscoverAllContactsOperation alloc] init];
    op.queuePriority = NSOperationQueuePriorityNormal;
    
    [op setDiscoverAllContactsCompletionBlock:^(NSArray *userInfos, NSError *error) {
        
        CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
        
        // back on the main queue, call our completion handler
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionHandler(userInfos);
        });
    }];
    [self.container addOperation:op];
    
    // or directly without NSOperation
    /*[self.container discoverAllContactUserInfosWithCompletionHandler:^(NSArray *userInfos, NSError *error) {
        
        // back on the main queue, call our completion handler
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    }];*/
}

// obtain the current logged in user's CKRecordID
//
- (void)fetchLoggedInUserRecord:(void (^)(CKRecordID *recordID))completionHandler
{
    [self requestDiscoverabilityPermission:^(BOOL discoverable) {
        
        if (discoverable)
        {
            [self.container fetchUserRecordIDWithCompletionHandler:^(CKRecordID *recordID, NSError *error) {

                CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);

                // back on the main queue, call our completion handler
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    completionHandler(recordID);    // invoke our caller's completion handler indicating we are done
                });
            }];
        }
        else
        {
            // can't discover user, return nil user recordID back on the main queue
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionHandler(nil);    // invoke our caller's completion handler indicating we are done
            });
        }
    }];
}

// Discover the given CKRecordID's user's info with CKDiscoverUserInfosOperation,
// return in its completion handler the last name and first name, if possible.
// Users of an app must opt in to discoverability before their user records can be accessed.
//
- (void)fetchUserNameFromRecordID:(CKRecordID *)recordID completionHandler:(void (^)(NSString *firstName, NSString *lastName))completionHandler
{
    NSAssert(recordID != nil, @"Error fetchUserNameFromRecordID, incoming recordID is nil");
    
    // first find our own login user recordID
    [self fetchLoggedInUserRecord:^(CKRecordID *loggedInUserRecordID) {
    
        // our completion handler -
        CKRecordID *recordIDToUse = nil;
        
        // we found our login user recordID, is it our photo?
        if ([self isMyRecord:recordID])
        {
            // we own this record, so look up our user name using our login recordID
            recordIDToUse = loggedInUserRecordID;
        }
        else
        {
            // this recordID is owned by another user, find its user info using the incoming "recordID" directly
            recordIDToUse = recordID;
        }
        
        if (recordIDToUse != nil)
        {
            CKDiscoverUserInfosOperation *discoverOperation = [[CKDiscoverUserInfosOperation alloc] init];
            discoverOperation.userRecordIDs = @[recordIDToUse];
            
            discoverOperation.discoverUserInfosCompletionBlock = ^(NSDictionary *emailsToUserInfos, NSDictionary *userRecordIDsToUserInfos, NSError *operationError) {
                
                CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), operationError);
                
                // the dictionary has a key as CKRecordID which gives us back a CKDiscoveredUserInfo
                CKDiscoveredUserInfo *userInfo = userRecordIDsToUserInfos[recordIDToUse];
                if (userInfo != nil)
                {
                    // back on the main queue, call our completion handler
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        // invoke our caller's completion handler indicating we are done
                        completionHandler(userInfo.firstName, userInfo.lastName);
                    });
                }
            };
            [self.container addOperation:discoverOperation];
        }
        else
        {
            // could not find our login user recordID (probably because we or the other user are not discoverable)
            // report back with a generic name
            //
            // back on the main queue, call our completion handler
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionHandler(NSLocalizedString(@"Undetermined Login Name", nil), nil);
            });
        }
    }];
}

// used to update our user information (in case user logged out/in or with a different account),
// typically you call this when the app becomes active from launch or from the background.
//
- (void)updateUserLogin:(void (^)(void))completionHandler
{
    // first ask for discoverability permission from the user
    [self requestDiscoverabilityPermission:^(BOOL discoverable) {
        
        // invoke our caller's completion handler indicating we are done
        if (discoverable)
        {
            // first obtain the CKRecordID of the logged in user (we use it to find the user's contact info)
            //
            [self.container fetchUserRecordIDWithCompletionHandler:^(CKRecordID *recordID, NSError *error) {
                
                if (error != nil)
                {
                    // no user information will be known at this time
                    _userInfo = nil;
                    _userRecordID = nil;
                    
                    CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
                    
                    // back on the main queue, call our completion handler
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        completionHandler(); // no user information found, due to an error
                    });
                }
                else
                {
                    _userRecordID = recordID;
                    
                    // retrieve info about the logged in user using it's CKRecordID
                    [self.container discoverUserInfoWithUserRecordID:recordID completionHandler:^(CKDiscoveredUserInfo *user, NSError *error) {
                        if (error != nil)
                        {
                            // if we get network failure error (4), we still get back a recordID, which means no access to CloudKit container
                            
                            // no user information will be known at this time
                            _userRecordID = nil;
                            _userInfo = nil;
                            
                            CloudKitErrorLog(__LINE__, NSStringFromSelector(_cmd), error);
                        }
                        else
                        {
                            _userInfo = user;
                            //NSLog(@"logged in as '%@ %@'", self.userInfo.firstName, self.userInfo.lastName);
                        }
                        
                        // back on the main queue, call our completion handler
                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            completionHandler();    // invoke our caller's completion handler indicating we are done
                        });
                    }];
                }
            }];
        }
        else
        {
            // user info is not discoverable
            
            // back on the main queue, call our completion handler
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionHandler();    // invoke our caller's completion handler indicating we are done
            });
        }
    }];
}

@end
