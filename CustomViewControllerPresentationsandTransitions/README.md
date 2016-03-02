# Custom View Controller Presentations and Transitions

Custom View Controller Presentations and Transitions demonstrates using the view controller transitioning APIs to implement your own view controller presentations and transitions.  Learn from a collection of easy to understand examples how to use UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning, and UIPresentationController to create unique presentation styles that adapt to the available screen space.

**IMPORTANT**: This sample should be run on an iOS device. Some animations may not display correctly in the iOS Simulator.

### Cross Dissolve ###

This example implements a full screen presentation that transitions between view controllers using a cross dissolve animation.  It demonstrates the minimum configuration necessary to implement a custom transition.

### Swipe ###

This example implements a full screen presentation that transitions between view controllers by sliding the presented view controller on and off the screen.  You will learn how to implement UIPercentDrivenInteractiveTransition to add interactivity to your transitions.

### Custom Presentation ###

This example implements a custom presentation that displays the presented view controller in the lower third of the screen.  You will learn how to implement your own UIPresentationController subclass that defines a custom layout for the presented view controller, and responds to changes to the presented view controller's preferredContentSize.

### Adaptive Presentation ###

This example implements a custom presentation that responds to size class changes.  You will learn how to implement UIAdaptivePresentationControllerDelegate to adapt your presentation to the compact horizontal size class.

### Checkerboard ###

This example implements a transition between two view controllers in a UINavigationController.  You will learn how to take your transitions into the third dimension with perspective transforms, and how to leverage the snapshotting APIs to create copies of views.

### Slide ###

This example implements an interactive transition between two view controllers in a UITabBarController.  You will learn how to implement an interactive transition where the destination view controller could change in the middle of the transition.


REQUIREMENTS
--------------------------------------------------------------------------------

### Build ###

Xcode 6 or later

### Runtime ###

iOS 7.1 or later (Some examples require iOS 8.0 or later)

CHANGES FROM PREVIOUS VERSIONS:
--------------------------------------------------------------------------------

+ Version 1.0 
    - First release.



================================================================================
Copyright (C) 2016 Apple Inc. All rights reserved.
