/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The application's primary table view controller showing the list of CKRecord photos.
 */

#import "APLDetailTableViewController.h"

@interface APLMainTableViewController : UITableViewController <DetailViewControllerDelegate>

// for handling a push notification of a specific CKRecordID
- (void)handlePushWithRecordID:(CKRecordID *)recordID reason:(CKQueryNotificationReason)reason;

// called when we receive notification from our App Delegate that the user logged in our out
- (void)iCloudAccountAvailabilityChanged;

@end
