/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Metal Renderer for MetalVideoCapture sample. Uses AVFoundation video capture APIs to grab video data and CVMetalTextureCache APIs to convert video frames to textures usable within a Metal render pass. A video frame is returned via an AVCapture API Callback which must be synchronized with the Metal renderer (in this case on the main queue). The renderer renders two objects (with two seperate programs). The first is the skybox and the second is a quad with the video texture, a skybox based environment map reflection and a mipmaped pvrtc texture.
 */

#import "AAPLView.h"
#import "AAPLViewController.h"

#import <Metal/Metal.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>
#import <Accelerate/Accelerate.h>

@interface AAPLRenderer : NSObject <AAPLViewControllerDelegate, AAPLViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

// load all assets before triggering rendering
- (void)configure:(AAPLView *)view;

@end
