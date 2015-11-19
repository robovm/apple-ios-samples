# IAPStoreProductViewController

## Description
IAPStoreProductViewController demonstrates how to use SKStoreProductViewController to display items available for sale in the App Store from within an application. 
IAPStoreProductViewController displays of list of items available for sale in the App Store. Tap on any of them to launch it in the store from your app. 

When tapping an item, IAPStoreProductViewController creates a product dictionary with its iTunes identifier, then displays it in the App Store by
passing it to SKStoreProductViewController's loadProductWithParameters:completionBlock:. It uses SKStoreProductViewControllerDelegate's productViewControllerDidFinish: 
to dismiss the store product view controller.

To  find your product’s iTunes identifier, go to http://linkmaker.itunes.apple.com and search for your product. Look for your product within the search result,
click on the link associated with your product, and your product’s iTunes identifier is the nine-digit number between "id" and "?mt" in the displayed link.
For instance, the URL link for iBooks is https://itunes.apple.com/us/app/ibooks/id364709193?mt=8&uo=4. As such, its iTunes identifier is 364709193.


## Build Requirements
Xcode 7.0, iOS SDK 9.0 or later


## Runtime Requirements
iOS 9.0 or later


## Changes from Previous Versions
3.0 - Added SKStoreProductParameterCampaignToken, SKStoreProductParameterProviderToken as optional parameters to Product. StoreProductViewController now recognizes if the product is an app and if campaign parameters are provided the StoreProductViewController is loaded appropriately.

2.0 - Cleaned up code.

1.0 - First Version


Copyright (C) 2014-2015 Apple Inc. All rights reserved.