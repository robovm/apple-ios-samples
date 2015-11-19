/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A renderer class for visualizing 2 rotating 3d cubes bounded to
  a plasma shader.
 */

#import "AAPLView.h"
#import "AAPLViewController.h"

@interface AAPLRenderer : NSObject <AAPLViewControllerDelegate, AAPLViewDelegate>

// renderer will create a default device at init time.
@property (nonatomic, readonly) id <MTLDevice> device;

// this value will cycle from 0 to g_max_inflight_buffers whenever a display completes ensuring renderer clients
// can synchronize between g_max_inflight_buffers count buffers, and thus avoiding a constant buffer from being overwritten between draws
@property (nonatomic, readonly) NSUInteger constantDataBufferIndex;

// These queries exist so the View can initialize a framebuffer that
// matches the expectations of the renderer
@property (nonatomic, readonly) MTLPixelFormat depthPixelFormat;
@property (nonatomic, readonly) MTLPixelFormat stencilPixelFormat;
@property (nonatomic, readonly) NSUInteger     sampleCount;

// load all assets before triggering rendering
- (void) configure:(AAPLView *)view;

- (void)cleanup;

@end
