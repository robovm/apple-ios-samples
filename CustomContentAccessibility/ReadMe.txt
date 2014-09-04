CustomContentAccessibility

===========================================================================
ABSTRACT

This sample shows you how to support accessibility in a custom drawing UIView and UIControl, demonstrates how to create an accessibility element for each map item, and implement UIAccessibilityContainer protocol in the container view to interact with iOS accessibility system. The Guided Access Restriction API, which is newly introduced in iOS 7 for restricting functions when Guided Access enabled, is also demonstrated in this sample.

===========================================================================
DISCUSSION

- Support accessibility in an iOS app
There are basically three scenarios when supporting accessibility in an iOS app:

1. For UIView objects with static accessibility attribute values, simply set up in the Accessibility pane in Xcode Identity Inspector.
2. If you need to programmatically change the accessibility attribute values, override UIAccessibilityElement methods to return appropriate values.
3. For self-drawing items (which are not UIView objects) to support accessibility, you will have to create an accessibility element (UIAccessibilityElement) for each item, and implement UIAccessibilityContainer protocol in the container view.

This sample shows you how to handle the 2nd and 3rd scenario. The maps in this sample are drawn with codes. To support accessibility, this sample creates an accessibility element for each map items (meeting rooms, elevators, etc), and implements UIAccessibilityContainer in the plan view class to interact with iOS accessibility system. Based on the different user interaction mode, UIAccessibilityTraitAdjustable and UIAccessibilityTraitButton are applied to the custom UIControl for floor and coffee on/off control.

- Guided Access Restriction
Guided Access is a feature that restricts iOS to running only one app, while disabling the use of hardware buttons. Please see http://support.apple.com/kb/HT5509 for a description of how to enable and configure Guided Access on iOS.

UIGuidedAccessRestrictionDelegate protocol allows an app to specify additional features that can be disabled by users when in Guided Access mode. This sample implements it to restrict the functions of adjusting floor and showing coffer stops.

After running this sample in Guided Access mode, you can triple click Home button to show the Guided Access options. You'll see "CustomContentAccessibility" option in the right of Guided Access options bar, and can tap to disable the floor and coffer on/off control.

===========================================================================
BUILD REQUIREMENTS

iOS SDK 7.0

RUNTIME REQUIREMENTS

iOS 7.0 or later, iPad only.
Works only on the iPad device.

===========================================================================
PACKAGING LIST

APLAppDelegate
The app delegate, implementing UIGuidedAccessRestrictionDelegate protocol to restrict adjusting floor and showing coffer stops when in Guided Access mode.

APLViewController
The main view controller, presenting the maps and the other UI elements.

APLFloorPlanView
A custom UIView for drawing the plan view of the map, implementing UIAccessibilityContainer for the map items to support accessibility.

APLTitleView
A custom UIView for drawing the map title, overriding UIAccessibilityElement methods to supply accessibilityValue for current floor.

APLElevatorControl
A custom UIControl for adjusting the floor, implementing UIAccessibilityTraitAdjustable trait.

APLCoffeeControl
A custom UIControl for showing / hiding the coffee stops, implementing UIAccessibilityTraitButton trait.

APLCommon
Common constants for drawing the maps.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS

1.0 - First Version, converted from WWDCMaps sample from WWDC 2013.

===========================================================================
Copyright (C) 2010-2013 Apple Inc. All rights reserved.
