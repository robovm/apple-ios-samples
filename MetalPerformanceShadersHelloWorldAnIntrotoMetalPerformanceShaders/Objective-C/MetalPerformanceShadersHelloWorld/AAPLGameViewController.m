/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    Contains the applications main view controller, AAPLGameViewController.
*/

#import "AAPLGameViewController.h"

@import Metal;
@import simd;
@import ModelIO;
@import MetalPerformanceShaders;

@interface AAPLGameViewController ()

#pragma mark - Properties

// View.
@property (nonatomic, strong) MTKView *metalView;

// Metal.
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

// Source Texture.
@property (nonatomic, strong) id<MTLTexture> sourceTexture;

// Label telling the user their device isn't supported by MetalPerformanceShaders.
@property (strong, nonatomic) IBOutlet UILabel *metalPerformanceShadersDisabledLabel;

@end

@implementation AAPLGameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.metalView = (MTKView *)self.view;
    
    // Set the view to use the default device.
    self.metalView.device = MTLCreateSystemDefaultDevice();
    
    // Make sure the current device supports MetalPerformanceShaders.
    if (!MPSSupportsMTLDevice(self.metalView.device)) {
        return;
    }
    
    // Hide the label telling the user their device isn't supported by MetalPerformanceShaders.
    self.metalPerformanceShadersDisabledLabel.hidden = YES;

    // Set up the view, pixel format, color format, access to render.
    [self setupView];
    
    // Set up Metal, device, and command queue.
    [self setupMetal];
    
    // Access to source texture and load to a variable.
    [self loadAssets];
}

- (void)setupMetal {
    
    // Create a new command queue.
    self.commandQueue = [self.metalView.device newCommandQueue];
}

- (void)setupView {
    self.metalView.delegate = self;
    
    // Setup the render target, choose values based on your app.
    self.metalView.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    
    // Set up pixel format as your input/output texture.
    self.metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    
    // Allow to access to currentDrawable.texture write mode.
    self.metalView.framebufferOnly = false;
}

- (void)loadAssets {
    // Load source texture.
    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:self.metalView.device];

    NSBundle *mainBundle = [NSBundle mainBundle];

    NSURL *url = [mainBundle URLForResource:@"AnimalImage" withExtension:@"png"];

    self.sourceTexture = [textureLoader newTextureWithContentsOfURL:url options:nil error:nil];
}

- (void)render {
    // Create a new command buffer for each renderpass to the current drawable.
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    // Initialize MetalPerformanceShaders gaussianBlur with Sigma = 10.0f.
    MPSImageGaussianBlur *gaussianblur = [[MPSImageGaussianBlur alloc] initWithDevice:self.metalView.device sigma:10.0f];
    
    // Run MetalPerformanceShader gaussianblur
    [gaussianblur encodeToCommandBuffer:commandBuffer
                          sourceTexture:self.sourceTexture
                     destinationTexture:self.metalView.currentDrawable.texture];
    
    // Schedule a present using the current drawable.
    [commandBuffer presentDrawable:self.metalView.currentDrawable];
    
    // Finalize command buffer.
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

#pragma mark - MTKViewDelegate

// Called whenever view changes orientation or layout is changed.
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}

// Called whenever the view needs to render.
- (void)drawInMTKView:(nonnull MTKView *)view {
    @autoreleasepool {
        [self render];
    }
}

@end