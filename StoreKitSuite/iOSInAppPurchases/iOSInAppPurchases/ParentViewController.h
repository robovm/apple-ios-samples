/*
 
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Manages the child view controllers: iOSProductsList and iOSPurchasesList.
         Displays a Restore button that allows you to restore all previously purchased
         non-consumable and auto-renewable subscription products. Request product information
         about a list of product identifiers using StoreManager. Calls StoreObserver to implement
         the restoration of purchases.
 
*/


@interface ParentViewController : UIViewController
@end