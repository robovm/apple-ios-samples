
### Multipeer Group Chat ###

===========================================================================
DESCRIPTION:

MultipeerGroupChat sample application utilizes the Multipeer Connectivity framework to enable nearby users to discover, connected, and send data between each other.  This sample simulates a simple chat interface where up to 8 devices can connect with each other and send text messages or images to each other.  Here you will learn how to bring up framework UI for discovery and connections and also how to monitor session state, listen for incoming data and resources, and send data and resources.

===========================================================================
BUILD REQUIREMENTS:

iOS 7.0 SDK

===========================================================================
RUNTIME REQUIREMENTS:

iOS 7.0 or later

===========================================================================
PACKAGING LIST:

AppDelegate.h/m
The application delegate class, responsible for application events and for bringing up the user interface.

SessionContainer.h/m
Container object for encapsulating the Multipeer Connectivity API including callings it's methods and implementing it's delegate protocols.

Transcript.h/m
Model class used as data source in the main chat room table view controller.  This class keeps state such as message direction, message text, image urls, image transfer progress.

ProgressObserver.h/m
Model class which implement KVO observation on the NSProgress class that the Multipeer Connectivity framework returns when URL resources are sent or received.  This class shows users how to monitor resource transfer progress and in turn update a progress bar via those progress updates.

MainViewController.h/m
The view controller loaded by the application delegate that is responsible for handling user events, selecting the correct filter, and passing accelerometer data through the filter and into the GraphView.

SettingsViewController.h/m
A modal view controller presented on first launch and subsequently when the user presses the "info" button in the main chat room view.  This view requires the user to enter a valid local display name to be advertised to other nearby peers.  It also requires the user to enter a "room name" aka Multipeer Connectivity service type which restricts discovery (advertising/browsing) to those using the same service type string.  This file also show how to use exception catching to determine if invalid display name or service type were entered.

MessageView.h/m
A container view class used to populate the contents for table view cells that related to string based messages sent or received between peers.

ImageView.h/m
A container view class used to populate the contents for table view cells that related to transferred images sent or received using the Multipeer Connectivity resource API.

ProgressView.h/m
A container view class used to populate the contents for table view cells that related to ongoing resource transfer progress.

main.m
Entry point for the application. Creates the application object, sets its delegate, and causes the event loop to start.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:


===========================================================================
Copyright (C) 2013 Apple Inc. All rights reserved.
