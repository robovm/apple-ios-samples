# LookInside: An example application demonstrating presentation controllers, adaptivity, and custom animator objects

This example shows how to use a custom presentation controller to create a custom view controller presentation. It provides a transitioning delegate to the view controller, which vends a presentation controller and animator object.

## Project Contents

The LookInside project contains the following interesting classes:

 - AAPLRootViewController
     - This is the root view controller of the application. It provides a scrolling grid of photos through a UICollectionView. When one of the photos is tapped, it performs a view controller presentation

 - AAPLOverlayViewController
     - This is the view controller for the photo editing interface. It has an image view, some sliders, and a save button. It uses CoreImage to change the HSV of the image
     - Note that the view controller provides no dimming views, borders, or other chrome

 - AAPLOverlayTransitioningDelegate
     - This is the transitioning delegate used for the Overlay presentation style. It implements the UIViewControllerTransitioningDelegate protocol to provide a custom animator object and presentation controller

 - AAPLOverlayAnimatedTransitioning
     - This is the animator object used for the Overlay presentation style. It animates the presented view controller in from the right side of the display with a spring animation

 - AAPLOverlayPresentationController
     - This is the presentation controller used for the Overlay presentation style. It provides sizing information for the presented view controller to position it on the right edge of the display. It also provides a dimming view for use in the presentation. It implements a gesture on the dimming view to dismiss the presented view controller

 - AAPLCoolTransitioningDelegate
     - This is the transitioning delegate used for the Cool presentation style. It implements the UIViewControllerTransitioningDelegate protocol to provide a custom animator object and presentation controller

 - AAPLCoolAnimatedTransitioning
     - This is the animator object used for the Cool presentation style. It animates the presented view controller in from the center of the display using a scale animation

 - AAPLCoolPresentationController
     - This is the presentation controller used for the Cool presentation style. It provides sizing information for the presented view controller to position it in the center of the display. It positions a pink view behind the presented view controller. It also provides custom chrome - leopard print borders, a pink flower, and a unicorn

## Requirements

### Build

iOS 8 SDK

### Runtime

iOS 8 or later

Copyright (C) 2014 Apple Inc. All rights reserved.
