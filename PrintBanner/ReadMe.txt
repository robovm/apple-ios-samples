### PrintBanner ###

================================================================================
DESCRIPTION:

This sample demonstrates how to print to a roll-fed AirPrint printer.

================================================================================
USING THE SAMPLE:

1. Launch the PrintBanner project using Xcode.
2. Make sure the project's current target is set to PrintBanner.
3. Build and run the PrintBanner target.
4. Enter the text you'd like to print as a banner.
5. Choose a font—Typed, Script, Courier, Arial.
6. Choose a text color—Black, Orange, Purple, Red.
7. Click Print.
8. Choose Simulated Label Printer.
9. By default, the label printer has an address label loaded. Load a roll to allow for banner printing. 


================================================================================
BUILD REQUIREMENTS:

iOS 7.0 SDK or later

================================================================================
RUNTIME REQUIREMENTS:

iOS 7.0 or later

================================================================================
PACKAGING LIST:

main.m 
    	Main source file for this sample.

AppDelegate.{h,m}
	The application delegate class for installing the app's view controller.

ViewController.{h,m}
	The main view controller containing the app's user interface. Sets up printing using input from the user (text, font, font color). Calculates a font size that optimizes banner text for the width of the available paper. Calculates a cut-size based on the length of the text.

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0
- Preliminary draft for WWDC 2013 AirPrint session.

Version 1.1 
- First public release which includes minor UI changes.

================================================================================
Copyright (C) 2013-2014 Apple Inc. All rights reserved.