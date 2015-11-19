/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
A view controller for an individual product. Includes all the code needed to set up and display an Apple Pay request, along with shipping and contact information handlers.
*/

import UIKit
import PassKit
import Contacts

class ProductTableViewController: UITableViewController, PKPaymentAuthorizationViewControllerDelegate {
    // MARK: IB Outlets

    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var productTitleLabel: UILabel!
    @IBOutlet weak var productPriceLabel: UILabel!
    @IBOutlet weak var productDescriptionView: UITextView!
    @IBOutlet weak var applePayView: UIView!
    
    // MARK: Other Properties

    static let confirmationSegue = "ConfirmationSegue"

    // Our app will support all available networks in Apple Pay.
    static let supportedNetworks = [
        PKPaymentNetworkAmex, 
        PKPaymentNetworkDiscover, 
        PKPaymentNetworkMasterCard, 
        PKPaymentNetworkVisa
    ]

    var product: Product!

    var paymentToken: PKPaymentToken!

    // MARK: View Controller
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard segue.identifier == ProductTableViewController.confirmationSegue else { return }

        let viewController = segue.destinationViewController as! ConfirmationViewController
        viewController.transactionIdentifier = paymentToken!.transactionIdentifier
    }

    // MARK: UITableViewDataSource
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        productTitleLabel.text = product.name
        productDescriptionView.text = product.description
        productPriceLabel.text = "$\(product.price)"
        
        /*
            Display an Apple Pay button if a payment card is available. In your
            app, you might divert the user to a more traditional checkout if 
            Apple Pay wasn't set up.
        */
        if PKPaymentAuthorizationViewController.canMakePaymentsUsingNetworks(ProductTableViewController.supportedNetworks) {
            
            let button = PKPaymentButton(type: .Buy, style: .Black)
            button.addTarget(self, action: "applePayButtonPressed", forControlEvents: .TouchUpInside)
            
            button.center = applePayView.center
            button.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
            applePayView.addSubview(button)
        }
    }

    // MARK: - Apple Pay Methods

    func applePayButtonPressed() {
        // Set up our payment request.
        let paymentRequest = PKPaymentRequest()
        
        /* 
            Our merchant identifier needs to match what we previously set up in
            the Capabilities window (or the developer portal).
        */
        paymentRequest.merchantIdentifier = AppConfiguration.Merchant.identififer
        
        /* 
            Both country code and currency code are standard ISO formats. Country
            should be the region you will process the payment in. Currency should
            be the currency you would like to charge in.
        */
        paymentRequest.countryCode = "US"
        paymentRequest.currencyCode = "USD"
        
        // The networks we are able to accept.
        paymentRequest.supportedNetworks = ProductTableViewController.supportedNetworks
        
        /* 
            Ask your payment processor what settings are right for your app. In
            most cases you will want to leave this set to .Capability3DS.
        */
        paymentRequest.merchantCapabilities = .Capability3DS
        
        /*
            An array of `PKPaymentSummaryItems` that we'd like to display on the
            sheet (see the summaryItems function).
        */
        paymentRequest.paymentSummaryItems = makeSummaryItems(requiresInternationalSurcharge: false)

        // Request shipping information, in this case just postal address.
        paymentRequest.requiredShippingAddressFields = .PostalAddress
        
        // Display the view controller.
        let viewController = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
        viewController.delegate = self
        presentViewController(viewController, animated: true, completion: nil)
    }
    
    
    // A function to generate our payment summary items, applying an international surcharge if required.
    func makeSummaryItems(requiresInternationalSurcharge requiresInternationalSurcharge: Bool) -> [PKPaymentSummaryItem] {
        var items = [PKPaymentSummaryItem]()
        
        /*
            Product items have a label (a string) and an amount (NSDecimalNumber).
            NSDecimalNumber is a Cocoa class that can express floating point numbers
            in Base 10, which ensures precision. It can be initialized with a
            double, or in this case, a string.
        */
        let productSummaryItem = PKPaymentSummaryItem(label: "Sub-total", amount: NSDecimalNumber(string: product.price))
        items += [productSummaryItem]

        let totalSummaryItem = PKPaymentSummaryItem(label: "Emporium", amount: productSummaryItem.amount)
        // Apply an international surcharge, if needed.
        if requiresInternationalSurcharge {
            let handlingSummaryItem = PKPaymentSummaryItem(label: "International Handling", amount: NSDecimalNumber(string: "9.99"))
            
            // Note how NSDecimalNumber has its own arithmetic methods.
            totalSummaryItem.amount = productSummaryItem.amount.decimalNumberByAdding(handlingSummaryItem.amount)

            items += [handlingSummaryItem]
        }
        
        items += [totalSummaryItem]
        
        return items
    }

    
    // MARK: - PKPaymentAuthorizationViewControllerDelegate
    
    /* 
        Whenever the user changed their shipping information we will receive a
        callback here.
    
        Note that for privacy reasons the contact we receive will be redacted, 
        and only have a city, ZIP, and country.
    
        You can use this method to estimate additional shipping charges and update
        the payment summary items.
    */
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didSelectShippingContact contact: PKContact, completion: (PKPaymentAuthorizationStatus, [PKShippingMethod], [PKPaymentSummaryItem]) -> Void) {
        
        /*
            Create a shipping method. Shipping methods use PKShippingMethod,
            which inherits from PKPaymentSummaryItem. It adds a detail property
            you can use to specify information like estimated delivery time.
        */
        let shipping = PKShippingMethod(label: "Standard Shipping", amount: NSDecimalNumber.zero())
        shipping.detail = "Delivers within two working days"
        
        /*
            Note that this is a contrived example. Because addresses can come from 
            many sources on iOS they may not always have the fields you want. 
            Your application should be sure to verify the address is correct, 
            and return the appropriate status. If the address failed to pass validation
            you should return `.InvalidShippingPostalAddress` instead of `.Success`.
        */
        
        let address = contact.postalAddress
        let requiresInternationalSurcharge = address!.country != "United States"
        
        let summaryItems = makeSummaryItems(requiresInternationalSurcharge: requiresInternationalSurcharge)
        
        completion(.Success, [shipping], summaryItems)
    }

    /*
        This is where you would send your payment to be processed - here we will 
        simply present a confirmation screen. If your payment processor failed the
        payment you would return `completion(.Failure)` instead. Remember to never
        attempt to decrypt the payment token on device.
    */
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: PKPaymentAuthorizationStatus -> Void) {
        
        paymentToken = payment.token

        completion(.Success)

        performSegueWithIdentifier(ProductTableViewController.confirmationSegue, sender: self)
    }

    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        // We always need to dismiss our payment view controller when done.
        dismissViewControllerAnimated(true, completion: nil)
    }
}
