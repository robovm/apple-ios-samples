 iOSInAppPurchases
 
 Description
 iOSPurchases demonstrates how to retrieve, display, purchase, and restore In-App Purchase products using the StoreKit framework.
 It follows the In App Purchase built-in product model and provides best practices about populating the UI and making purchases. 
 It queries and retrieves information from the App Store using SKRequestDelegate, SKProductsRequestDelegate, SKProductsResponse,
 and SKProductsRequest. It uses SKProduct's localizedTitle, priceLocale, price properties to display its products' localized title
 and price information. It shows how to download hosted content from the App Store using SKPaymentTransactionObserver's paymentQueue: updatedDownloads:.
 It displays purchase information and download progress using SKPaymentTransaction and SKDownload's progress property, respectively.
 

Build Requirements
iOS SDK 7.1 or later


Runtime Requirements
iOS 7.1 or later


Using the Sample
iOSInAppPurchases displays a Restore button and segmented control, which allows you to toggle between 2 views: Products and Purchases.
Tap Restore to restore all your restorable products. Products  displays a list of items available for sale in the App Store as well as
unrecognized product identifiers. Tap any item in the "AVAILABLE PRODUCTS" list to purchase it. iOSInAppPurchases displays appropriate 
alerts to inform you about the purchase process. Your hosted product's content is saved in the Caches directory on your device.
Purchases displays all your purchased and restored products. Tap on any of these products to view their purchase information.


There are few steps required for testing this sample for In-App Purchase:

1. You must create or use an application that uses an explicit App ID in the "Certificates, Identifiers & Profiles" section of Member Center.

2. The created/used application must support In-App Purchase as outlined in the "Contracts, Tax, and Banking Information" section of TN2259 Adding In-App Purchase to your iOS and OS X Applications.

3. Create a test user account in iTunes Connect. See iTunes Connect Developer Guide > Test Users for more information about creating test user accounts.

4. Create In-App Purchase products in iTunes Connect if your application does not have any. See iTunes Connect > Creating In-App Purchase Products in the In-App Purchase Configuration Guide for more information about creating these products.

5. Launch or create your project in Xcode.

6. Update the ProductIds.plist file with the identifiers created in step 4.

7. Enter your app's bundle identifier in the Bundle Identifier field of your Target's Info pane in Xcode. See App Distribution Guide > Setting the Bundle ID for more information.

8. Set the code signing identity to your development certificate as outlined in App Distribution Guide > Maintaining Your Signing Identities and Certificates > To set the code signing identity to your development certificate.

9. Build and run your application. See App Distribution Guide > Troubleshooting if you are running into any codesigning issues.

10. iOSInAppPurchases queries the App Store about the identifiers contained in ProductIds.plist upon launching. It displays the results in the Products view. If all your identifiers are returned as invalid, see TN2259 Adding In-App Purchase to your iOS and OS X Applications > FAQ6 for information on how to resolve this issue. Skip to step 11 if Products displays some available products for sale.

11. Tap any product from the "AVAILABLE PRODUCTS" list to purchase it. Enter the test user account created in step 3 when prompted by StoreKit to authenticate the purchase.

See TN2259 Adding In-App Purchase to your iOS and OS X Applications that describes how to set up and test In-App Purchase in your iOS and OS X applications.


References
TN2259 Adding In-App Purchase to your iOS and OS X Applications
<https://developer.apple.com/library/ios/technotes/tn2259>

iTunes Connect Developer Guide > Test Users
<https://developer.apple.com/library/ios/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/SettingUpUserAccounts.html#//apple_ref/doc/uid/TP40011225-CH25-SW9>

In-App Purchase Configuration Guide for iTunes Connect > Creating In-App Purchase Products
<https://developer.apple.com/library/ios/documentation/LanguagesUtilities/Conceptual/iTunesConnectInAppPurchase_Guide/Chapters/CreatingInAppPurchaseProducts.html>

iTunes Connect Help> Determining Whether Your App is Ready to Upload
<https://developer.apple.com/library/ios/recipes/iTunesConnect_Recipes/Articles/DetermineStatus.html>

App Distribution Guide > Setting the Bundle ID
<https://developer.apple.com/library/ios/documentation/IDEs/Conceptual/AppDistributionGuide/ConfiguringYourApp/ConfiguringYourApp.html#//apple_ref/doc/uid/TP40012582-CH28-SW16>


Copyright (C) 2014 Apple Inc. All rights reserved.