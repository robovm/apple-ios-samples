/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Game View Controller declaration.
 */

#if TARGET_OS_IPHONE
@import UIKit;
@interface AAPLGameViewController : UIViewController <SCNSceneRendererDelegate, SCNPhysicsContactDelegate>
#else
@interface AAPLGameViewController : NSViewController <SCNSceneRendererDelegate, SCNPhysicsContactDelegate>
#endif

- (void)handleTapAtPoint:(CGPoint)p;
- (void)handleDoubleTapAtPoint:(CGPoint)p;
- (void)handlePanAtPoint:(CGPoint)p;
- (void)gestureDidEnd;
- (void)gestureDidBegin;

- (void)tiltCameraWithOffset:(CGPoint)offset;

@end
