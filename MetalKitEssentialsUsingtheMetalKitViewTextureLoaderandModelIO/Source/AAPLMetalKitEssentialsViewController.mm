/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 MetalKit view controller that's setup as the MTKViewDelegate.
 */

#import <Metal/Metal.h>
#import <simd/simd.h>
#import <MetalKit/MetalKit.h>
#import "AAPLShaderTypes.h"
#import "AAPLMetalKitEssentialsViewController.h"
#import "AAPLMetalKitEssentialsMesh.h"

// The  number of command buffers in flight.
const NSUInteger AAPLBuffersInflightBuffers = 3;

@implementation AAPLMetalKitEssentialsViewController {
    /*
        Using ivars instead of properties to avoid any performance penalities with
        the Objective-C runtime.
    */
    
    // View.
    MTKView *_view;
    
    // View Controller.
    dispatch_semaphore_t _inflightSemaphore;
    uint8_t _constantDataBufferIndex;
    
    // Renderer.
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;
    id <MTLLibrary> _defaultLibrary;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLDepthStencilState> _depthState;
    
    // Uniforms.
    matrix_float4x4 _projectionMatrix;
    matrix_float4x4 _viewMatrix;
    float _rotation;
    
    // Meshes.
    NSMutableArray<AAPLMetalKitEssentialsMesh *> *_meshes;
    
    id <MTLBuffer> _frameUniformBuffers[AAPLBuffersInflightBuffers];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _constantDataBufferIndex = 0;
    _inflightSemaphore = dispatch_semaphore_create(AAPLBuffersInflightBuffers);
    
    [self setupMetal];
    [self setupView];
    [self loadAssets];
    [self reshape];
}

- (void)setupView {
    _view = (MTKView *)self.view;
    _view.delegate = self;
    _view.device = _device;
    
    // Setup the render target, choose values based on your app.
    _view.sampleCount = 4;
    _view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
}

- (void)setupMetal {
    // Set the view to use the default device.
    _device = MTLCreateSystemDefaultDevice();

    // Create a new command queue.
    _commandQueue = [_device newCommandQueue];
    
    // Load all the shader files with a metal file extension in the project.
    _defaultLibrary = [_device newDefaultLibrary];
}

- (void)loadAssets {
    // Load the fragment program into the library.
    id <MTLFunction> fragmentProgram = [_defaultLibrary newFunctionWithName:@"fragmentLight"];

    // Load the vertex program into the library.
    id <MTLFunction> vertexProgram = [_defaultLibrary newFunctionWithName:@"vertexLight"];

    /*
        Create a vertex descriptor for our Metal pipeline. Specifies the layout 
        of vertices the pipeline should expect.
    */
    MTLVertexDescriptor *mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];

    // Positions.
    mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].format = MTLVertexFormatFloat3;
    mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].offset = 0;
    mtlVertexDescriptor.attributes[AAPLVertexAttributePosition].bufferIndex = AAPLMeshVertexBuffer;

    // Normals.
    mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].format = MTLVertexFormatFloat3;
    mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].offset = 12;
    mtlVertexDescriptor.attributes[AAPLVertexAttributeNormal].bufferIndex = AAPLMeshVertexBuffer;

    // Texture coordinates.
    mtlVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].format = MTLVertexFormatHalf2;
    mtlVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].offset = 24;
    mtlVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].bufferIndex = AAPLMeshVertexBuffer;

    // Single interleaved buffer.
    mtlVertexDescriptor.layouts[AAPLMeshVertexBuffer].stride = 28;
    mtlVertexDescriptor.layouts[AAPLMeshVertexBuffer].stepRate = 1;
    mtlVertexDescriptor.layouts[AAPLMeshVertexBuffer].stepFunction = MTLVertexStepFunctionPerVertex;

    // Create a reusable pipeline state
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"MyPipeline";
    pipelineStateDescriptor.sampleCount = _view.sampleCount;
    pipelineStateDescriptor.vertexFunction = vertexProgram;
    pipelineStateDescriptor.fragmentFunction = fragmentProgram;
    pipelineStateDescriptor.vertexDescriptor = mtlVertexDescriptor;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = _view.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = _view.depthStencilPixelFormat;
    pipelineStateDescriptor.stencilAttachmentPixelFormat = _view.depthStencilPixelFormat;

    NSError *error;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];

    if (!_pipelineState) {
        NSLog(@"Failed to create pipeline state, error %@", error);
    }

    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

    
    /*
        From our Metal vertex descriptor, create a Model I/O vertex descriptor we'll
        load our asset with. This specifies the layout of vertices Model I/O should
        format loaded meshes with.
    */
    MDLVertexDescriptor *mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(mtlVertexDescriptor);
    mdlVertexDescriptor.attributes[AAPLVertexAttributePosition].name = MDLVertexAttributePosition;
    mdlVertexDescriptor.attributes[AAPLVertexAttributeNormal].name   = MDLVertexAttributeNormal;
    mdlVertexDescriptor.attributes[AAPLVertexAttributeTexcoord].name = MDLVertexAttributeTextureCoordinate;

    MTKMeshBufferAllocator *bufferAllocator = [[MTKMeshBufferAllocator alloc] initWithDevice:_device];

    NSURL *assetURL = [[NSBundle mainBundle] URLForResource:@"Data/Assets/realship/realship.obj"
                                              withExtension:nil];

    if(!assetURL) {
        NSLog(@"Could not find asset.");
    }

    /*
        Load Model I/O Asset with mdlVertexDescriptor, specifying vertex layout and
        bufferAllocator enabling ModelIO to load vertex and index buffers directory
        into Metal GPU memory.
    */ 
    MDLAsset *asset = [[MDLAsset alloc] initWithURL:assetURL vertexDescriptor:mdlVertexDescriptor bufferAllocator:bufferAllocator];

    // Create MetalKit meshes.
    NSArray<MTKMesh *> *mtkMeshes;
    NSArray<MDLMesh *> *mdlMeshes;

    mtkMeshes = [MTKMesh newMeshesFromAsset:asset
                                     device:_device
                               sourceMeshes:&mdlMeshes
                                      error:&error];

    if (!mtkMeshes) {
        NSLog(@"Failed to create mesh, error %@", error);
        return;
    }

    
    // Create our array of App-Specific mesh wrapper objects.
    _meshes = [[NSMutableArray alloc] initWithCapacity:mtkMeshes.count];


    assert(mtkMeshes.count == mdlMeshes.count);

    for (NSUInteger index = 0; index < mtkMeshes.count; index++) {
        AAPLMetalKitEssentialsMesh *mesh = [[AAPLMetalKitEssentialsMesh alloc]initWithMesh:mtkMeshes[index]
                                                                                   mdlMesh:mdlMeshes[index]
                                                                                    device:_device];
        [_meshes addObject:mesh];
    }
   
    // Create a uniform buffer that we'll dynamicall update each frame.
    for (uint8_t i = 0; i < AAPLBuffersInflightBuffers; i++) {
        _frameUniformBuffers[i] = [_device newBufferWithLength:sizeof(AAPLFrameUniforms) options:0];
    }
}

- (void)render {
    dispatch_semaphore_wait(_inflightSemaphore, DISPATCH_TIME_FOREVER);
    
    // Perofm any app logic, including updating any Metal buffers.
    [self update];

    // Create a new command buffer for each renderpass to the current drawable.
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Main Command Buffer";
    
    // Obtain a renderPassDescriptor generated from the view's drawable textures.
    MTLRenderPassDescriptor* renderPassDescriptor = _view.currentRenderPassDescriptor;
    
    // Create a render command encoder so we can render into something.
    id <MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    renderEncoder.label = @"Final Pass Encoder";
    
    // Set context state.
    [renderEncoder setViewport:{0, 0, _view.drawableSize.width, _view.drawableSize.height, 0, 1}];
    [renderEncoder setDepthStencilState:_depthState];
    [renderEncoder setRenderPipelineState:_pipelineState];
    
    // Set the our per frame uniforms.
    [renderEncoder setVertexBuffer:_frameUniformBuffers[_constantDataBufferIndex]
                            offset:0
                           atIndex:AAPLFrameUniformBuffer];
    
    [renderEncoder pushDebugGroup:@"Render Meshes"];
    
    // Render each of our meshes.
    for(AAPLMetalKitEssentialsMesh *mesh in _meshes) {
        [mesh renderWithEncoder:renderEncoder];
    }
    
    [renderEncoder popDebugGroup];
    
    // We're done encoding commands.
    [renderEncoder endEncoding];
    
    /*
        Call the view's completion handler which is required by the view since
        it will signal its semaphore and set up the next buffer.
    */
    __block dispatch_semaphore_t block_sema = _inflightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(block_sema);
    }];
    
    /*
        The renderview assumes it can now increment the buffer index and that
        the previous index won't be touched until we cycle back around to the same index.
    */
    _constantDataBufferIndex = (_constantDataBufferIndex + 1) % AAPLBuffersInflightBuffers;
    
    // Schedule a present once the framebuffer is complete using the current drawable.
    [commandBuffer presentDrawable:_view.currentDrawable];
    
    // Finalize rendering here & push the command buffer to the GPU.
    [commandBuffer commit];
}

- (void)reshape {
    /*
        When reshape is called, update the view and projection matricies since 
        this means the view orientation or size changed.
    */
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    _projectionMatrix = matrix_from_perspective_fov_aspectLH(65.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);
    
    _viewMatrix = matrix_identity_float4x4;
}

- (void)update {
    AAPLFrameUniforms *frameData = (AAPLFrameUniforms *)[_frameUniformBuffers[_constantDataBufferIndex] contents];

    frameData->model = matrix_from_translation(0.0f, 0.0f, 2.0f) * matrix_from_rotation(_rotation, 1.0f, 1.0f, 0.0f);    frameData->view = _viewMatrix;
    
    matrix_float4x4 modelViewMatrix = frameData->view * frameData->model;
    
    frameData->projectionView = _projectionMatrix * modelViewMatrix;
    
    frameData->normal = matrix_invert(matrix_transpose(modelViewMatrix));
    
    _rotation += 0.05f;
}

// Called whenever view changes orientation or layout is changed
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    [self reshape];
}


// Called whenever the view needs to render
- (void)drawInMTKView:(nonnull MTKView *)view {
    @autoreleasepool {
        [self render];
    }
}

#pragma mark Utilities

static matrix_float4x4 matrix_from_perspective_fov_aspectLH(const float fovY, const float aspect, const float nearZ, const float farZ) {
    // 1 / tan == cot
    float yscale = 1.0f / tanf(fovY * 0.5f);
    float xscale = yscale / aspect;
    float q = farZ / (farZ - nearZ);
    
    matrix_float4x4 m = {
        .columns[0] = { xscale, 0.0f, 0.0f, 0.0f },
        .columns[1] = { 0.0f, yscale, 0.0f, 0.0f },
        .columns[2] = { 0.0f, 0.0f, q, 1.0f },
        .columns[3] = { 0.0f, 0.0f, q * -nearZ, 0.0f }
    };
    
    return m;
}

static matrix_float4x4 matrix_from_translation(float x, float y, float z) {
    matrix_float4x4 m = matrix_identity_float4x4;
    m.columns[3] = (vector_float4) { x, y, z, 1.0 };
    return m;
}

static matrix_float4x4 matrix_from_rotation(float radians, float x, float y, float z) {
    vector_float3 v = vector_normalize(((vector_float3){x, y, z}));
    float cos = cosf(radians);
    float cosp = 1.0f - cos;
    float sin = sinf(radians);

    return (matrix_float4x4) {
        .columns[0] = {
            cos + cosp * v.x * v.x,
            cosp * v.x * v.y + v.z * sin,
            cosp * v.x * v.z - v.y * sin,
            0.0f,
        },
        
        .columns[1] = {
            cosp * v.x * v.y - v.z * sin,
            cos + cosp * v.y * v.y,
            cosp * v.y * v.z + v.x * sin,
            0.0f,
        },
        
        .columns[2] = {
            cosp * v.x * v.z + v.y * sin,
            cosp * v.y * v.z - v.x * sin,
            cos + cosp * v.z * v.z,
            0.0f,
        },
        
        .columns[3] = { 0.0f, 0.0f, 0.0f, 1.0f
        }
    };
}

@end
