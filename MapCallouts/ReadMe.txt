MapCallouts

===========================================================================
ABSTRACT

Demonstrates the use of the MapKit framework, displaying a map view with custom MKAnnotations each with custom callouts or custom MKAnnotationViews.  An annotation object on a map is any object that conforms to the MKAnnotation protocol and is displayed on the screen as a MKAnnotationView.  Through the use of the MKAnnotation protocol and MKAnnotationView, this application shows how you can extend annotations with custom strings and left/right calloutAccessoryViews.

===========================================================================
DISCUSSION

This sample implements two different variations of MKPinAnnotationViews each with their own specific information.  One shows how to use a rightCalloutAccessoryView with a UIButtonTypeDetailDisclosure button and other with leftCalloutAccessoryView containing an image.


===========================================================================
BUILD REQUIREMENTS

iOS 6.0 SDK or later

===========================================================================
RUNTIME REQUIREMENTS

iOS 5.0 or later, Automatic Reference Counting (ARC)

===========================================================================
PACKAGING LIST

AppDelegate
Configures and displays the application window and navigation controller.

MapViewController
The primary view controller containing the MKMapView, adding and removing both MKPinAnnotationViews through its toolbar.

BridgeAnnotation
The custom MKAnnotation object representing the Golden Gate Bridge.

SFAnnotation
The custom MKAnnotation object representing the city of San Francisco.

CustomMapItem
The custom MKAnnotation object representing a generic location, hosting a title and image.

CustomAnnotationView
The custom MKAnnotationView object representing a generic location, displaying a title and image.

DetailViewController
The detail view controller used for displaying the Golden Gate Bridge.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS

1.4 - Now shows use of MKMapView's "calloutAccessoryControlTapped" delegate method.

1.3 - Upgraded for iOS 6.0, added support for further customizing MKAnnotationView, now using Automatic Reference Counting (ARC), updated to adopt current best practices for Objective-C.

1.2 - Updated icons and artwork. Upgraded project to build with the iOS 4 SDK.

1.0 - Initial version published.

===========================================================================
Copyright (C) 2010-2013 Apple Inc. All rights reserved.
