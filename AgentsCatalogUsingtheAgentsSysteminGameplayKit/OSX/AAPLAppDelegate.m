/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	OS X application delegate. Handles switching demo scenes based on UI controls.
 */

#import "AAPLAppDelegate.h"

#import "AAPLGameScene.h"

@implementation AAPLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    self.window.titleVisibility = NSWindowTitleHidden;
	
	// Configure the view.
    self.skView.ignoresSiblingOrder = YES;
    self.skView.showsFPS = YES;
    self.skView.showsNodeCount = YES;
	
	// Present the scene.
	[self selectScene:self.sceneControl];
}

- (IBAction)selectScene:(NSSegmentedControl *)sender {
	AAPLGameScene *scene = [AAPLGameScene sceneWithType:sender.selectedSegment size:CGSizeMake(800, 600)];
	
    scene.scaleMode = SKSceneScaleModeAspectFit;

    [self.skView presentScene:scene];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
