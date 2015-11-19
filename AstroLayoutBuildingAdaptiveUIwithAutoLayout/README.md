# AstroLayout: Building Adaptive UI with Auto Layout

This sample demonstrates how to properly activate and deactivate groups of constraints in response to a size class change. It also shows how to animate layout changes using UIView animations. This code leverages layout guides and anchors to reduce code overhead and allow for more complex layouts.

Constraint changes can be found in -traitCollectionDidChange: for size class changes. There are also gestures set up to trigger animations outside of size class changes. Double-tap will trigger an animated change between regular and compact layouts regardless of the current horizontal size class. This is achieved by putting the calls to deactivate and activate inside an animation block. Double-tapping with two fingers (hold down option in the simulator to get the extra touch) triggers a keyframe-based animation that activates and deactivates a few individual constraints at a time, leading to a more staggered animation. 

In this example, the constraints that need to change are held on to both as individual constraints (for the keyframe animation) and as arrays of constraints (for the more basic animation). Generally you will not need to do both, but both are used here to demonstrate the different types of animations you can use with auto layout. For most uses, holding on to arrays of constraints will suffice to keep your layout flexible and allow you to animate well.

## Requirements

### Build

Xcode 7.0, iOS 9.0 SDK

### Runtime

iOS 9.0

Copyright (C) 2015 Apple Inc. All rights reserved.
