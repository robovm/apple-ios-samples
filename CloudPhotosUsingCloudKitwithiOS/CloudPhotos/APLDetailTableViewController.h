/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The detail view controller showing a specific CKRecord photo.
 */

@import UIKit;
@import CloudKit;

@protocol DetailViewControllerDelegate;

@interface APLDetailTableViewController : UITableViewController

@property (nonatomic, weak, readwrite) id<DetailViewControllerDelegate> delegate;

@property (nonatomic, strong) CKRecord *record;

// for handling a push notification of a specific CKRecordID
- (void)handlePushWithRecordID:(CKRecordID *)recordID reason:(CKQueryNotificationReason)reason reasonMessage:(NSString *)reasonMessage;

// called when we receive notification from our App Delegate that the user logged in our out
- (void)iCloudAccountAvailabilityChanged;

@end


#pragma mark -

// protocol used to inform our parent table view controller to update its table if the given record was added, changed or deleter
@protocol DetailViewControllerDelegate <NSObject>

@required
- (void)detailViewController:(APLDetailTableViewController *)viewController didChangeCloudRecord:(CKRecord *)record;
- (void)detailViewController:(APLDetailTableViewController *)viewController didAddCloudRecord:(CKRecord *)record;
- (void)detailViewController:(APLDetailTableViewController *)viewController didDeleteCloudRecord:(CKRecord *)record;

@end
