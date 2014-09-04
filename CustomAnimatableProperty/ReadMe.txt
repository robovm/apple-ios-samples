### Custom Animatable Property ###

================================================================================
DESCRIPTION:

This sample shows how to animate a custom property defined within a CALayer subclass.By overriding -needsDisplayForKey and returning YES for custom CALayer subclass properties, Core Animation is instructed to automatically redraw a layer when that property changes. This technique can be leveraged whether the CALayer subclass belongs to a UIView or is standalone. This sample demonstrates explicit and implicit animation triggers, as well as basic and keyframe animation types. 

See the ANIMATION_TRIGGER and ANIMATION_TYPE defines respectively, within Defines.h to toggle between code paths implementing either.

================================================================================
BUILD REQUIREMENTS:

iOS SDK 7.0 or later

================================================================================
RUNTIME REQUIREMENTS:

iOS 7.0 or later

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

1.0 - First Version.

================================================================================
Copyright (C) 2014 Apple Inc. All rights reserved.
