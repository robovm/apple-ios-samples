### StateRestoreChildViews ###

===========================================================================
DESCRIPTION:

Demonstrates how to implement "State Preservation and Restoration" to restore parent/child view controller relationships.

The sample contains one parent view controller, which can host two different child view controllers. The user taps the segmented control to toggle between the two different children.
It shows how to preserve and restore the "current" child view controller. It encodes/decodes the segmented control state to decide which child to make visible. When the app is re-launched, it decodes the segmented control state as well as each child view, and properly adds the correct child to its parent. To make this all work properly, the parent view controller needs to encode/decode both children. In addition, to round out the sample, each child view controller restores it's text field state.
The parent and both children are required to have restoration identifiers.

===========================================================================
TESTING YOUR DEVICES:

Important Debugging Rule:
Be aware that the system automatically deletes an app’s preserved state when the user force quits the app. Deleting the preserved state information when the app is killed is a safety precaution. (The system also deletes preserved state if the app crashes at launch time as a similar safety precaution.) If you want to test your app’s ability to restore its state, you should not use the multitasking bar to kill the app during debugging. Instead, use Xcode to kill the app or kill the app programmatically by installing a temporary command or gesture to call exit on demand.

To remove or reset state resoration for a given app in the Simulator, to go this location:

~/Library/Application Support/iPhone Simulator/<iOS version>/Applications/<your app>/Library/Saved Application State/

Remove the contents in that folder.

===========================================================================
BUILD REQUIREMENTS:

iOS 6.0 SDK or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later, Automatic Reference Counting (ARC)

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.0 - First version.
1.1 - UIWindow's makeKeyAndVisible now called in willFinishLaunchingWithOptions.

===========================================================================
Copyright (C) 2013 Apple Inc. All rights reserved.
