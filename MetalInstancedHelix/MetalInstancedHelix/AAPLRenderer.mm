/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Metal Renderer for MetalInstancedHelix. Acts as the update and render delegate for the view controller and performs rendering. In MetalInstancedHelix, the renderer draws N cubes, whos color values change every update.
 */

#import "AAPLRenderer.h"
#import "AAPLViewController.h"
#import "AAPLView.h"
#import "AAPLTransforms.h"
#import "AAPLSharedTypes.h"

using namespace AAPL;
using namespace simd;

static const long kInFlightCommandBuffers = 3;

static const NSUInteger kNumberOfBoxes = 250;
static const float4 kBoxAmbientColors[2] = {
    {0.18, 0.24, 0.8, 1.0},
    {0.8, 0.24, 0.1, 1.0}
};

static const float4 kBoxDiffuseColors[2] = {
    {0.4, 0.4, 1.0, 1.0},
    {0.8, 0.4, 0.4, 1.0}
};

static const float kRadius  = 5.0f;
static const float kTheta   = 180.0f;
static const float kPhi     = 360.0f;

static const float kFOVY    = 65.0f;
static const float3 kEye    = {0.0f, 0.0f, 0.0f};
static const float3 kCenter = {0.0f, 0.0f, 1.0f};
static const float3 kUp     = {0.0f, 1.0f, 0.0f};

static const float kWidth  = 0.05f;
static const float kHeight = 0.05f;
static const float kDepth  = 0.05f;

static const float kCubeVertexData[] =
{
    kWidth, -kHeight, kDepth,   0.0, -1.0,  0.0,  
    -kWidth, -kHeight, kDepth,   0.0, -1.0, 0.0,  
    -kWidth, -kHeight, -kDepth,   0.0, -1.0,  0.0,
    kWidth, -kHeight, -kDepth,  0.0, -1.0,  0.0,  
    kWidth, -kHeight, kDepth,   0.0, -1.0,  0.0,  
    -kWidth, -kHeight, -kDepth,   0.0, -1.0,  0.0,
    
    kWidth, kHeight, kDepth,    1.0, 0.0,  0.0,
    kWidth, -kHeight, kDepth,   1.0,  0.0,  0.0,  
    kWidth, -kHeight, -kDepth,  1.0,  0.0,  0.0,  
    kWidth, kHeight, -kDepth,   1.0, 0.0,  0.0,
    kWidth, kHeight, kDepth,    1.0, 0.0,  0.0,
    kWidth, -kHeight, -kDepth,  1.0,  0.0,  0.0,  
    
    -kWidth, kHeight, kDepth,    0.0, 1.0,  0.0,
    kWidth, kHeight, kDepth,    0.0, 1.0,  0.0,
    kWidth, kHeight, -kDepth,   0.0, 1.0,  0.0,
    -kWidth, kHeight, -kDepth,   0.0, 1.0,  0.0,  
    -kWidth, kHeight, kDepth,    0.0, 1.0,  0.0,
    kWidth, kHeight, -kDepth,   0.0, 1.0,  0.0,
    
    -kWidth, -kHeight, kDepth,  -1.0,  0.0, 0.0,  
    -kWidth, kHeight, kDepth,   -1.0, 0.0,  0.0,
    -kWidth, kHeight, -kDepth,  -1.0, 0.0,  0.0,  
    -kWidth, -kHeight, -kDepth,  -1.0,  0.0,  0.0,
    -kWidth, -kHeight, kDepth,  -1.0,  0.0, 0.0,  
    -kWidth, kHeight, -kDepth,  -1.0, 0.0,  0.0,
    
    kWidth, kHeight,  kDepth,  0.0, 0.0,  1.0,    
    -kWidth, kHeight,  kDepth,  0.0, 0.0,  1.0,   
    -kWidth, -kHeight, kDepth,   0.0,  0.0, 1.0,  
    -kWidth, -kHeight, kDepth,   0.0,  0.0, 1.0,  
    kWidth, -kHeight, kDepth,   0.0,  0.0,  1.0,  
    kWidth, kHeight,  kDepth,  0.0, 0.0,  1.0,    
    
    kWidth, -kHeight, -kDepth,  0.0,  0.0, -1.0,  
    -kWidth, -kHeight, -kDepth,   0.0,  0.0, -1.0,
    -kWidth, kHeight, -kDepth,  0.0, 0.0, -1.0,   
    kWidth, kHeight, -kDepth,  0.0, 0.0, -1.0,    
    kWidth, -kHeight, -kDepth,  0.0,  0.0, -1.0,  
    -kWidth, kHeight, -kDepth,  0.0, 0.0, -1.0   
};

@implementation AAPLRenderer
{
    // constant synchronization for buffering <kInFlightCommandBuffers> frames
    dispatch_semaphore_t _inflight_semaphore;
    id <MTLBuffer> _dynamicConstantBuffer[kInFlightCommandBuffers];
    
    // renderer global ivars
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;
    id <MTLLibrary> _defaultLibrary;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLBuffer> _vertexBuffer;
    id <MTLDepthStencilState> _depthState;
    
    // globals used in update calculation
    float4x4 _projectionMatrix;
    float4x4 _viewMatrix;
    float4x4 _baseModelMatrix[kNumberOfBoxes];
    float _rotation;
    
    long _maxBufferBytesPerFrame;
    size_t _sizeOfConstantT;
    
    // this value will cycle from 0 to g_max_inflight_buffers whenever a display completes ensuring renderer clients
    // can synchronize between g_max_inflight_buffers count buffers, and thus avoiding a constant buffer from being overwritten between draws
    NSUInteger _constantDataBufferIndex;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _sizeOfConstantT = sizeof(constants_t);
        _maxBufferBytesPerFrame = _sizeOfConstantT*kNumberOfBoxes;
        _constantDataBufferIndex = 0;
        _inflight_semaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
    }
    return self;
}

#pragma mark Configure

- (void)configure:(AAPLView *)view
{
    // assign device created by the view
    _device = view.device;
    
    // setup view with drawable formats
    view.depthPixelFormat   = MTLPixelFormatDepth32Float;
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
    
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    
    // allocate a number of buffers in memory that matches the sempahore count so that
    // we always have one self contained memory buffer for each buffered frame.
    // In this case triple buffering is the optimal way to go so we cycle through 3 memory buffers
    for (int i = 0; i < kInFlightCommandBuffers; i++)
    {
        _dynamicConstantBuffer[i] = [_device newBufferWithLength:_maxBufferBytesPerFrame options:0];
        _dynamicConstantBuffer[i].label = [NSString stringWithFormat:@"ConstantBuffer%i", i];
        
        // write initial color values for both cubes (at each offset).
        // Note, these will get animated during update
        constants_t *constant_buffer = (constants_t *)[_dynamicConstantBuffer[i] contents];
        for (int j = 0; j < kNumberOfBoxes; j++)
        {
            if (j%2==0) {
                constant_buffer[j].multiplier = 1;
                constant_buffer[j].ambient_color = kBoxAmbientColors[0];
                constant_buffer[j].diffuse_color = kBoxDiffuseColors[0];
            }
            else {
                constant_buffer[j].multiplier = -1;
                constant_buffer[j].ambient_color = kBoxAmbientColors[1];
                constant_buffer[j].diffuse_color = kBoxDiffuseColors[1];
            }
        }
    }
    
    // preload initial transformation data once the constant buffers are setup
    [self prepareTransforms];
    
}

- (BOOL)preparePipelineState:(AAPLView *)view
{
    // get the fragment function from the library
    id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:@"lighting_fragment"];
    if(!fragmentProgram)
        NSLog(@">> ERROR: Couldn't load fragment function from default library");
    
    // get the vertex function from the library
    id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:@"lighting_vertex"];
    if(!vertexProgram)
        NSLog(@">> ERROR: Couldn't load vertex function from default library");
    
    // setup the vertex buffers
    _vertexBuffer = [_device newBufferWithBytes:kCubeVertexData length:sizeof(kCubeVertexData) options:MTLResourceOptionCPUCacheModeDefault];
    _vertexBuffer.label = @"Vertices";
    
    // create a pipeline state descriptor which can be used to create a compiled pipeline state object
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    pipelineStateDescriptor.label                           = @"MyPipeline";
    pipelineStateDescriptor.sampleCount                     = view.sampleCount;
    pipelineStateDescriptor.vertexFunction                  = vertexProgram;
    pipelineStateDescriptor.fragmentFunction                = fragmentProgram;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineStateDescriptor.depthAttachmentPixelFormat      = view.depthPixelFormat;
    
    // create a compiled pipeline state object. Shader functions (from the render pipeline descriptor)
    // are compiled when this is created unlessed they are obtained from the device's cache
    NSError *error = nil;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if(!_pipelineState) {
        NSLog(@">> ERROR: Failed Aquiring pipeline state: %@", error);
        return NO;
    }
    
    return YES;
}

#pragma mark Render

- (void)render:(AAPLView *)view
{
    // Allow the renderer to preflight 3 frames on the CPU (using a semapore as a guard) and commit them to the GPU.
    // This semaphore will get signaled once the GPU completes a frame's work via addCompletedHandler callback below,
    // signifying the CPU can go ahead and prepare another frame.
    dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    
    // Prior to sending any data to the GPU, constant buffers should be updated accordingly on the CPU.
    [self updateConstantBuffer];
    
    // create a new command buffer for each renderpass to the current drawable
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    // create a render command encoder so we can render into something
    MTLRenderPassDescriptor *renderPassDescriptor = view.renderPassDescriptor;
    if (renderPassDescriptor)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"Boxes"];
        [renderEncoder setDepthStencilState:_depthState];
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0 ];
        
        // Use instanced drawing to render all of the boxes. Note, each will have its own constant data thereby making the helix shape.
        // The shader uses instance_id to determine which portion of the constant buffer to read
        [renderEncoder setVertexBuffer:_dynamicConstantBuffer[_constantDataBufferIndex] offset:0 atIndex:1 ];
            
        // tell the render context we want to draw our primitives
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:36 instanceCount:kNumberOfBoxes];
        
        [renderEncoder endEncoding];
        [renderEncoder popDebugGroup];
        
        // schedule a present once rendering to the framebuffer is complete
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    // Add a completion handler / block to be called once the command buffer is completed by the GPU. All completion handlers will be returned in the order they were committed.
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

- (void)reshape:(AAPLView *)view
{
    // when reshape is called, update the view and projection matricies since this means the view orientation or size changed
    float aspect = fabsf(view.bounds.size.width / view.bounds.size.height);
    _projectionMatrix = perspective_fov(kFOVY, aspect, 0.1f, 100.0f);
    _viewMatrix = lookAt(kEye, kCenter, kUp);
}

#pragma mark Update

// only called at setup time
- (void)prepareTransforms
{
    for (int i = 0; i < kNumberOfBoxes; i++)
    {
        // calculate x,y,z position for translation matrix using spherical coordinate system
        // place somewhere in a helix
        float pos = (float((i+1)*2.0)/kNumberOfBoxes);
        float t = radians(kTheta * pos);
        float p = radians(kPhi * pos);
        float x = kRadius*cos(t)*sin(p);
        float y = kRadius*sin(t)*sin(p);
        float z = kRadius*cos(t);
        
        // translate to a viewable position on the screen
        _baseModelMatrix[i] = translate(x, y, z) * translate(0.0f, 0.0f, 15.0f);
    }
}

// called every frame
- (void)updateConstantBuffer
{
    constants_t *constant_buffer = (constants_t *)[_dynamicConstantBuffer[_constantDataBufferIndex] contents];
    for (int i = 0; i < kNumberOfBoxes; i++)
    {
        // calculate the Model view projection matrix of each box
        float4x4 modelViewMatrix = _baseModelMatrix[i] * rotate(_rotation, 1.0f, 1.0f, 1.0f);
        modelViewMatrix = _viewMatrix * modelViewMatrix;
        constant_buffer[i].normal_matrix = inverse(transpose(modelViewMatrix));
        constant_buffer[i].modelview_projection_matrix = _projectionMatrix * modelViewMatrix;
        
        // change the color each frame
        // reverse direction if we've reached a boundary
        if (constant_buffer[i].ambient_color.y >= 0.8) {
            constant_buffer[i].multiplier = -1;
            constant_buffer[i].ambient_color.y = 0.79;
        } else if (constant_buffer[i].ambient_color.y <= 0.2) {
            constant_buffer[i].multiplier = 1;
            constant_buffer[i].ambient_color.y = 0.21;
        } else
            constant_buffer[i].ambient_color.y += constant_buffer[i].multiplier * 0.0001*i;
    }
}

// just use this to update app globals
- (void)update:(AAPLViewController *)controller
{
    _rotation += controller.timeSinceLastDraw * 50.0f;
}

- (void)viewController:(AAPLViewController *)controller willPause:(BOOL)pause
{
    // timer is suspended/resumed
    // Can do any non-rendering related background work here when suspended
}


@end
