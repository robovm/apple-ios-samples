/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Displays two lists: purchased products and restored ones. Call StoreObserver to determine
         whether the user has purchased or restored some products. When a user taps a product, it calls
         PaymentTransactionDetails to display its purchase information using SKPaymentTransaction.
 
*/

#import "IAPTableViewDataSource.h"

@interface iOSPurchasesList : UITableViewController <IAPTableViewDataSource>
@end
