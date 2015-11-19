/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	OS X application delegate. Handles switching demo scenes based on UI controls.
 */

@import SpriteKit;

@interface AAPLAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet SKView *skView;
@property (weak) IBOutlet NSSegmentedControl *sceneControl;

@end
