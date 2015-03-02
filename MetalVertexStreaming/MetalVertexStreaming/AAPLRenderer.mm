/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Metal Renderer for Metal Vertex Streaming sample. Acts as the update and render delegate for the view controller and performs rendering. Renders a simple basic triangle with and updates the vertices every frame using a shared CPU/GPU memory buffer.
  
 */

#import "AAPLRenderer.h"
#import "AAPLViewController.h"
#import "AAPLView.h"

#import <simd/simd.h>

static const long kMaxBufferBytesPerFrame = 1024*1024;
static const long kInFlightCommandBuffers = 3;

static const simd::float4 vertexData[] = {
    { -1.0f, -1.0f, 0.0f, 1.0f,  },
    { -1.0f,  1.0f, 0.0f, 1.0f,  },
    {  1.0f, -1.0f, 0.0f, 1.0f,  },
    
    {  1.0f, -1.0f, 0.0f, 1.0f,  },
    { -1.0f,  1.0f, 0.0f, 1.0f,  },
    {  1.0f,  1.0f, 0.0f, 1.0f,  },
    
    { -0.0f, 0.25f, 0.0f, 1.0f   },    
    { -0.25f, -0.25f, 0.0f, 1.0f },
    { 0.25f, -0.25f, 0.0f, 1.0f  },
};

static const simd::float4 vertexColorData[] = {
    { 0.0f, 0.0f, 1.0f, 1.0f },
    { 0.0f, 0.0f, 1.0f, 1.0f },
    { 0.0f, 0.0f, 1.0f, 1.0f },
    
    { 0.0f, 0.0f, 1.0f, 1.0f },
    { 0.0f, 0.0f, 1.0f, 1.0f },
    { 0.0f, 0.0f, 1.0f, 1.0f },
    
    { 0.0f, 0.0f, 1.0f, 1.0f },
    { 0.0f, 1.0f, 0.0f, 1.0f },
    { 1.0f, 0.0f, 0.0f, 1.0f },
};

// Current animated triangle offsets.
simd::float3 xOffset = { -1.0f, 1.0f, -1.0f };
simd::float3 yOffset = {  1.0f, 0.0f, -1.0f };

// Current vertex deltas
simd::float3 xDelta = { 0.002, -0.001, 0.003 };
simd::float3 yDelta = { 0.001,  0.002, -0.001 };

@implementation AAPLRenderer
{
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;
    id <MTLLibrary> _defaultLibrary;
    
    dispatch_semaphore_t _inflight_semaphore;
    
    // render stage
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLBuffer> _vertexBuffer;
    id <MTLBuffer> _vertexColorBuffer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _sampleCount = 4;
        _depthPixelFormat = MTLPixelFormatInvalid;
        _stencilPixelFormat = MTLPixelFormatInvalid;
        
        // find a usable Device
        _device = MTLCreateSystemDefaultDevice();
        
        // create a new command queue
        _commandQueue = [_device newCommandQueue];
        
        _defaultLibrary = [_device newDefaultLibrary];
        
        if(!_defaultLibrary)
        {
            NSLog(@">> ERROR: Couldnt create a default shader library");
            
            // assert here becuase if the shader libary isnt loading, its good place to debug why shaders arent compiling
            assert(0);
        }
        
        _constantDataBufferIndex = 0;
        _inflight_semaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
    }
    return self;
}

#pragma mark RENDER VIEW DELEGATE METHODS

- (void)configure:(AAPLView *)view
{
    view.depthPixelFormat   = _depthPixelFormat;
    view.stencilPixelFormat = _stencilPixelFormat;
    view.sampleCount        = _sampleCount;
    
    // load the vertex program into the library
    id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:@"passThroughVertex"];
    
    if(!vertexProgram)
    {
        NSLog(@">> ERROR: Couldnt load vertex function from default library");
    }
    
    // load the fragment program into the library
    id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:@"passThroughFragment"];
    
    if(!fragmentProgram)
    {
        NSLog(@">> ERROR: Couldnt load fragment function from default library");
    }
    
    // set the vertex shader and buffers defined in the shader source, in this case we have 2 inputs. A position buffer and a color buffer
    // Allocate a buffer to store vertex position data (we'll quad buffer this one)
    _vertexBuffer = [_device newBufferWithLength:kMaxBufferBytesPerFrame
                                         options:0];
    
    _vertexBuffer.label = @"Vertices";
    
    // Single static buffer for color information
    _vertexColorBuffer = [_device newBufferWithBytes: vertexColorData
                                              length: sizeof(vertexColorData)
                                             options:0];
    
    _vertexBuffer.label = @"colors";
    
    //  create a reusable pipeline state
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
    
    pipelineStateDescriptor.label = @"MyPipeline";
    
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    pipelineStateDescriptor.sampleCount      = _sampleCount;
    pipelineStateDescriptor.vertexFunction   = vertexProgram;
    pipelineStateDescriptor.fragmentFunction = fragmentProgram;
    
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                             error:nil];
}

- (void)_renderTriangle:(id <MTLRenderCommandEncoder>)renderEncoder
                   view:(AAPLView *)view
                   name:(NSString *)name
{
    [renderEncoder pushDebugGroup:name];
    
    //  set context state
    [renderEncoder setRenderPipelineState:_pipelineState];
    
    [renderEncoder setVertexBuffer:_vertexBuffer
                            offset:256*_constantDataBufferIndex
                           atIndex:0 ];
    
    [renderEncoder setVertexBuffer:_vertexColorBuffer
                            offset:0
                           atIndex:1 ];
    
    // tell the render context we want to draw our primitives
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:9 instanceCount:1];
    
    [renderEncoder popDebugGroup];
}

- (void)render:(AAPLView *)view
{
    dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    
    // create a new command buffer for each renderpass to the current drawable
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // create a render command encoder so we can render into something
    MTLRenderPassDescriptor *renderPassDescriptor = view.renderPassDescriptor;
    if (renderPassDescriptor)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        [self _renderTriangle:renderEncoder view:view name:@"Triangle"];
        
        [renderEncoder endEncoding];
        
        // call the view's completion handler which is required by the view since it will signal its semaphore and set up the next buffer
        __block dispatch_semaphore_t block_sema = _inflight_semaphore;
        
        [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
            dispatch_semaphore_signal(block_sema);
        }];
        
        // schedule a present once the framebuffer is complete
        [commandBuffer presentDrawable:view.currentDrawable];
        
        // finalize rendering here. this will push the command buffer to the GPU
        [commandBuffer commit];
    }
    else
    {
        // release the semaphore to keep things synchronized even if we couldnt render
        dispatch_semaphore_signal(_inflight_semaphore);
    }
        
    // the renderview assumes it can now increment the buffer index and that the previous index wont be touched
    // until we cycle back around to the same index
    _constantDataBufferIndex = (_constantDataBufferIndex + 1) % kInFlightCommandBuffers;
}

- (void)reshape:(AAPLView *)view
{
    // unused in this sample
}

#pragma mark VIEW CONTROLLER DELEGATE METHODS

- (void)update:(AAPLViewController *)controller
{
    simd::float4 *vData = (simd::float4 *)((uintptr_t)[_vertexBuffer contents] + 256*_constantDataBufferIndex);
    
    // reset the vertex data in the shared cpu/gpu buffer each frame and just accumulate offsets below
    memcpy(vData,vertexData,sizeof(vertexData));
    
    // Animate triangle offsets
    int j;
    
    for(j = 0; j < 3; j++)
    {
        xOffset[j] += xDelta[j];
        
        if(xOffset[j] >= 1.0 || xOffset[j] <= -1.0)
        {
            xDelta[j] = -xDelta[j];
            xOffset[j] += xDelta[j];
        }
        
        yOffset[j] += yDelta[j];
        
        if(yOffset[j] >= 1.0 || yOffset[j] <= -1.0)
        {
            yDelta[j] = -yDelta[j];
            yOffset[j] += yDelta[j];
        }
        
        // Update last triangle position directly in the shared cpu/gpu buffer
        vData[6+j].x = xOffset[j];
        vData[6+j].y = yOffset[j];
    }
}

- (void)viewController:(AAPLViewController *)controller willPause:(BOOL)pause
{
    // timer is suspended/resumed
    // Can do any non-rendering related background work here when suspended
}


@end
