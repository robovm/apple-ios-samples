/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
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
    
    // this value will cycle from 0 to g_max_inflight_buffers whenever a display completes ensuring renderer clients
    // can synchronize between g_max_inflight_buffers count buffers, and thus avoiding a constant buffer from being overwritten between draws
    NSUInteger _constantDataBufferIndex;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _constantDataBufferIndex = 0;
        _inflight_semaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
    }
    return self;
}

#pragma mark RENDER VIEW DELEGATE METHODS

- (void)configure:(AAPLView *)view
{
    // find a usable Device
    _device = view.device;
    
    // setup view with drawable formats
    view.depthPixelFormat   = MTLPixelFormatInvalid;
    view.stencilPixelFormat = MTLPixelFormatInvalid;
    view.sampleCount        = 1;
    
    // create a new command queue
    _commandQueue = [_device newCommandQueue];
    
    _defaultLibrary = [_device newDefaultLibrary];
    if(!_defaultLibrary) {
        NSLog(@">> ERROR: Couldnt create a default shader library");
        // assert here becuase if the shader libary isn't loading, nothing good will happen
        assert(0);
    }
    
    if (![self preparePipelineState:view])
    {
        NSLog(@">> ERROR: Couldnt create a valid pipeline state");
        
        // cannot render anything without a valid compiled pipeline state object.
        assert(0);
    }
    
    // set the vertex shader and buffers defined in the shader source, in this case we have 2 inputs. A position buffer and a color buffer
    // Allocate a buffer to store vertex position data (we'll quad buffer this one)
    _vertexBuffer = [_device newBufferWithLength:kMaxBufferBytesPerFrame options:0];
    _vertexBuffer.label = @"Vertices";
    
    // Single static buffer for color information
    _vertexColorBuffer = [_device newBufferWithBytes: vertexColorData length: sizeof(vertexColorData) options:0];
    _vertexBuffer.label = @"colors";
}

- (BOOL)preparePipelineState:(AAPLView*)view
{
    // load the vertex program into the library
    id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:@"passThroughVertex"];
    
    // load the fragment program into the library
    id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:@"passThroughFragment"];

    //  create a reusable pipeline state
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineStateDescriptor.label = @"MyPipeline";
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineStateDescriptor.sampleCount      = view.sampleCount;
    pipelineStateDescriptor.vertexFunction   = vertexProgram;
    pipelineStateDescriptor.fragmentFunction = fragmentProgram;
    
    NSError *error = nil;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                             error:&error];
    if(!_pipelineState) {
        NSLog(@">> ERROR: Failed Aquiring pipeline state: %@", error);
        return NO;
    }
    
    return YES;
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
    // Allow the renderer to preflight 3 frames on the CPU (using a semapore as a guard) and commit them to the GPU.
    // This semaphore will get signaled once the GPU completes a frame's work via addCompletedHandler callback below,
    // signifying the CPU can go ahead and prepare another frame.
    dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    
    [self updateVertexBuffer];
    
    // create a new command buffer for each renderpass to the current drawable
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // create a render command encoder so we can render into something
    MTLRenderPassDescriptor *renderPassDescriptor = view.renderPassDescriptor;
    if (renderPassDescriptor)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        [self _renderTriangle:renderEncoder view:view name:@"Triangle"];
        
        [renderEncoder endEncoding];

        // schedule a present once the framebuffer is complete
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    // call the view's completion handler which is required by the view since it will signal its semaphore and set up the next buffer
    __block dispatch_semaphore_t block_sema = _inflight_semaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        
        // GPU has completed rendering the frame and is done using the contents of any buffers previously encoded on the CPU for that frame.
        // Signal the semaphore and allow the CPU to proceed and construct the next frame.
        dispatch_semaphore_signal(block_sema);
    }];
    
    // finalize rendering here. this will push the command buffer to the GPU
    [commandBuffer commit];
    
    // This index represents the current portion of the ring buffer being used for a given frame's constant buffer updates.
    // Once the CPU has completed updating a shared CPU/GPU memory buffer region for a frame, this index should be updated so the
    // next portion of the ring buffer can be written by the CPU. Note, this should only be done *after* all writes to any
    // buffers requiring synchronization for a given frame is done in order to avoid writing a region of the ring buffer that the GPU may be reading.
    _constantDataBufferIndex = (_constantDataBufferIndex + 1) % kInFlightCommandBuffers;
}

- (void) updateVertexBuffer
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

- (void)reshape:(AAPLView *)view
{
    // unused in this sample
}

@end
