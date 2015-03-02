/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A UIViewController subclass that manages the selection of a food item.
            
*/

@import UIKit;

@class AAPLFoodItem;

@interface AAPLFoodPickerViewController : UITableViewController

@property (strong) AAPLFoodItem *selectedFoodItem;

@end
