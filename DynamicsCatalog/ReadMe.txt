### UIKit Dynamics Catalog ###

================================================================================
DESCRIPTION:

This sample code project illustrates a number of uses of UIKit Dynamics, the iOS API that provides physics-related capabilities and animations to views and other dynamic items. A dynamic item is any iOS or custom object that conforms to the UIDynamicItem protocol.

Each of the 10 view controllers in this project shows a different way to use UIKit Dynamics—-in many cases, combining dynamic behaviors for interesting results. See the Packaging List section in this ReadMe for specific descriptions.

When learning about UIKit Dynamics, start by reading UIDynamicAnimator Class Reference and UIDynamicItem Protocol Reference. Every use of UIKit Dynamics employs these APIs.

There are two WWDC 2013 sessions on UIKit Dynamics:

Getting Started with UIKit Dynamics
<https://developer.apple.com/wwdc/videos/?id=206>

Advanced Techniques with UIKit Dynamics
<https://developer.apple.com/wwdc/videos/?id=221>


================================================================================
BUILD REQUIREMENTS:

iOS 7.0 SDK or later
 
================================================================================
RUNTIME REQUIREMENTS:

iOS 7.0 or later

================================================================================
PACKAGING LIST:

View Controllers and Supporting Classes
--------------------------------------------------------------------------------

APLGravityViewController.{h/m}
    - Provides the "Gravity" demonstration. The dynamic item in this scene is the square view, which is associated with an instance of the UIGravityBehavior class. This association subjects the view to UIKit gravity. Because there is no collision behavior added to the dynamic animator, the dynamic item continues moving beyond the bottom edge of the screen. If you want to replay the demo, return to the main view in the app and again tap on the Gravity row.

    See
        UIGravityBehavior Class Reference


APLCollisionGravityViewController.{h/m}
    - Provides the "Collision + Gravity" demonstration. The dynamic item (square view) collides with the bottom edge of its parent view; both of these items are associated with a single instance of the UICollisionBehavior class, enabling them to participate in collisions together. The dynamic item has a default amount of elasticity, enabling a small bounce effect upon collision.

    See
        UICollisionBehavior Class Reference
        UIGravityBehavior Class Reference


APLAttachmentsViewController.{h/m}
    - Provides the "Attachments + Collision" demonstration. The square view in this demonstration is associated, using a rigid (default) attachment behavior, with an anchor point. The anchor point, in turn, tracks onscreen gestures. As you move the anchor point by dragging onscreen, the dynamic item moves in response. Because the attachment point in the dynamic item is configured to be offset from the item's center, the forces involved when moving the anchor point result in rotation as well as translation of the dynamic item.

    See
        UIAttachmentBehavior Class Reference


APLCollisionsGravitySpringViewController.{h/m}
    - Provides the "Collisions + Gravity + Spring" demonstration, which extends the “Attachments + Collision” demonstration by adding two elements: a spring-like effect to the attachment behavior, and gravity. By default, an attachment behavior is rigid; to add springiness, set values for its frequency and damping properties.

    See
        UIAttachmentBehavior Class Reference
        UICollisionBehavior Class Reference
        UIGravityBehavior Class Reference


APLSnapViewController.{h/m}
    - Provides the "Snap" demonstration. The dynamic item in this demonstration moves quickly to the spot on the screen that you tap. When the center of the item reaches the spot, the item oscillates briefly according to the default value in a snap behavior's damping property.

    See
        UISnapBehavior Class Reference


APLInstantaneousPushViewController.{h/m}
APLContinuousPushViewController.{h/m}
   - These classes provide two companion demonstrations, "Instantaneous Push + Collision" and "Continuous Push + Collision." In each demo, you define a push vector by tapping a spot on the screen relative to the small cross at the screen center. The demo briefly represents the new push vector as a red arrow, showing direction and magnitude. 

   * In the Instantaneous Push demo, the push behavior's mode property is configured using the UIPushBehaviorModeInstantaneous constant. After you tap the screen, the dynamic item receives an impulse, causing it to quickly reach a constant speed.

   * In the Continuous Push demo, the push behavior's mode property is configured using the UIPushBehaviorModeContinuous constant. After you tap the screen, the dynamic item is subject to a continuous force, causing it to accelerate.

    See
        UICollisionBehavior Class Reference
        UIPushBehavior Class Reference


APLCompositeBehaviorViewController.{h/m}
APLPendulumBehavior.{h/m}
    - Together, these provide the "Pendulum (Composite Behavior)" demonstration. You see how to create a new, composite behavior by combining primitive iOS behaviors. In this case, a gravity behavior and an attachment behavior combine to make the single, composite pendulum behavior.

    See
        UIAttachmentBehavior Class Reference
        UIGravityBehavior Class Reference

    
APLItemPropertiesViewController.{h/m}
    - Provides the "Item Properties" demonstration. By using the UIDynamicItemBehavior class, you can override some inherent properties of a dynamic item, such as its elasticity. This demo shows two dynamic items subject to the same gravity and the same collision boundary, but each with its own elasticity. 

    This demo also shows how to reset the states of dynamic items to replay an animation from the start.

    See
        UICollisionBehavior Class Reference
        UIDynamicItemBehavior Class Reference
        UIGravityBehavior Class Reference


APLCustomDynamicItemViewController.{h/m}
APLPositionToBoundsMapping.{h/m}
    - Together, these provide the "Custom Dynamic Item" demonstration, which shows how to employ UIKit Dynamics to animate a property that cannot normally be animated by UIKit Dynamics. 

    The APLPositionToBoundsMapping class adopts and extends the UIDynamicItem protocol. It provides a proxy object that remaps the UIKit Dynamics "center" animation as a "bounds" animation. 
    
    See
        UIAttachmentBehavior Class Reference
        UIDynamicItem Protocol Reference
        UIPushBehavior Class Reference


Accessory Classes
--------------------------------------------------------------------------------
    
APLDecorationView.{h/m}
    - Provides the visual ornamentation (arrows representing force vectors, and dashed lines representing attachments) for all the demonstrations. You do not need to understand the code in this this class to understand the concepts presented in this sample code project.

================================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.3
- First public release.
- Added additional UIKit Dynamics demonstrations and enhanced the UI.
- Expanded the ReadMe file to introduce each demonstration.

Version 1.2
- Corrected missing outlet connections. 
- Updated the ReadMe to indicate known issues.

Version 1.1
- Added comments and minor improvements.

Version 1.0 
- Illustrates use of UIKit Dynamics.

================================================================================
Copyright (C) 2013 Apple Inc. All rights reserved.
