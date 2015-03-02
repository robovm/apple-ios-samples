MapCallouts

===========================================================================
ABSTRACT

Demonstrates the use of the MapKit framework for iOS and OS X, displaying a map view with custom MKAnnotations each with custom callouts or custom MKAnnotationViews.  An annotation object on a map is any object that conforms to the MKAnnotation protocol and is displayed on the screen as a MKAnnotationView.  Through the use of the MKAnnotation protocol and MKAnnotationView, this application shows how you can extend annotations with custom strings and left/right calloutAccessoryViews.


Building and Linking with MapKit Framework for OS X:
————————————————————————————————————————————————————
If you don’t have the right entitlements to use MapKit framework, at runtime you will not see map detail and you will get this message in the console:

“Your Application has attempted to access the Map Kit API. You cannot access this API without an entitlement. You may receive an entitlement from the Mac Developer Program for use by you only with your Mac App Store Apps. For more information about Apple's Mac Developer Program, please visit developer.apple.com.”

In the Portal: 
1) Create an AppID with “Maps” enabled for both Development and Distribution.
2) Create the Mac Provisioning Profiles for Development and Distribution, that use this new AppID.

Then in Xcode:
3) Set the target’s CFBundleIdentifier to match the new AppID.
4) Select the appropriate “Team” for your target, in the “General” tab, under the “Identity” section.
5) In the “Capabilities” tab, turn on “App Sandbox” and “Maps”.  This will create and include an entitlements file in your project called “MapCallouts.entitlements” in order to link and run with MapKit.framework.


===========================================================================
DISCUSSION

This sample implements two different variations of MKPinAnnotationViews each with their own specific information.  One shows how to use a rightCalloutAccessoryView with a UIButtonTypeDetailDisclosure button and other with leftCalloutAccessoryView containing an image.


===========================================================================
BUILD REQUIREMENTS

iOS 7.0 SDK or later
OS X 10.9 SDK or later


===========================================================================
RUNTIME REQUIREMENTS

iOS 7.0 or later (as a universal app)
OS X 10.9 or later

Both use Automatic Reference Counting (ARC).


===========================================================================
CHANGES FROM PREVIOUS VERSIONS

1.5 - Added OS X version to this sample.

1.4 - Now shows use of MKMapView's "calloutAccessoryControlTapped" delegate method.

1.3 - Upgraded for iOS 6.0, added support for further customizing MKAnnotationView, now using Automatic Reference Counting (ARC), updated to adopt current best practices for Objective-C.

1.2 - Updated icons and artwork. Upgraded project to build with the iOS 4 SDK.

1.0 - Initial version published.

===========================================================================
Copyright (C) 2010-2014 Apple Inc. All rights reserved.
