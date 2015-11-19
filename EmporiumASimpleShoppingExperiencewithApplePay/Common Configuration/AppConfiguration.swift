/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Handles application configuration logic and information.
*/

import Foundation

public class AppConfiguration {
    /*
        The value of the `EMPORIUM_BUNDLE_PREFIX` user-defined build setting is
        written to the Info.plist file of every target in Swift version of the
        Emporium project. Specifically, the value of `EMPORIUM_BUNDLE_PREFIX` is
        used as the string value for a key of `AAPLEmporiumBundlePrefix`. This value
        is loaded from the target's bundle by the lazily evaluated static variable
        "prefix" from the nested "Bundle" struct below the first time that "Bundle.prefix" 
        is accessed. This avoids the need for developers to edit both `EMPORIUM_BUNDLE_PREFIX`
        and the code below. The value of `Bundle.prefix` is then used as part of 
        an interpolated string to insert the user-defined value of `EMPORIUM_BUNDLE_PREFIX` 
        into several static string constants below.
    */
    private struct Bundle {
        static var prefix = NSBundle.mainBundle().objectForInfoDictionaryKey("AAPLEmporiumBundlePrefix") as! String
    }
    
    struct UserActivity {
        static let payment = "\(Bundle.prefix).Emporium.payment"
    }
    
    struct Merchant {
        static let identififer = "merchant.\(Bundle.prefix).Emporium"
    }
}
