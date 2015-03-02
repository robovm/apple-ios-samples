/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Displays information retrieved from HealthKit about the food items consumed today.
            
*/

@import UIKit;
@import HealthKit;

@interface AAPLJournalViewController : UITableViewController

@property (nonatomic) HKHealthStore *healthStore;

@end
