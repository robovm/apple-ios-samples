### PhotoMap ###
 
===========================================================================
DESCRIPTION:
 
The sample demonstrates how to load and display geotagged photos as MapKit annotations. It further demonstrates how to cluster multiple annotations together to reduce on-screen clutter.

This project was presented as a demo for WWDC 2011 session "Visualizing Information Geographically with MapKit”.

 
===========================================================================
BUILD REQUIREMENTS:
 
iOS SDK 7.0 or later.
 
===========================================================================
RUNTIME REQUIREMENTS:
 
iOS 7.0 or later.
 
===========================================================================
PACKAGING LIST:

LoadingStatus
- A view which displays a progress indicator, along with some text

PhotoAnnotation
- A MapKit annotation which represents a geotagged photo.

PhotoMapAppDelegate
- A basic UIApplication delegate which sets up the application.

PhotoMapViewController
- A UIViewController which handles the logic driving an MKMapView.

PhotosViewController
- Provides a view which displays multiple photos, allowing the user to pan between them.

Images/
- Several sample geotagged images.
 
===========================================================================
CHANGES FROM PREVIOUS VERSIONS:
 
1.0 - First version.
1.1 - First public release, upgraded to iOS 7 SDK, uses Storyboards and ARC.
 
===========================================================================
Copyright (C) 2011-2014 Apple Inc. All rights reserved.