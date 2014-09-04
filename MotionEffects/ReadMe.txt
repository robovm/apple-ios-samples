### MotionEffects ###

================================================================================
DESCRIPTION:

MotionEffects demonstrates applying motion effects to views in order to enhance the illusion of depth by creating parallaxing  effects.

Note: Motion effects are disabled in the iOS simulator and when sharing your screen over AirPlay.

This sample is broken down into three different parts, each demonstrating a unique way to use motion effects.

+ BASIC INTERPOLATION +
The Basic Interpolation example demonstrates the application of a UIInterpolatingMotionEffect to the position property of one or more views.  Two views are used with the former overlying the latter.  Switches allow the user to toggle the motion effects on both views in order to observe how applying motion effects to the foreground view, background view, or both affects the illusion of depth.  Enabling motion effects on the background view results in the background appearing to be inset, or recessed relative to the screen plane.  Enabling motion effects on the foreground view results in the foreground view appearing to float above the background, revealing the contents underneath its edges as the user tilts the device.  A more balanced effect can be achieved by enabling motion effects on both the foreground and background.

+ PARALLAX BLUR +
The Parallax Blur example demonstrates how a view with motion effects applied can blur the contents underneath it with minimal CPU overhead.  While not a truly dynamic blur, the contents underneath the view will be blurred as the motion effects alter the view's position.  

To create the effect, first a snapshot of the background is taken and then blurred.  Since this example uses an image as the background, a blurred copy of this image was created beforehand and included as a resource.  For more dynamic applications, the –drawViewHierarchyInRect:afterScreenUpdates: method can capture the current contents of the background and the Core Image or vImage APIs can be used to produce a blurred copy.  A UIImageView is initialized with the blurred snapshot and placed at the back of the motion-effected view's subview tree.  This UIImageView must be sized to match the size of the blurred snapshot.  * Make sure to set clipsToBounds to YES on the motion-effected view *   A second set of motion effects is created with the opposite minimum and maximum values used for the motion effects applied to the view.  This new set of motion effects is applied to the UIImageView containing the blurred snapshot.  You can create a tinted blur by applying a background color to the view and lowering the opacity of the UIImageView containing the blurred snapshot.

+ CUSTOM MOTION EFFECT +
The Custom Motion Effect example demonstrates how to create your own UIMotionEffect subclass.  Creating your own motion effect subclass may be necessary if the linear interpolation offered by UIInterpolatingMotionEffect is not enough to express your desired effect.  See the comments in PerspectiveMotionEffect.m for a discussion of the method you must implement and what your implementation must do.  This example implements a custom motion effect that alters its target's sublayerTransform, simulating camera that rotates around a configurable point-of-interest as the viewer offset changes.  This perspective motion effect is used to bring a specially-prepared image to life by allowing the viewer to look behind objects in the foreground as they tilt the device.

While not pertinent to understanding how to create custom motion effects, some may be interested in the steps taken to prepare the image used in this example.  A good image to use for this effect is one with multiple minimally overlapping objects at different depths, and where the edges of those objects run parallel to the viewer plane.  The goal of the pre-processing is to separate the key objects from the source image into layers, grouped by their estimated (or known) depth in the original scene.  This example uses seven layers which can be found in the "Parallax Layers" folder.  The space occupied by objects on higher layers (closer to the camera) must be filled in on the lower (further away or background) layers.  Notice how the Sky layer in this example spans the entire width of the image uninterrupted.  If you have the luxury of working with a computer generated scene, you can render your scene multiple times with the appropriate objects visible in each pass.  For existing images, such as the one used for this example, you will need to digitally reconstruct the background behind the objects that have been extracted to higher layers [1].

Each layer is assigned a point in 3D space which, when viewed through the virtual camera, best recreates the layer's depth [2] in the original image.  Assuming each layer is the same size, this is a matter of choosing appropriate points along the Z-axis to position the layer.  You can see the final result of this step in -[CustomMotionEffectVC viewDidLayoutSubviews].  For the best result, you should prototype this step in a 3D graphics program.  Create textured planes for the layers and a virtual camera to view the scene through.  Move the virtual camera slightly to the left and right to see how the effect composes, modifying the position of each layer's plane until satisfied.  The positions of the planes and virtual camera can be copied directly into the code.

[1]: It's not necessary to reconstruct the entire space behind the object, only the space that may be visible as the virtual camera moves.  This will be dependent on the constraints imposed on the virtual camera (See maximumViewingAngleX and maximumViewingAngleY in PerspectiveMotionEffect.h).
[2]: The depth value will likely have no relation to the distance from the object(s) in that layer to the camera in the original scene.  It is selected so that the final effect is aesthetically pleasing.


================================================================================
BUILD REQUIREMENTS:

iOS 7.0 SDK or later
 

================================================================================
RUNTIME REQUIREMENTS:

iOS 7.0 or later


================================================================================
PACKAGING LIST:

AppDelegate.{h/m}
    - The application's delegate.

BasicInterpolationVC.{h/m}
    - View controller that applies interpolation motion effects to the position of it's subviews.  A basic parallax effect is created in which a view in the foreground appears to float above a recessed background. Demonstrates UIInterpolatingMotionEffect and UIMotionEffectGroup.
    
ParallaxBlurVC.{h/m}
    - Demonstrates how to create a dynamic blur underneath a view with motion effects applied that overlies a static background.
    
CustomMotionEffectVC.{h/m}
    - Demonstrates using a custom motion effect to bring a specially-prepared image to life by allowing the viewer to look behind objects in the foreground as they rotate the device.

PerspectiveMotionEffect.{h/m}
    - Subclass of UIMotionEffect that simulates a camera which orbits around a specific point of interest as the reported viewer offset changes.


================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.0 
- Demonstrates UIKit motion effects.


================================================================================
Copyright (C) 2013-2014 Apple Inc. All rights reserved.