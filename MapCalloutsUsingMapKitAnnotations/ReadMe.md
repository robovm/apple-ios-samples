# MapCallouts

## Abstract

Demonstrates the use of the MapKit framework for iOS and OS X, displaying a map view with custom MKAnnotations each with custom callouts or custom MKAnnotationViews.  An annotation object on a map is any object that conforms to the MKAnnotation protocol and is displayed on the screen as a MKAnnotationView.  Through the use of the MKAnnotation protocol and MKAnnotationView, this application shows how you can extend annotations with custom views, strings and callout accessory views.

## Discussion

This sample implements different variations of MKPinAnnotationView each with their own specific information:

  - BridgeAnnotation - shows a button in the rightCalloutAccessoryView.

  - WharfAnnotation - shows an image view in the detailCalloutAccessoryView.

  - SFAnnotation - uses a a custom flag image as its annotation and shows an image view in the leftCalloutAccessoryView.
  
  - CustomAnnotation - uses a custom view subclass, CustomAnnotationView, as its annotation.

## Building the Sample

### Building and Linking

If you don’t have the right entitlements to use MapKit framework, at runtime you will not see map detail and you will get this message in the console:

“Your Application has attempted to access the Map Kit API. You cannot access this API without an entitlement. You may receive an entitlement from the Mac Developer Program for use by you only with your Mac App Store Apps. For more information about Apple's Mac Developer Program, please visit developer.apple.com.”

In the Portal: 
1) Create an AppID with “Maps” enabled for both Development and Distribution.
2) Create the Mac Provisioning Profiles for Development and Distribution, that use this new AppID.

Then in Xcode:
3) Set the target’s CFBundleIdentifier to match the new AppID.
4) Select the appropriate “Team” for your target, in the “General” tab, under the “Identity” section.
5) In the “Capabilities” tab, turn on “App Sandbox” and “Maps”.  This will create and include an entitlements file in your project called “MapCallouts.entitlements” in order to link and run with MapKit.framework.


## Build Requirements

iOS 9.0 SDK or later
OS X 10.11 SDK or later


## Runtime Requirements

iOS 9.0 or later (as a universal app)
OS X 10.11 or later


Copyright (C) 2010-2015 Apple Inc. All rights reserved.
