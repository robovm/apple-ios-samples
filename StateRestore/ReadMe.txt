### StateRestore ###

===========================================================================
DESCRIPTION:

Demonstrates how to implement and debug the APIs for "State Preservation and Restoration".

The sample itself manages a list of generic "items", each having notes attached to them.  The user taps an item to view it's detailed screen allowing them to type in the notes field.  The app saves these items using NSKeyedArchiver.

It shows how to preserve and restore two user interfaces within the app:

- the detail view controller restoring its current item, and UITextView's text content and its selection.  Note that the text selection state is restored automatically for us by UIKit.

- the main table view's multiple selection state, and edit mode state.

There is a combination of pertinent information from the Developer documentation and the WWDC 2012 session on state restoration.  The goal is to combine this information into a workable sample that can be used to show best practices, to debug and investigate.

Note:
All view controllers leading up to MyViewController must have a restoration identifier
(including our UINavigationController), or restoration will not work all restorationIdentifiers
are set in the storyboard, not in code

===========================================================================
TESTING YOUR DEVICES:

Important Debugging Rule:
Be aware that the system automatically deletes an app’s preserved state when the user force quits the app. Deleting the preserved state information when the app is killed is a safety precaution. (The system also deletes preserved state if the app crashes at launch time as a similar safety precaution.) If you want to test your app’s ability to restore its state, you should not use the multitasking bar to kill the app during debugging. Instead, use Xcode to kill the app or kill the app programmatically by installing a temporary command or gesture to call exit on demand.

In order to show how to use "UIDataSourceModelAssociation" to show how to restore the data source, the sample allows for table cells to be reordered.

===========================================================================
BUILD REQUIREMENTS:

iOS 6.0 SDK or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later, Automatic Reference Counting (ARC)

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.1 - Added restoration identifiers to UITextView and UITextField, fixed bug: text field was not being restored.
1.0 - First version.


===========================================================================
Copyright (C) 2013 Apple Inc. All rights reserved.
