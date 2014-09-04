### MessageComposer ###

================================================================================
DESCRIPTION:

MessageComposer illustrates how to use the MessageUI framework to compose and send email and SMS messages from within your application.
This application uses the MFMailComposeViewController and MFMessageComposeViewController classes of the MessageUI framework.  These two classes manage user interfaces that allows users to compose and send email and SMS messages from within their applications, respectively.

MessageComposer displays two buttons labeled "Compose Mail" and "Compose SMS."
When users tap on "Compose Mail" and "Compose SMS," the application respectively shows an email composition interface and an SMS composition interface. 
The application shows either of these composition interfaces if their respective classes exist and the device is configured for sending email or SMS. It provides a feedback message, otherwise.

================================================================================
BUILD REQUIREMENTS:

iOS 6.0 SDK or later
 
================================================================================
RUNTIME REQUIREMENTS:

iOS 5.0 or later
 
================================================================================
PACKAGING LIST:

MessageComposerAppDelegate.{h,m}
    Application delegate that sets up a UIViewController with two UIButton's and a UILabel. 

MessageComposerViewController.{h,m}
    UIViewController that includes two UIButton's and a UILabel.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
- Migrated to Storyboards and ARC.
- Updated to target iOS 5.

Version 1.1
- Changed the rainy.png image into JPEG format, because PNG-optimization made it unreadable on some platforms when sent as an attachment.

Version 1.0
- First version (Formerly known as MailComposer).

================================================================================
Copyright (C) 2010-2013 Apple Inc. All rights reserved.