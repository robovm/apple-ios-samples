# Emporium: A Simple Shopping Experience with Apple Pay

This sample shows how to integrate Apple Pay into a simple shopping experience. You'll learn how to make payment requests, collect shipping and contact information, apply discounts for debit/credit cards, and use the Apple Pay button. This project also contains an Apple Watch WatchKit extension that shows you how to start to make Apple Pay transactions using Handoﬀ with the NSUserActivity class.

The app is comprised of several parts:

* `CatalogCollectionViewController` - a collection view that displays a list of products (parsed from `ProductsList.plist`)
* `ProductTableViewController` - a detail table view that summarizes a product, and allows the user to buy it using Apple Pay
* `ConfirmationViewController` - a simple confirmation screen to be shown after a successful payment

Additionally, a simple WatchKit extension is supplied showing how to easily use hand-off to trigger a payment sheet on a companion iPhone.

## Requirements

If you're running this application on an iOS device you will need an Apple Pay card available, or alternatively you can use the iOS Simulator. Additionally, you'll need to have set up an Apple Pay merchant identifier. You can do this using Xcode's Capabilities window, which will also set up the required entitlement on your behalf.

To ensure the smoothest start with the sample, make sure to update the EMPORIUM_BUNDLE_PREFIX to a reverse DNS value appropriate for you or your organization. As this app makes use of entitlements, the bundle identifier and many other strings need to be unique. The project has been configured so that you only have to change this value in one place to establish this set of unique values in your situation.

For more information about processing an Apple Pay payment using a payment platform or merchant bank, visit [this link](developer.apple.com/apple-pay).

### Build

Xcode 7.0, iOS 9.0 SDK, watchOS 1.0 SDK

### Runtime

iOS 9.0, watchOS 1.0

Copyright (C) 2015 Apple Inc. All rights reserved.