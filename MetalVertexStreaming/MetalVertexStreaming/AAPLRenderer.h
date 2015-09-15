/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Metal Renderer for Metal Vertex Streaming sample. Acts as the update and render delegate for the view controller and performs rendering. Renders a simple basic triangle with and updates the vertices every frame using a shared CPU/GPU memory buffer.
 */

#import "AAPLView.h"
#import "AAPLViewController.h"

#import <Metal/Metal.h>

@interface AAPLRenderer : NSObject <AAPLViewDelegate>

// load all assets before triggering rendering
- (void)configure:(AAPLView *)view;

@end
