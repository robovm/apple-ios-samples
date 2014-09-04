
### URLCache ###


DESCRIPTION
===========

The purpose of this sample is to demonstrate how an iPhone application can download a resource off the web, store it in the application's data directory, and use the local copy of the resource. The URLCache sample also demonstrates how to implement a couple of caching policies:

1. The local copy of a web resource should remain valid for a period of time (for example, one day) during which the web is not re-checked.

2. The HTTP header's Last-Modified date should be used to determine the last time a web resource changed before re-downloading it.

The audience for this sample is iPhone developers using resources such as images that are retrieved or updated from the web.

URLCache uses the Cocoa URL loading system (see below) to load the resource from the web. URLCache can load any resource available using the HTTP protocol, but it's designed to load and display images. During launch, URLCache loads a file named URLCache.plist that contains the URL of a NOAA "image of the day" site. The application then loads the image specified by this URL. (To change the URL, use Xcode to open the file URLCache.plist and edit the first entry in the file.)

The term "update" means to check the last modified date of an image to see if we need to load a new version. If more than 24 hours has elapsed since a cached image was last updated, and you press the Display Image button, the image is updated. If the cache is empty or the image has changed, the image is automatically loaded from the web. The UI displays the date and time the cached image was last updated. (In this implementation, this Updated date is the file modification date of the local cached copy of the image.)

The Display Image button checks the cache for the NOAA image. If the image is not found in the cache, it is loaded from the web. Otherwise, the image in the cache is displayed. In addition, this button performs an update operation if more than one day has elapsed since the last update. When the application launches, it uses the same logic to automatically display the image.

The Clear Cache button removes all locally cached images from the cache directory, which is located inside the application data directory.


RELATED INFORMATION
===================

The Foundation framework provides a set of classes for interacting with URLs and communicating with servers using standard Internet protocols. Together these classes are referred to as the Cocoa URL loading system. The most important classes in this API are listed below.

NSURLCache
NSURLConnection
NSURLRequest
NSURLResponse
NSCachedURLResponse

See the document "URL Loading System" for more information.

The URLCache sample uses the application data directory to cache local copies of images. For more information about the data directory, see "The Application Sandbox" in iPhone OS Programming Guide.

The images that this application retrieves and displays are made available by the Operational Significant Event Imagery (OSEI) team of the National Oceanic and Atmospheric Administration (NOAA). Apple acknowledges NASA, NOAA, and the OSEI team as the supplier of these public domain images.

The OSEI image of the day changes on a daily basis during the work week. For more information about these images and their terms of use, see:

http://www.osei.noaa.gov/


BUILD REQUIREMENTS
==================

iOS 4.0 SDK


RUNTIME REQUIREMENTS
====================

iOS 3.2


PACKAGING LIST
==============

URLCacheAppDelegate.h
URLCacheAppDelegate.m

Acts as the delegate for the UIApplication instance. In the applicationDidFinishLaunching: method, it creates the application's view controller and embeds its view in the application window.

URLCacheController.h
URLCacheController.h

This is the custom view controller class for the view that contains the application UI. In the viewDidLoad: method, it embeds the application's UI in the main window. Contains the controller logic for the view that contains the application's UI.

URLCacheConnection.h
URLCacheConnection.m

Initiates an asynchronous retrieval of web resources using NSURLConnection and implements delegate methods for the connection object to handle events during the load.

URLCacheAlert.h
URLCacheAlert.m

Utility functions for displaying UIAlertView alerts.

Default.png
Icon.png

Application images.

MainWindow.xib
MainView.xib

Nib files that contain the application UI including the toolbar.

Localizable.strings

Table of localized strings that are displayed in the UI.
English version generated using this command:
(set default directory to project directory)
genstrings -o en.lproj Classes/*.m

URLCache.plist

A list of URLs that specify images. Only the first image is used in this sample.


CHANGES FROM PREVIOUS VERSIONS
==============================

Version 1.0 - First release.
Version 1.1 - Fixed several minor bugs. Upgraded project to build with iOS 4.0 SDK.


Copyright (C) 2008-2010 Apple Inc. All rights reserved.
