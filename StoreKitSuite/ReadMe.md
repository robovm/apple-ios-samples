# StoreKitSuite
StoreKitSuite is a suite of sample applications that demonstrate how to implement three different aspects of StoreKit:


1. In App Purchases

2. Displaying items available for sale in the App Store from within an application using SKStoreProductViewController

3. Affiliate campaign and App Analytics campaign tracking


iOSInAppPurchases demonstrates how to retrieve, display, purchase, download, and restore In-App Purchase products using SKRequestDelegate, SKProductsRequestDelegate, SKProductsResponse, and SKPaymentTransactionObserver's paymentQueue:updatedTransactions: and paymentQueue: updatedDownloads:. It displays available products for sale and invalid product identifiers returned from the App Store using SKProduct, displays purchase information using SKPaymentTransaction, and hosted product’s download progress using SKDownload's progress.


IAPStoreProductViewController demonstrates how to use SKStoreProductViewController to display items available for sale in the App Store from within an application. This sample also demonstrates how campaign token and provider token can be supplied to SKStoreProductViewController to support campaign tracking in App Analytics.


## Build Requirements
Xcode 7.0, iOS SDK 9.0 or later


## Runtime Requirements
iOS 9.0 or later


## Changes from Previous Versions
3.0 - Added SKStoreProductParameterCampaignToken, SKStoreProductParameterProviderToken as optional parameters to Product. StoreProductViewController now recognizes if the product is an app and if campaign parameters are provided the StoreProductViewController is loaded appropriately.

2.0 - Added the SKPaymentTransactionStateDeferred case to StoreObserver's paymentQueue: updatedTransactions: in iOSInAppPurchases. Cleaned up code in iOSInAppPurchases and IAPStoreProductViewController.

1.0 - First Version

Copyright (C) 2014-2015 Apple Inc. All rights reserved.