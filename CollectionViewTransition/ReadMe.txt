Collection View Transition
==========================

This sample illustrates how to create a custom transition when navigating between two collection views in a navigation hierarchy managed by a navigation controller.  It uses a subclass of UICollectionViewTransitionLayout to help in the transition of the cell positions based on gesture position.

The application has two view collection view controllers that display images. The first is a stack view, the second is a grid view. You can transition from the stack to the grid by tapping on the stack. You can also use a pinch gesture, in which case you can control the speed of, and even reverse, the transition.

===========================================================================
BUILD REQUIREMENTS:

Xcode 5.0, iOS 7.0 or later

===========================================================================
RUNTIME REQUIREMENTS:

iOS 7.0 or later

===========================================================================
Copyright (C) 2013 Apple Inc. All rights reserved.