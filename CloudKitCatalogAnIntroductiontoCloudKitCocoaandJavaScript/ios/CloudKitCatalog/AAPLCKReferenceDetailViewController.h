/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller lets you add subitems to a list.
*/

@import UIKit;

@class AAPLCloudManager;

@interface AAPLCKReferenceDetailViewController : UITableViewController

@property (strong) AAPLCloudManager *cloudManager;
@property (copy) CKRecordID *parentRecordID;

@end
