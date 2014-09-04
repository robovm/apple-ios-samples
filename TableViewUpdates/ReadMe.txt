### Table View Animations and Gestures ###

Demonstrates how you can use animated updates to open and close sections of a table view for viewing, where each section represents a play, and each row contains a quotation from the play. It also uses gesture recognizers to respond to user input:
* A UITapGestureRecognizer to allow tapping on the section headers to expand the section;
* A UIPinchGestureRecognizer to allow dynamic changes to the height of table view rows; and
* A UILongPressGestureRecognizer to allow press-and-hold on table view cells to initiate an email of the quotation.


Main files:

APLTableViewController.{h,m}
A table view controller to manage display of quotations from a collection of plays. The controller supports opening and closing of sections. To do this it maintains information about each section using an array of SectionInfo objects.


APLSectionInfo.{h,m}
A section info object maintains information about a section:
 * Whether the section is open
 * The header view for the section
 * The model objects for the section -- in this case, the dictionary containing the quotations for a single play, and the name of the play itself
 * The height of each row in the section


APLSectionHeaderView.{h,m}
A view to display a section header, and support opening and closing a section.


APLQuoteCell.{h,m}
A table view cell to display information about a quotation.
 

APLAppDelegate.{h,m}
Application delegate: Loads information about plays and quotations stored in a property list, then passes it to the main table view controller.


APLPlay.{h,m}
A simple model class to represent a play with a name and a collection of quotations.


APLQuotation.{h,m}
A simple model class to represent a quotation with information about the character, and the act and scene in which the quotation was made.


PlaysAndQuotations.plist
A plist file that contains information about quotations made by various characters in different plays. The data is arranges as an array of "plays". Each play is a dictionary with the following keys:
@"playName": The name of the plays
@"quotations": An array of quotations

Each quotation is a dictionary with the following keys:
@"act": The act in the play in which the quotation appears
@"scene": The scene in the play in which the quotation appears
@"character": The name of the character making the quotation
@"quotation": The actual quotation


===========================================================================
Copyright (C) 2010-2013 Apple Inc. All rights reserved.
