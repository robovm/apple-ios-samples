/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
      View for Deferred lighting Metal Sample Code. Manages the main render pass descriptors and expects a delegate to repond to render commands to perform drawing. Can be configured with 4 color attachments, depth and stencil attachments.
      
*/

#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <UIKit/UIKit.h>

@protocol AAPLViewDelegate;

@interface AAPLView : UIView
{
    @public
    
    /*  set these pixel formats to have the main drawable render descriptor get created with color[0-3] depth and/or stencil attachments.
        colorAttachment0Format is the attachment that will get presented to screen.
        clear color and load store settings for each attachment.
        load actions default to MTLLoadActionClear if clear color is set, otherwise dont care.
        store actions default to MTLStoreActionStore for main drawable texture (color attachment0), otherwise the rest are MTLStoreActionDontCare.
     */
    MTLPixelFormat colorAttachmentFormat[4];
    MTLClearColor colorAttachmentClearValue[4];
    MTLPixelFormat depthPixelFormat;
    double depthAttachmentClearValue;
    MTLPixelFormat stencilPixelFormat;
    uint32_t stencilAttachmentClearValue;
}

@property (nonatomic, weak) IBOutlet id <AAPLViewDelegate> delegate;

// view has a handle to the metal device when created
@property (nonatomic, readonly) id <MTLDevice> device;

// the current drawable created within the view's CAMetalLayer
@property (nonatomic, readonly) id <CAMetalDrawable> currentDrawable;

// This call may block until the drawable is available.
@property (nonatomic, readonly) MTLRenderPassDescriptor *renderPassDescriptor;

// view controller will be call off the main thread
- (void)display;

// release any uneeded color/depth/stencil resources. view controller will call when paused.
- (void)releaseTextures;

@end

// rendering delegate (App must implement a rendering delegate that responds to these messages
@protocol AAPLViewDelegate <NSObject>
@required
// delegate should perform all rendering here
- (void)render:(AAPLView *)view;

@optional
// called if the view changes orientation or size, renderer can precompute its view and projection matricies here for example
- (void)reshape:(AAPLView *)view;

@end
