### DocInteraction ###

================================================================================
DESCRIPTION:

This sample how to use UIDocumentInteractionController to obtain information about documents and how to preview them.  There are two ways to preview documents: one is to use UIDocumentInteractionController's preview API, the other is directly use QLPreviewController.  This sample also demonstrates the use of UIFileSharingEnabled feature so you can upload documents to the application using iTunes and then preview them.  With the help of "kqueue" kernel event notifications, the sample monitors the contents of the Documents folder.

In addition it leverages UIDocumentInteractionController's built-in UIGestureRecognizers.  That is, single tap = preview, tap-hold = options menu, by attaching them to the display icon.

DirectoryWatcher
An object used to help monitor the contents of the "Documents" folder by using "kqueue", a kernel event notification mechanism.
Normally apps would use these UIApplication delegate calls to scan the Documents folder for content changes:

	- (void)applicationDidBecomeActive:(UIApplication *)application;
	- (void)applicationWillResignActive:(UIApplication *)application;

With the DirectoryWatcher object, rather, you can detect changes without having to
unnecessarily scan the Documents folder in numerous places in your code.

Since this sample uses "UIFileSharingEnabled", it is easy to test DirectoryWatcher observing
the Documents folder with iTunes.  Once the app is installed on the device, open iTunes,
select the device, refer the apps for that device and look for "DocInteraction" in the
File Sharing section.  From there you are free to upload files to its Documents folder.
While the app is running, you will see the newly uploaded files appear in its table view.

================================================================================
BUILD REQUIREMENTS:

iOS SDK 7.0 or later

================================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.6 - Upgraded to iOS 7.0 SDK, now uses Storyboards in favor of XIB.
1.5 - Upgraded for iOS 6.0 SDK, updated to adopt current best practices for Objective-C, now uses Automatic Reference Counting (ARC) and NSByteCountFormatter. 
1.4 - Upgraded to support iOS 5.0 SDK, added QLPreviewControllerDelegate to DITableViewController.h.
1.3 - Upgraded to support iOS 4.2 SDK, QLPreviewController now navigates to a separate screen.
1.2 - Fixed Xcode project deployment target to 4.0.
1.1 - Modified and improved for previewing files in the Documents folder.
1.0 - First Version, released for WWDC 2010

================================================================================
Copyright (C) 2010-2014 Apple Inc. All rights reserved.
