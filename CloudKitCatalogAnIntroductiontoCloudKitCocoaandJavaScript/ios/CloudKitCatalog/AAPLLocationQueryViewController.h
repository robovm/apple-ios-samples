/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller lets you query for items near the location of the pin.
*/

@import UIKit;

@class AAPLCloudManager;

@interface AAPLLocationQueryViewController : UITableViewController

@property (strong) AAPLCloudManager *cloudManager;

@end
