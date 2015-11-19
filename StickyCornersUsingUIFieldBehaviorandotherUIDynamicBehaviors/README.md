# StickyCorners: Using UIFieldBehavior and Other UIDynamicBehaviors

StickyCorners showcases the usage of UIFieldBehavior using UIKit Dynamics.

The application positions a red box in one of the screen corners. The box can be manipulated by panning with a finger. Additionally, the box can be thrown towards different corners with momentum gained during panning. The box also collides with the edges of the screen.

## StickyCornersBehavior

StickyCornersBehavior is a compound UIDynamicBehavior subclass made up of the following child behaviors

* UICollisionBehavior - Used for collision with the edges to keep the box on screen
* UIDynamicItemBehavior - Used to alter the dynamic properties of the red box
* UIFieldBehavior - There are 4 spring fields, one for each quadrant of the reference view. Each has an origin point offset from the respective corner. Each field's region has been confined to the assigned quadrant.

## StickyCornersViewController

StickyCornersViewController is a UIViewController subclass demonstrating the usage of StickyCornersBehavior. It sets up a view for the red box, creates the StickyCornersBehavior, and creates a UIDynamicAnimator to control the animation. This view controller also handled interaction with the UIPanGestureRecognizer for manipulation of the red box. 

StickyCornersViewController also handled transitions in reference view size, for example during rotation.

## Debugging

A Bridging header has been created to expose UIDynamicAnimator's private debug interface in Swift. This can be enabled by a long press on the application background (the white view). This is private interface only intended for debugging UIKit Dynamics interactions.

## Requirements

### Build

Xcode 7.0, iOS 9.0 SDK

### Runtime

iOS 9.0 

Copyright (C) 2015 Apple Inc. All rights reserved.
