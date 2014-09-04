### GenericKeychain ###

================================================================================
DESCRIPTION:

This sample shows how to navigate through the Keychain Services API
provided by iOS. Its demonstration leverages the Generic
Keychain Item class and provides a template on how to successfully set up calls 
to: SecItemAdd, SecItemCopyMatching, SecItemDelete, and SecItemUpdate.

The user interface is a master-detail designed in Interface Builder, archived in the MainWindow nib.
The user interface is modeled on a typical iOS app preferences screen. 

The sample builds two separate applications from the same code base. Both applications
have their own keychain item that stores a username and password. Both apps also share
a second keychain item that stores an account number. This takes advantage
of the shared keychain item capability added in iOS 3.0.

Testing:

The ability to share keychain items between apps is based on code signing entitlements. These
in turn are based on the app ID prefix that is contained in your provisioning profile. All
apps that share a keychain item must be built using the same app ID prefix.

The sample must be edited to include your app ID prefix in five places where the text "YOUR_APP_ID_HERE"
appears before building and running the sample apps. The easiest way to do that is to use Xcode's Find in Project
command to locate the places that must be edited first. Just change the app ID prefix; leave the rest unchanged.

Next, make GenericKeychain the active target and select Build and Go to run the first app GenericKeychain.

Finally, make GenericKeychain2 the active target and select Build and Go to run the second app GenericKeychain2.

NOTE:

Apps that are built for the simulator aren't signed, so there's no keychain access group
for the simulator to check. This means that all keychain items are in the same default access group
and all apps can see all keychain items when run on the simulator.

If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
simulator will return -25243 (errSecNoAccessForItem).

The sample is written to ignore the access group if built for the simulator.

================================================================================
BUILD REQUIREMENTS:

iOS 4 SDK

================================================================================
RUNTIME REQUIREMENTS:

iOS 3.2 or later

================================================================================
PACKAGING LIST:

AppDelegate
Adds the root navigation controller's view to the main window and displays the window when the 
application launches.

KeychainItemWrapper
Abstract interface to Keychain Services that wraps a single keychain item.

DetailViewController
Custom detail view controller.

EditorController
View controller subclass for abstracting an interface to either a text field or a text view.

MainWindow.xib
The nib file containing the main window and the view controllers used in the application.


================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
	Fixed minor memory leak and upgraded project to build with the iOS 4 SDK.

Version 1.1
    Adopted UITableView and UITableViewCell API for iPhone OS 3.0. Added support for
	shared keychain items. 

Version 1.0
    N/A

Copyright (c) 2008-2010 Apple Inc. All rights reserved.