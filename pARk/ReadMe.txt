### pARk ###

===========================================================================
DESCRIPTION:

pARk is an application project that demonstrates a how to use Core Motion's true north-referenced attitude API. It contains a UIView subclass, ARView, that displays a live camera feed with places-of-interest overlaid at the appropriate coordinates. The places-of-interest used are some famous parks around the world.

The project has the following classes and protocol, which (except where noted) have corresponding .h and .m file:

ARView —A UIView subclass that provides an augmented reality view of the specified places-of-interest. It uses AVFoundation to provide a live camera feed. It also uses Core Location to determine the user's location and Core Motion to determine where the user is facing (i.e. the user's attitude). When provided with an NSArray containing objects of type PlaceOfInterest, it computes the location of each place-of-interest relative to the user, and on every frame, it projects this onto the user's screen using the attitude provided by Core Motion. It then renders the UIView contained in each PlaceOfInterest at the projected location.

PlaceOfInterest —A class containing the data necessary to locate and render each place-of-interest (i.e. a UIView and a location).

pARkViewController —A view controller that feeds hard-coded places-of-interest to its ARView in viewDidLoad, starts the ARView in viewWillAppear, and stops the ARView in viewWillDisappear.

pARkAppDelegate —A standard implementation of the UIApplicationDelegate protocol. 

See "Motion Events" in Event Handling Guide for iPhone OS explains how to use the Core Motion API. The document also includes links to related Core Motion reference documentation.

If you run the compiled application on a device that does not have a gyroscope, you cannot use device motion data. You cannot effectively run the application on the simulator.

===========================================================================
BUILD REQUIREMENTS:

Xcode 4.2 or later; iPhone iOS SDK 5.0 or later.

===========================================================================
RUNTIME REQUIREMENTS:

iOS 5.0 or later. This app will not produce camera output on the iOS simulator.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0 First version.

===========================================================================
Copyright (C) 2011 Apple Inc. All rights reserved.