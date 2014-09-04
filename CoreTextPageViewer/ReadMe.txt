
### CoreTextPageViewer ###

===========================================================================
DESCRIPTION:

This sample shows how to use CoreText to display large amounts of text on a page 
basis using a flexible frame structure. 

This sample is based on a sample used for WWDC 2010, Session #110, "Advanced Text Handling
for iPhone OS".  The session can be viewed at <http://developer.apple.com/videos/wwdc/2010/>

To use this sample, you may select from a list of example documents via the
"Samples" list, and you may make document-wide overrides of the used font and
font features via the "Fonts and Features" list.  To paginate through an example 
document, swipe left or right.  Note that while some fonts support applying multiple 
font features simultaneously, for simplicity this sample only allows setting
one font feature override at a time.

Please see the ReadMe.xml sample document in this sample itself for more
details on the application architecture.

===========================================================================
BUILD REQUIREMENTS:

OS X 10.8, iOS 7.0 SDK

===========================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later, iPad only

===========================================================================
PACKAGING LIST:

AppDelegate.{h,m}
A simple application delegate to display the application's window.

RootViewController.{h,m}
The root view controller that manages the main Core Text scroll view and popovers.

SamplesController.{h,m}
A table view controller to manage and display a list of file names of sample documents to draw.

FontFamsController.{h,m}
A table view controller to manage and display a list of font families to use, and supported
font features.

AttributedStringDoc.{h,m}
Manages the construction of AttributedStrings from xml/plist documents. These documents are generated on Mac OS X using the AttributedStringDoc Gen sibling project to this demo. It takes an RTF document created using TextEdit, reads it into an AttributedString, and finally proceeds to serialize it into a format (xml/plist) that is readable by the AttributedStringDoc class. In fact, the AttributedStringDoc class is also used on the desktop to serialize the file.
 
This class also keeps track of the characteristics of the document: background colors, frames for each page, page number display, and number of columns to display.
 
CoreTextScrollView.{h,m}
Manages the display of pages for a given document to display. This is the view that you will use in Interface Builder or create directly to display and interact with an AttributedStringDoc in an application. 

It is also fair to say that this view acts as a controller for CoreTextViews. You can change the page to display, manage text selection, and change font parameters for the document.

TextAccessibilityElement.{h,m}
This class defines the Accessibility features for CoreTextScrollView.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0

First version, incorporates the following changes from WWDC version:
  - viewDidUnload now releases IBOutlets, added localization support, fixed rotation layout bug.
  - Prevented tap in search bar from dismissing popover. Added presentation of an alert sheet when the user taps the Clear Recents button. 
  - Amended method signature in delegate protocol to conform to Cocoa conventions.
  - Removed text search functionality, addressed in separate sample.
  - Combined font and font feature UI into single popover.
  
Version 1.1
  - Fixed compiler and Static Analyzer warnings.
  - Updated with storyboard and auto layout.

===========================================================================
Copyright (C) 2011~14 Apple Inc. All rights reserved.

