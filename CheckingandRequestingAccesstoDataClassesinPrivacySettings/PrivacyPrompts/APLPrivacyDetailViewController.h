/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 View controller that handles checking and requesting access to the users private data classes.
 */

@import UIKit;

typedef void (^CheckAccessBlock)();
typedef void (^RequestAccessBlock)();

@interface APLPrivacyDetailViewController : UITableViewController

@property (nonatomic, copy) CheckAccessBlock checkBlock;
@property (nonatomic, copy) RequestAccessBlock requestBlock;

@end
