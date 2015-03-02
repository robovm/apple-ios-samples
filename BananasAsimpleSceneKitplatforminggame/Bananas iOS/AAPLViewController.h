/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  A view controller that manages an AAPLSceneView instance for displaying the game.
  
 */

#import <UIKit/UIKit.h>
#import "AAPLSceneView.h"

@interface AAPLViewController : UIViewController

@property (nonatomic, readonly) AAPLSceneView *sceneView;

@end
