# KeychainTouchID: Using Touch ID with keychain and LocalAuthentication

KeychainTouchID shows how the store Touch ID protected items to keychain and how to query for the items with custom message prompts. It also shows how to use the new keychain item accessibility class which invalidates item when the passcode is removed. It also shows how to use LocalAuthentication to invoke Touch ID verification without involving the keychain.

The LocalAuthentication sample is implemented in AAPLLocalAuthenticationTestsViewController while the keychain sample is implemented in AAPLKeychainTestsViewController. Both classes are inherited from AAPLBasicTestViewController which just implements the shared table view handling and launching of the tests defined in AAPLLocalAuthenticationTestsViewController and AAPLKeychainTestsViewController.

Note that the LocalAuthentication framework requires Touch ID. You can implement your own authentication to support devices without Touch ID.

## Requirements
This sample requires a device with Touch ID and passcode enabled. The keychain test will work on devices without Touch ID; iOS will fall back to the passcode prompt in that case. The LocalAuthentication test on the other hand requires Touch ID.

This sample does not support the simulator.

### Build

iOS 8 SDK or later

### Runtime

iOS 8 or later

Copyright (C) 2014 Apple Inc. All rights reserved.
