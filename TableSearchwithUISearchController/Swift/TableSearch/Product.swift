/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The data model object describing the product displayed in both main and results tables.
*/

import Foundation

class Product: NSObject, NSCoding {
    // MARK: Types
    
    enum CoderKeys: String {
        case nameKey
        case typeKey
        case yearKey
        case priceKey
    }
    
    enum Hardware: String {
        case iPhone = "iPhone"
        case iPod = "iPod"
        case iPodTouch = "iPod touch"
        case iPad = "iPad"
        case iPadMini = "iPad Mini"
        case iMac = "iMac"
        case MacPro = "Mac Pro"
        case MacBookAir = "Mac Book Air"
        case MacBookPro = "Mac Book Pro"
    }
    
    // MARK: Properties
    
    let title: String
    let hardwareType: String
    let yearIntroduced: Int
    let introPrice: Double
    
    // MARK: Initializers
    
    init(hardwareType: String, title: String, yearIntroduced: Int, introPrice: Double) {
        self.hardwareType = hardwareType
        self.title = title
        self.yearIntroduced = yearIntroduced
        self.introPrice = introPrice
    }
    
    // MARK: NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        title = aDecoder.decodeObjectForKey(CoderKeys.nameKey.rawValue) as! String
        hardwareType = aDecoder.decodeObjectForKey(CoderKeys.typeKey.rawValue) as! String
        yearIntroduced = aDecoder.decodeIntegerForKey(CoderKeys.yearKey.rawValue)
        introPrice = aDecoder.decodeDoubleForKey(CoderKeys.priceKey.rawValue)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(title, forKey: CoderKeys.nameKey.rawValue)
        aCoder.encodeObject(hardwareType, forKey: CoderKeys.typeKey.rawValue)
        aCoder.encodeInteger(yearIntroduced, forKey: CoderKeys.yearKey.rawValue)
        aCoder.encodeDouble(introPrice, forKey: CoderKeys.priceKey.rawValue)
    }
    
    // MARK: Device Type Info

    class var deviceTypeNames: [String] {
        return [
            Product.deviceTypeTitle,
            Product.desktopTypeTitle,
            Product.portableTypeTitle
        ]
    }
    
    class var deviceTypeTitle: String {
        return NSLocalizedString("Device", comment:"Device type title")
    }

    class var desktopTypeTitle: String {
        return NSLocalizedString("Desktop", comment:"Desktop type title")
    }

    class var portableTypeTitle: String {
        return NSLocalizedString("Portable", comment:"Portable type title")
    }
}
