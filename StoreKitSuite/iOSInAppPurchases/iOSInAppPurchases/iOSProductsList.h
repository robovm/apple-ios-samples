/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Displays a list of products available for sale in the App Store if StoreManager returns one.
         Displays the localized title and price of each of these products using SKProduct. Also shows a list
         of product identifiers not recognized by the App Store if applicable. Calls StoreObserver to implement
         a purchase when a user taps a product.
 
*/

#import "IAPTableViewDataSource.h"

@interface iOSProductsList : UITableViewController <IAPTableViewDataSource>
@end
