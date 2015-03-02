/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Metal Renderer for MetalInstancedHelix. Acts as the update and render delegate for the view controller and performs rendering. In MetalInstancedHelix, the renderer draws N cubes, whos color values change every update.
 */

#import "AAPLView.h"
#import "AAPLViewController.h"

#import <Metal/Metal.h>

@interface AAPLRenderer : NSObject <AAPLViewControllerDelegate, AAPLViewDelegate>

// load all assets before triggering rendering
- (void)configure:(AAPLView *)view;

@end
