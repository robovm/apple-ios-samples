/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
WatchKit interface controller to display Apple Pay / Handoff information to the user.
*/

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {
    // MARK: Properties
    
    @IBOutlet var statusLabel: WKInterfaceLabel!
    
    /* 
        How you request a charge from your WatchKit app will depend upon how
        your app is architected. Generally speaking, you'll want to use handoff
        and have your iOS app immediately display the payment sheet when it's invoked.
        
        In this example, we'll send the product to be charged in the handoff `userInfo`
        payload. See the `AppDelegate` of the main app for how we process this on iOS.
    */
    @IBAction func makePaymentPressed() {
        /*
            We'll send the product as a dictionary, and convert it to a `Product`
            value in our app delegate.
        */
        let product = [
            Product.DictionaryKey.Name.rawValue: "Example Charge",
            Product.DictionaryKey.Description.rawValue: "An example charge made by a WatchKit Extension",
            Product.DictionaryKey.Price.rawValue: "14.99"
        ]
        
        // Create our activity handoff type (registered in the iOS app's Info.plist).
        let activityType = AppConfiguration.UserActivity.payment
        
        // Use Handoff to route the wearer to the payment controller on phone
        let userInfo = [
            "product": product
        ]
        
        updateUserActivity(activityType, userInfo: userInfo, webpageURL: nil)
        
        // Tell the user to use handoff to pay.
        statusLabel.setText("Use handoff to pay!")
    }
}
