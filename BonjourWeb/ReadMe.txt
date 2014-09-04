BonjourWeb

===========================================================================
DESCRIPTION:

Shows how to find network services that are advertised by Bonjour.

This application illustrates the fundamentals of browsing for network services using Bonjour. The BonjourBrowser hierarchically displays Bonjour domains and services as table views in a navigation controller. The contents of the table views are discovered and updated dynamically using NSNetServiceBrowser objects. Tapping an item in the services table causes the corresponding NSNetService object to be resolved asynchronously.  When that resolution completes, a delegate method is called which constructs a URL and opens it in Safari.

===========================================================================
BUILD REQUIREMENTS

iOS SDK 4.0

===========================================================================
RUNTIME REQUIREMENTS

iOS 4.0

===========================================================================
PACKAGING LIST

Classes/BonjourWebAppDelegate.h
Classes/BonjourWebAppDelegate.m
The application delegate.
It creates, displays and is the delegate for a BonjourBrowser.
When it gets the delegate callback, it constructs and launches a URL in Safari.

main.m
Standard application entry point.

BonjourSupport/BonjourBrowser.h
BonjourSupport/BonjourBrowser.m
A subclass of UINavigationController that handles the UI needed for a user to browse for Bonjour services.
It constructs and displays list view controllers for domains and service instances.

BonjourSupport/BrowserViewController.h
BonjourSupport/BrowserViewController.m
View controller for the service instance list.
This object manages a NSNetServiceBrowser configured to look for Bonjour services.
It has an array of NSNetService objects that are displayed in a table view.
When the service browser reports that it has discovered a service, the corresponding NSNetService is added to the array.
When a service goes away, the corresponding NSNetService is removed from the array.
Selecting an item in the table view asynchronously resolves the corresponding net service.
When that resolution completes, the delegate is called with the corresponding net service.

BonjourSupport/DomainViewController.h
BonjourSupport/DomainViewController.m
View controller for the domain list.
This object manages a NSNetServiceBrowser configured to look for Bonjour domains.
It has two arrays of NSString objects that are displayed in two sections of a table view.
When the service browser reports that it has discovered a domain, that domain is added to the first array.
When a domain goes away it is removed from the first array.
It allows the user to add/remove their own domains from the second array, which is displayed in the second section of the table.
When an item in the table view is selected, the delegate is called with the corresponding domain.

BonjourSupport/SimpleEditViewController.h
BonjourSupport/SimpleEditViewController.m
View controller which allows the user to enter a small amount of text.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS

Version 2.9
- Updated to work with iOS SDK 4.0.

Version 2.8
- Fixed bug updating cells when all services are removed during a resolve.

Version 2.7
- Fixed table selection bug when no services are listed. 

Version 2.6
- Upgraded for 3.0 SDK due to deprecated APIs; in "cellForRowAtIndexPath" it now uses UITableViewCell's initWithStyle. 

Version 2.5
- Updated for and tested with iPhone OS 2.0. First public release.

Version 2.4
- Updated for Beta 7.
- Significant code changes that adopt Bonjour best practices.

Version 2.3
- Updated for Beta 6.
- Added LSRequiresIPhoneOS key to Info.plist.

Version 2.2
- Updated for Beta 5.
- Converted from CFNetService/CFNetServiceBrowser to NSNetService and NSNetServiceBrowser.

Version 2.1
- Updated for Beta 4. Added code signing.

Version 2.0
- Removed check for kCFNetServiceFlagIsDomain flag as BrowserViewController only browses for services.
- Changed code so that the application now:
-- Updates the UI only once there are no more add/remove events coming.
-- Starts the resolve after the selection has changed rather than before it changes.
-- Takes into account the port number and the various fields from the TXT record when constructing the URL.
-- Asynchronously resolves services; the user should control cancelation, rather than an arbitrary timeout.
-- Shows the network status activity indicator when resolving 
-- Uses a nib file for the main window.

================================================================================
Copyright (C) 2008-2010 Apple Inc. All rights reserved.
