/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller that manages an AAPLSceneView instance for displaying the game.
  
 */

#import "AAPLViewController.h"

@implementation AAPLViewController

- (AAPLSceneView *)sceneView
{
	return (id)self.view;
}

- (void)loadView
{
	self.view = [[AAPLSceneView alloc] init];
}

@end
