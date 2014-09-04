### AlternateViews ###

===========================================================================
DESCRIPTION:

This sample demonstrates how to implement alternate or distinguishing views for particular device orientations.  Doing so can be useful if your app displays different content between orientations or if your app uses vastly different layouts between orientations which cannot be reconciled by auto layout or programatic layout alone.

Two different techniques are illustrated:

AlternateViewControllers:
The simpler technique.  Two separate view controllers are used (one for portrait, another for landscape).  The portrait view controller is the initial view controller.  Upon receiving a UIDeviceOrientationDidChangeNotification it presents or dismisses the landscape view controller.  This technique should be preferred if the landscape view controller should always cover any bars on the screen (It should always be full screen) or if little controller code is shared between the portrait and landscape views.  There are also a few limitations:
* It is difficult to share controller code between the portrait and landscape views; because each is implemented in a separate view controller.
* The landscape view will always be presented atop any navigation bars or tab bars present in the portrait orientation.

AlternateViews:
A more involved technique that does not share the limitations of AlternateViewControllers.  The portrait and landscape views are defined in XIB files which are loaded and swapped in as a subviews of a single view controller's view, dependent on the current device orientation.  This technique should be preferred if the portrait and landscape views must both be confined to a container view (a Navigation Controller or Tab Bar Controller), or if there is an opportunity to share large amounts of controller code between the two views.  This technique comes with its own limitations:
* The separate views must be defined in XIBs or programatically.
* No direct access to the top and bottom layout guides of the view controller from the views.  A workaround for this limitation is demonstrated.


===========================================================================
USING THE SAMPLE:

When launched, notice the view says "Portrait".  Rotate the device to landscape right or landscape left positions and the view changes to the alternate one supporting landscape.


===========================================================================
BUILD REQUIREMENTS:

iOS 7.0 SDK or later


===========================================================================
RUNTIME REQUIREMENTS:

iOS 6.0 or later


===========================================================================
PACKAGING LIST:

AlternateViewControllers
    main.m
        - Main source file for this sample.

    AppDelegate.{h,m}
        - The application's delegate.

    NavigationController.{h,m}
        - UINavigationController subclass that forwards queries about its supported interface orientations to its child view controllers.
        - Only necessary if targeting iOS 6; iOS 7 only apps should provide a delegate that implements -navigationControllerSupportedInterfaceOrientations: instead.
        
    PortraitViewController.{h,m}
        - The application view controller used when the device is in portrait orientation.
        
    LandscapeView.{h,m}
        - The view controller shown when the device is in landscape orientation.

AlternateViews
    main.m
        - Main source file for this sample.

    AppDelegate.{h,m}
        - The application's delegate.
        
    LayoutSupport.h
        - Protocol adopted by both PortraitView and LandscapeView.  Enables ViewController to pass its layout guides to the orientation specific views.

    ViewController.{h,m}
        - A view controller with different views for portrait and landscape orientations.
        
    PortraitView.{h,m}
        - The view used by ViewController while in portrait orientation.
        
    LandscapeView.{h,m}
        - The view used by ViewController while in landscape orientation.


===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.3
- Updated project to build with the iOS 7 SDK.
- Now a universal app.
- Introduces a new technique for implementing alternate views.

Version 1.2
- Updated project to build with the iOS SDK 6.
- Deployment target set to iOS 4.3.
- Now uses ARC.
- Included launch images and missing retina versions of certain icons.

Version 1.1
- Upgraded project to build with the iOS 4.0 SDK.

Version 1.0
- First version.

===========================================================================
Copyright (C) 2009-2014 Apple Inc. All rights reserved.
