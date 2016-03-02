/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
     This is the main renderer for this sample.  Acts as the update and render delegate for the view controller and performs rendering. renders in 2 passes, 1) shadow pass, 2) Gbuffer pass which retains the drawable and presents it to the screen while discard the remaining attachments
  
 */

#import "AAPLRenderer.h"
#import "AAPLViewController.h"
#import "AAPLView.h"
#import "AAPLTransforms.h"
#import "AAPLUtilities.h"

#import "common.h"

#import <simd/simd.h>

using namespace AAPL;

// number of fairy lights spinning around temple
static const uint32_t kNumFairies = 64;

// light radius
static const float kLightRadius = 0.5f;

// total number of frames to preapare in advanced
static const int kMaxFrameLag = 3;

@implementation AAPLRenderer
{
    id <MTLCommandQueue>           _commandQueue;
    id <MTLLibrary>                _defaultLibrary;
    CFTimeInterval                 _frameTime;
    dispatch_semaphore_t           _inflight_semaphore;
    
    float4                         _fairyColors[kNumFairies];
    float                          _fairyAngles[kNumFairies];
    float                          _fairyPhases[kNumFairies];
    float                          _fairySpeeds[kNumFairies];
    
    LightFragmentInputs            _lightData[kNumFairies+1];
    
    float3                         _sunColor;
    ClearColorBuffers              _clear_color_buffers;
    float                          _structureCameraRotationRate;
    float                          _skyboxCameraRotationRate;
    float                          _skyboxScale;
    float                          _structureScale;
    float4x4                       _projectionMatrix;
    
    id<MTLDepthStencilState>       _noDepthStencilState;
    id<MTLDepthStencilState>       _lightMaskStencilState;
    id<MTLDepthStencilState>       _lightColorStencilState;
    id<MTLDepthStencilState>       _lightColorStencilStateNoDepth;
    id<MTLDepthStencilState>       _gBufferDepthStencilState;
    id<MTLDepthStencilState>       _shadowDepthStencilState;
    id<MTLDepthStencilState>       _compositionDepthState;
    
    MTLRenderPassDescriptor*       _shadowRenderPassDescriptor;
    id<MTLTexture>                 _shadow_texture;
    
    id<MTLRenderPipelineState>     _shadow_render_pipeline;
    id<MTLRenderPipelineState>     _skybox_render_pipeline;
    id<MTLRenderPipelineState>     _gbuffer_render_pipeline;
    id<MTLRenderPipelineState>     _light_mask_pipeline;
    id<MTLRenderPipelineState>     _light_color_pipeline;
    id<MTLRenderPipelineState>     _composition_pipeline;
    id<MTLRenderPipelineState>     _fairy_pipeline;
    id<MTLRenderPipelineState>     _texture_copy_pipeline;
    
    id<MTLTexture>                 _skyboxTexture;
    id<MTLTexture>                 _fairyTexture;
    NSMutableArray*                _structureModelGroupDiffuseTextures;
    NSMutableArray*                _structureModelGroupSpecularTextures;
    NSMutableArray*                _structureModelGroupBumpTextures;
    
    NSMutableDictionary*           _texture2DCache;

    id<MTLBuffer>                  _skyboxVertexBuffer;
    id<MTLBuffer>                  _quadPositionBuffer;
    id<MTLBuffer>                  _quadTexcoordBuffer;
    id<MTLBuffer>                  _structureVertexBuffer;
    id<MTLBuffer>                  _structureIndexBuffer;
    id<MTLBuffer>                  _lightModelVertexBuffer;
    id<MTLBuffer>                  _lightModelIndexBuffer;
    id<MTLBuffer>                  _spriteBuffer;
    
    NSMutableArray<id<MTLBuffer>>* _lightModelMatrixBuffers;
    NSMutableArray<id<MTLBuffer>>* _lightDataBuffers;
    NSMutableArray<id<MTLBuffer>>* _sunDataBuffers;
    NSMutableArray<id<MTLBuffer>>* _skyboxMatrixBuffers;
    NSMutableArray<id<MTLBuffer>>* _modelMatricesBuffers;
    NSMutableArray<id<MTLBuffer>>* _zOnlyProjectionBuffers;
    NSMutableArray<id<MTLBuffer>>* _fairySpriteBuffers;
    
    id<MTLBuffer>                  _clearColorBuffer1;
    id<MTLBuffer>                  _clearColorBuffer2;
    
    AAPLOBJModel*                  _structureModel;
    AAPLOBJModelGroup*             _structureModelGroup;
    
    MTLIndexType                   _structureModelGroupIndexDataType;
    int                            _fairyCount;
    
    int                            _numFrames;
    int                            _currFrameIndex;}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        // find a usable Device
        _device = MTLCreateSystemDefaultDevice();
        
        // create a new command queue
        _commandQueue = [_device newCommandQueue];
        
        _defaultLibrary = [_device newDefaultLibrary];
        if(!_defaultLibrary) {
            NSLog(@">> ERROR: Couldnt create a default shader library");
            
            // assert here becuase if the shader libary isnt loading, shaders arent compiling
            assert(0);
        }
        
        //Setup Globals constants
        _sunColor = {1.0f, 0.875f, 0.75f};
        
        _clear_color_buffers.clear_color = {0.0, 0.0, 0.0, 1.0};
        _clear_color_buffers.albedo_clear_color = {_sunColor.x * 0.75f + 0.075f, _sunColor.y * 0.75f + 0.075f, _sunColor.z * 0.75f + 0.075f, 1.0};
        _clear_color_buffers.light_buffer_clear_color = {0.1f, 0.1f, 0.125f, 0.0f};
        
        // Clear linear depth buffer to far plane in eye-space (25)
        _clear_color_buffers.linear_depth_clear_color = {25.0f, 25.0f, 25.0f, 25.0f};
        
        _structureCameraRotationRate = 7.5f;
        _structureScale = 0.01f;
        _skyboxCameraRotationRate = 2.0f;
        _skyboxScale = 10.0f;
        
        _structureModelGroupBumpTextures = [[NSMutableArray alloc] initWithCapacity: 10];
        _structureModelGroupDiffuseTextures = [[NSMutableArray alloc] initWithCapacity: 10];
        _structureModelGroupSpecularTextures = [[NSMutableArray alloc] initWithCapacity: 10];
        
        _texture2DCache = [NSMutableDictionary dictionaryWithCapacity:8];
        
        _lightDataBuffers = [[NSMutableArray alloc] initWithCapacity: kMaxFrameLag];
        _lightModelMatrixBuffers = [[NSMutableArray alloc] initWithCapacity: kMaxFrameLag];
        _sunDataBuffers = [[NSMutableArray alloc] initWithCapacity: kMaxFrameLag];
        _skyboxMatrixBuffers = [[NSMutableArray alloc] initWithCapacity: kMaxFrameLag];
        _modelMatricesBuffers = [[NSMutableArray alloc] initWithCapacity: kMaxFrameLag];
        _zOnlyProjectionBuffers = [[NSMutableArray alloc] initWithCapacity: kMaxFrameLag];
        _fairySpriteBuffers = [[NSMutableArray alloc] initWithCapacity: kMaxFrameLag];
        
        _fairyCount = kNumFairies;
        
        for (NSInteger i = 0; i < kNumFairies; i++)
        {
            _fairyColors[i] = Utilities::randomColor();
            _fairyAngles[i] = Utilities::randomFloat(0.0f, Utilities::PI * 2.0f);
            _fairyPhases[i] = Utilities::randomFloat(0.0f, 1.0f);
            _fairySpeeds[i] = Utilities::randomFloat(5.0f, 15.0f);
        }
        
        _inflight_semaphore = dispatch_semaphore_create(kMaxFrameLag);
        _numFrames = kMaxFrameLag;
        _currFrameIndex = 0;
    }
    return self;
}

#pragma mark LOAD

- (void)configure:(AAPLView *)view
{
    // set up g-buffer framebuffer via view for final pass (which is also g-buffer pass).
    // Final results are composited to color_attachment0 in the view, which is the main drawable texture
    // so the other attachemnts do not need to be stored unless we want to view the intermediate results
    view->colorAttachmentFormat[0] = MTLPixelFormatBGRA8Unorm;
    view->colorAttachmentClearValue[0] = MTLClearColorMake(_clear_color_buffers.albedo_clear_color[0], _clear_color_buffers.albedo_clear_color[1], _clear_color_buffers.albedo_clear_color[2], _clear_color_buffers.albedo_clear_color[3]);

    view->colorAttachmentFormat[1] = MTLPixelFormatBGRA8Unorm;
    view->colorAttachmentClearValue[1] = MTLClearColorMake(_clear_color_buffers.clear_color[0], _clear_color_buffers.clear_color[1], _clear_color_buffers.clear_color[2], _clear_color_buffers.clear_color[3]);
    
    view->colorAttachmentFormat[2] = MTLPixelFormatR32Float;
    view->colorAttachmentClearValue[2] = MTLClearColorMake(_clear_color_buffers.linear_depth_clear_color[0], _clear_color_buffers.linear_depth_clear_color[1], _clear_color_buffers.linear_depth_clear_color[2], _clear_color_buffers.linear_depth_clear_color[3]);
    
    view->colorAttachmentFormat[3] = MTLPixelFormatBGRA8Unorm;
    view->colorAttachmentClearValue[3] = MTLClearColorMake(_clear_color_buffers.light_buffer_clear_color[0], _clear_color_buffers.light_buffer_clear_color[1], _clear_color_buffers.light_buffer_clear_color[2], _clear_color_buffers.light_buffer_clear_color[3]);
    
    view->depthPixelFormat = MTLPixelFormatDepth32Float;
    view->depthAttachmentClearValue = 1.0;
    
    view->stencilPixelFormat = MTLPixelFormatStencil8;
    view->stencilAttachmentClearValue = 0;
    
    // setup shadow buffer for first pass
    
    MTLTextureDescriptor *shadowTextureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: MTLPixelFormatDepth32Float width: 1024 height: 1024 mipmapped: NO];
    _shadow_texture   =  [_device newTextureWithDescriptor: shadowTextureDesc];
    [_shadow_texture setLabel:@"shadow map"];
    
    _shadowRenderPassDescriptor = [MTLRenderPassDescriptor new];
    MTLRenderPassDepthAttachmentDescriptor *shadow_attachment = _shadowRenderPassDescriptor.depthAttachment;
    shadow_attachment.texture = _shadow_texture;
    shadow_attachment.loadAction = MTLLoadActionClear;
    shadow_attachment.storeAction = MTLStoreActionStore;
    shadow_attachment.clearDepth = 1.0;
    
    //
    // Shader loading
    //*******************************************************************
    
    id<MTLFunction> fairyVert = _newFunctionFromLibrary(_defaultLibrary, @"fairyVertex");
    id<MTLFunction> fairyFrag = _newFunctionFromLibrary(_defaultLibrary, @"fairyFragment");
    
    id<MTLFunction> gBufferVert = _newFunctionFromLibrary(_defaultLibrary, @"gBufferVert");
    id<MTLFunction> gBufferFrag = _newFunctionFromLibrary(_defaultLibrary, @"gBufferFrag");
    
    id<MTLFunction> lightVert = _newFunctionFromLibrary(_defaultLibrary, @"lightVert");
    id<MTLFunction> lightFrag = _newFunctionFromLibrary(_defaultLibrary, @"lightFrag");
    
    id<MTLFunction> compositionVert = _newFunctionFromLibrary(_defaultLibrary, @"compositionVertex");
    id<MTLFunction> compositionFrag = _newFunctionFromLibrary(_defaultLibrary, @"compositionFrag");
    
    id<MTLFunction> skyboxVert = _newFunctionFromLibrary(_defaultLibrary, @"skyboxVert");
    id<MTLFunction> skyboxFrag = _newFunctionFromLibrary(_defaultLibrary, @"skyboxFrag");
    
    id<MTLFunction> zOnlyVert = _newFunctionFromLibrary(_defaultLibrary, @"zOnly");
    
    // Pipeline setup
    //*********************************************************************
    {
        MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
        NSError *err = nil;
    
        desc.label = @"Shadow Render";
        desc.vertexFunction = zOnlyVert;
        desc.fragmentFunction = nil;
        desc.depthAttachmentPixelFormat = _shadow_texture.pixelFormat;
        _shadow_render_pipeline = [_device newRenderPipelineStateWithDescriptor: desc error: &err];
        CheckPipelineError(_shadow_render_pipeline, err);
        
        desc.label = @"Skybox Render";
        desc.vertexFunction = skyboxVert;
        desc.fragmentFunction = skyboxFrag;
        for (int i = 0; i <= 3; i++)
            desc.colorAttachments[i].pixelFormat = view->colorAttachmentFormat[i];
        desc.depthAttachmentPixelFormat = view->depthPixelFormat;
        desc.stencilAttachmentPixelFormat = view->stencilPixelFormat;
        _skybox_render_pipeline = [_device newRenderPipelineStateWithDescriptor: desc error: &err];
        CheckPipelineError(_skybox_render_pipeline, err);
        
        //[desc reset];
        desc.label = @"GBuffer Render";
        desc.vertexFunction = gBufferVert;
        desc.fragmentFunction = gBufferFrag;
        _gbuffer_render_pipeline = [_device newRenderPipelineStateWithDescriptor: desc error: &err];
        CheckPipelineError(_gbuffer_render_pipeline, err);

        desc.label = @"Light Mask Render";
        desc.vertexFunction = lightVert;
        desc.fragmentFunction = nil;
        //Have active rendertargets but don't want to write to color
        //setup a blendsetate with no color writes for light mask pipeline
        for (int i = 0; i <= 3; i++)
            desc.colorAttachments[i].writeMask = MTLColorWriteMaskNone;
        _light_mask_pipeline = [_device newRenderPipelineStateWithDescriptor: desc error: &err];
        CheckPipelineError(_light_mask_pipeline, err);
        
        desc.label = @"Light Color Render";
        desc.vertexFunction = lightVert;
        desc.fragmentFunction = lightFrag;
        //reset default
        for (int i = 0; i <= 3; i++)
            desc.colorAttachments[i].writeMask = MTLColorWriteMaskAll;
        _light_color_pipeline = [_device newRenderPipelineStateWithDescriptor: desc error: &err];
        CheckPipelineError(_light_color_pipeline, err);
		
        desc.label = @"Composition Render";
        desc.vertexFunction = compositionVert;
        desc.fragmentFunction = compositionFrag;
        _composition_pipeline = [_device newRenderPipelineStateWithDescriptor: desc error: &err];
        CheckPipelineError(_composition_pipeline, err);
        
        desc.label = @"Fairy Sprites";
        desc.vertexFunction = fairyVert;
        desc.fragmentFunction = fairyFrag;
        _fairy_pipeline = [_device newRenderPipelineStateWithDescriptor: desc error: &err];
        CheckPipelineError(_fairy_pipeline, err);
    }
    
    //Setup depth and stencil state objects
    //*********************************************************************
    {
        MTLDepthStencilDescriptor *desc = [[MTLDepthStencilDescriptor alloc] init];
        MTLStencilDescriptor *stencilState = [[MTLStencilDescriptor alloc] init];
        
        desc.depthWriteEnabled = NO;
        desc.depthCompareFunction = MTLCompareFunctionAlways;
        _noDepthStencilState = [_device newDepthStencilStateWithDescriptor: desc];
        
        desc.depthWriteEnabled = YES;
        desc.depthCompareFunction = MTLCompareFunctionLessEqual;
        _shadowDepthStencilState = [_device newDepthStencilStateWithDescriptor: desc];
        
        desc.depthWriteEnabled = YES;
        stencilState.stencilCompareFunction = MTLCompareFunctionAlways;
        stencilState.stencilFailureOperation = MTLStencilOperationKeep;
        stencilState.depthFailureOperation = MTLStencilOperationKeep;
        stencilState.depthStencilPassOperation = MTLStencilOperationReplace;
        stencilState.readMask = 0xFF;
        stencilState.writeMask = 0xFF;
        desc.depthCompareFunction = MTLCompareFunctionLessEqual;
        desc.frontFaceStencil = stencilState;
        desc.backFaceStencil = stencilState;
        _gBufferDepthStencilState = [_device newDepthStencilStateWithDescriptor: desc];
        
        desc.depthWriteEnabled = NO;
        stencilState.stencilCompareFunction = MTLCompareFunctionEqual;
        stencilState.stencilFailureOperation = MTLStencilOperationKeep;
        stencilState.depthFailureOperation = MTLStencilOperationIncrementClamp;
        stencilState.depthStencilPassOperation = MTLStencilOperationKeep;
        stencilState.readMask = 0xFF;
        stencilState.writeMask = 0xFF;
        desc.depthCompareFunction = MTLCompareFunctionLessEqual;
        desc.frontFaceStencil = stencilState;
        desc.backFaceStencil = stencilState;
        _lightMaskStencilState  = [_device newDepthStencilStateWithDescriptor: desc];
        
        desc.depthWriteEnabled = NO;
        stencilState.stencilCompareFunction = MTLCompareFunctionLess;
        stencilState.stencilFailureOperation = MTLStencilOperationKeep;
        stencilState.depthFailureOperation = MTLStencilOperationDecrementClamp;
        stencilState.depthStencilPassOperation = MTLStencilOperationDecrementClamp;
        stencilState.readMask = 0xFF;
        stencilState.writeMask = 0xFF;
        desc.depthCompareFunction = MTLCompareFunctionLessEqual;
        desc.frontFaceStencil = stencilState;
        desc.backFaceStencil = stencilState;
        _lightColorStencilState  = [_device newDepthStencilStateWithDescriptor: desc];
        
        //Sharing the same state but just always passing depth
        desc.depthCompareFunction = MTLCompareFunctionAlways;
        _lightColorStencilStateNoDepth  = [_device newDepthStencilStateWithDescriptor: desc];
        
        desc.depthWriteEnabled = NO;
        stencilState.stencilCompareFunction = MTLCompareFunctionEqual;
        stencilState.stencilFailureOperation = MTLStencilOperationKeep;
        stencilState.depthFailureOperation = MTLStencilOperationKeep;
        stencilState.depthStencilPassOperation = MTLStencilOperationKeep;
        stencilState.readMask = 0xFF;
        stencilState.writeMask = 0;
        desc.depthCompareFunction = MTLCompareFunctionAlways;
        desc.frontFaceStencil = stencilState;
        desc.backFaceStencil = stencilState;
        _compositionDepthState = [_device newDepthStencilStateWithDescriptor: desc];
        
        stencilState = nil;
    }
    
    //Load models and create buffers
    //*********************************************************************
    SpriteData sprite;
    sprite.con_scale_intensity[0] = 2.0f;
    sprite.con_scale_intensity[1] = 4.0f;
    sprite.con_scale_intensity[2] = 2.0f;
    
    _spriteBuffer = [_device newBufferWithBytes:&sprite length:sizeof(SpriteData) options:0];
    [_spriteBuffer setLabel:@"sprite data"];
    
    float texcoords[] =
    {
        0.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
        
        0.0f, 0.0f,
        1.0f, 0.0f,
        1.0f, 1.0f
    };
    
    //All the combinations of quads needed.
    float quadVerts[] =
    {
        -1.0f, 1.0f,
        1.0f, -1.0f,
        -1.0f, -1.0f,
        -1.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, -1.0f,
        
        -1.0f, 1.0f,
        0.0f, 0.0f,
        -1.0f, 0.0f,
        -1.0f, 1.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
        
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        
        -1.0f, 0.0f,
        0.0f, -1.0f,
        -1.0f, -1.0f,
        -1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, -1.0f,
        
        0.0f, 0.0f,
        1.0f, -1.0f,
        0.0f, -1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
        1.0f, -1.0f,
        
    };
    
    _quadPositionBuffer = [_device newBufferWithBytes:quadVerts length:sizeof(quadVerts) options:0];
    [_quadPositionBuffer setLabel:@"quad vertices"];
    _quadTexcoordBuffer = [_device newBufferWithBytes:texcoords length:sizeof(texcoords) options:0];
    [_quadTexcoordBuffer setLabel:@"quad texcoords"];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundlePath = [bundle pathForResource: @"Temple" ofType: @"obj"];
    _structureModel = [[AAPLOBJModel alloc] initWithContentsOfFile:bundlePath computeTangentSpace: YES normalizeNormals: NO];
    _structureModelGroup = [[[_structureModel objects] objectForKey: AAPLOBJModelObjectDefaultKey] objectForKey: @"cage_stairs_01"];
    
    assert(_structureModel);
    assert(_structureModelGroup);
    
    _structureVertexBuffer   =  [_device newBufferWithBytes:[[_structureModel vertexData] bytes] length:[[_structureModel vertexData] length] options:0];
    [_structureVertexBuffer setLabel:@"structure vertices"];
    _structureIndexBuffer    =  [_device newBufferWithBytes:[[_structureModelGroup indexData] bytes] length:[[_structureModelGroup indexData] length] options:0];
    [_structureIndexBuffer setLabel:@"structure indices"];
    
    _structureModelGroupIndexDataType = MTLIndexTypeUInt16;
    if([_structureModelGroup bytesPerIndex] == 4)
    {
        _structureModelGroupIndexDataType = MTLIndexTypeUInt32;
    }
    
    static float vdata[24][4] =
    {
        // posx
        { -1.0f,  1.0f,  1.0f, 1.0f }
        ,
        { -1.0f, -1.0f,  1.0f, 1.0f }
        ,
        { -1.0f,  1.0f, -1.0f, 1.0f }
        ,
        { -1.0f, -1.0f, -1.0f, 1.0f }
        ,
        
        // negz
        { -1.0f,  1.0f, -1.0f, 1.0f }
        ,
        { -1.0f, -1.0f, -1.0f, 1.0f }
        ,
        { 1.0f,  1.0f, -1.0f, 1.0f }
        ,
        { 1.0f, -1.0f, -1.0f, 1.0f }
        ,
        
        // negx
        { 1.0f,  1.0f, -1.0f, 1.0f }
        ,
        { 1.0f, -1.0f, -1.0f, 1.0f }
        ,
        { 1.0f,  1.0f,  1.0f, 1.0f }
        ,
        { 1.0f, -1.0f,  1.0f, 1.0f }
        ,
        
        // posz
        { 1.0f,  1.0f,  1.0f, 1.0f }
        ,
        { 1.0f, -1.0f,  1.0f, 1.0f }
        ,
        { -1.0f,  1.0f,  1.0f, 1.0f }
        ,
        { -1.0f, -1.0f,  1.0f, 1.0f }
        ,
        
        // posy
        { 1.0f,  1.0f, -1.0f, 1.0f }
        ,
        { 1.0f,  1.0f,  1.0f, 1.0f }
        ,
        { -1.0f,  1.0f, -1.0f, 1.0f }
        ,
        { -1.0f,  1.0f,  1.0f, 1.0f }
        ,
        
        // negy
        { 1.0f, -1.0f,  1.0f, 1.0f }
        ,
        { 1.0f, -1.0f, -1.0f, 1.0f }
        ,
        { -1.0f, -1.0f,  1.0f, 1.0f }
        ,
        { -1.0f, -1.0f, -1.0f, 1.0f }
        ,
    };
    
    _skyboxVertexBuffer = [_device newBufferWithBytes:vdata length:sizeof(vdata) options:0];
    [_skyboxVertexBuffer setLabel:@"skybox vertices"];
    
    // set up icosahedron for point lights
    float X = 0.5 / Utilities::inscribe;
    float Z = X * (1.0 + sqrtf(5.0)) / 2.0;
    float lightVdata[12][4] =
    {
        { -X, 0.0, Z, 1.0f }
        ,
        { X, 0.0, Z, 1.0f }
        ,
        { -X, 0.0, -Z, 1.0f }
        ,
        { X, 0.0, -Z, 1.0f }
        ,
        { 0.0, Z, X, 1.0f }
        ,
        { 0.0, Z, -X, 1.0f }
        ,
        { 0.0, -Z, X, 1.0f }
        ,
        { 0.0, -Z, -X, 1.0f }
        ,
        { Z, X, 0.0, 1.0f }
        ,
        { -Z, X, 0.0, 1.0f }
        ,
        { Z, -X, 0.0, 1.0f }
        ,
        { -Z, -X, 0.0, 1.0f }
    };
    unsigned short tindices[20][3] =
    {
        { 0, 1, 4 }
        ,
        { 0, 4, 9 }
        ,
        { 9, 4, 5 }
        ,
        { 4, 8, 5 }
        ,
        { 4, 1, 8 }
        ,
        { 8, 1, 10 }
        ,
        { 8, 10, 3 }
        ,
        { 5, 8, 3 }
        ,
        { 5, 3, 2 }
        ,
        { 2, 3, 7 }
        ,
        { 7, 3, 10 }
        ,
        { 7, 10, 6 }
        ,
        { 7, 6, 11 }
        ,
        { 11, 6, 0 }
        ,
        { 0, 6, 1 }
        ,
        { 6, 10, 1 }
        ,
        { 9, 11, 0 }
        ,
        { 9, 2, 11 }
        ,
        { 9, 5, 2 }
        ,
        { 7, 11, 2 }
    };
    
    _lightModelVertexBuffer = [_device newBufferWithBytes:lightVdata length:sizeof(lightVdata) options:0];
    [_lightModelVertexBuffer setLabel:@"light model vertices"];
    _lightModelIndexBuffer = [_device newBufferWithBytes:tindices length:sizeof(tindices) options:0];
    [_lightModelIndexBuffer setLabel:@"light model indices"];
    
    //Constant Buffers
    _clearColorBuffer1 = [_device newBufferWithBytes:&((float&)_clear_color_buffers) length:sizeof(_clear_color_buffers) options:0];
    [_clearColorBuffer1 setLabel:@"clear color buffer 1"];
    _clearColorBuffer2 = [_device newBufferWithBytes:&((float&)_clear_color_buffers.light_buffer_clear_color.x) length:sizeof(_clear_color_buffers.light_buffer_clear_color) options:0];
    [_clearColorBuffer2 setLabel:@"clear color buffer 2"];
    
    //Setup dynamic constant buffers
    for(int i = 0; i < _numFrames; i++)
    {
        [_zOnlyProjectionBuffers addObject: [_device newBufferWithLength: sizeof(float4x4) options:0]];
        [[_zOnlyProjectionBuffers lastObject] setLabel:@"z-only projection"];
        [_skyboxMatrixBuffers addObject: [_device newBufferWithLength: sizeof(float4x4) options:0]];
        [[_skyboxMatrixBuffers lastObject] setLabel:@"skybox matrix"];
        [_modelMatricesBuffers addObject: [_device newBufferWithLength: sizeof(ModelMatrices) options:0]];
        [[_modelMatricesBuffers lastObject] setLabel:@"model matrices"];
        [_lightModelMatrixBuffers addObject: [_device newBufferWithLength: sizeof(LightModelMatrices)* _fairyCount options:0]];
        [[_lightModelMatrixBuffers lastObject] setLabel:@"light model matrices"];
        [_lightDataBuffers addObject: [_device newBufferWithLength: sizeof(LightFragmentInputs)*(_fairyCount + 1) options:0]];
        [[_lightDataBuffers lastObject] setLabel:@"light fragment inputs"];
        [_sunDataBuffers addObject: [_device newBufferWithLength: sizeof(MaterialSunData) options:0]];
        [[_sunDataBuffers lastObject] setLabel:@"sun data"];
        [_fairySpriteBuffers addObject: [_device newBufferWithLength: sizeof(float4x4) options:0]];
        [[_fairySpriteBuffers lastObject] setLabel:@"fairy sprite transform"];
    }
    
    //Load other model data and textures
    bundlePath = [bundle pathForResource:@"skybox" ofType:@"png"];
    _skyboxTexture = [self loadCubeTextureWithName:[bundlePath UTF8String]];
    [_skyboxTexture setLabel:@"skybox"];
    
    bundlePath = [bundle pathForResource:@"fairy" ofType:@"png"];
    _fairyTexture = [self load2DTextureWithName:[bundlePath UTF8String] pixelFormat:MTLPixelFormatR8Unorm];
    [_fairyTexture setLabel:@"fairy"];
    
    [self loadModel];
}

- (id<MTLTexture>)load2DTextureWithName:(const char *)name pixelFormat:(MTLPixelFormat) format
{
    NSString *hashKey = [NSString stringWithFormat:@"%s@%d", name, (int)format];
    id<MTLTexture> texture = _texture2DCache[hashKey];
    if (texture)
    {
        return texture;
    }
    
    ImageInfo tex_info;
    CreateImageInfo(name, tex_info);
    
    if (tex_info.bitmapData == NULL) return nil;
    
    if (tex_info.hasAlpha == false && tex_info.bitsPerPixel >= 24)
    {
        RGB8ImageToRGBA8(&tex_info);
    }
    
    texture =[_device newTextureWithDescriptor: [MTLTextureDescriptor texture2DDescriptorWithPixelFormat: format width: tex_info.width height: tex_info.height mipmapped: NO]];
    
    [texture replaceRegion:MTLRegionMake2D(0, 0, tex_info.width, tex_info.height)
               mipmapLevel:0
                 withBytes:tex_info.bitmapData
               bytesPerRow:tex_info.width * tex_info.bitsPerPixel / 8];
    
    free(tex_info.bitmapData);
    
    _texture2DCache[hashKey] = texture;
    
    return texture;
}

- (id<MTLTexture>)loadCubeTextureWithName:(const char *)name
{
    ImageInfo tex_info;
    CreateImageInfo(name, tex_info);
    
    if (tex_info.bitmapData == NULL) return nil;
    
    if (tex_info.hasAlpha == 0)
    {
        RGB8ImageToRGBA8(&tex_info);
    }
    
    unsigned Npixels = tex_info.width * tex_info.width;
    id<MTLTexture> texture = [_device newTextureWithDescriptor: [MTLTextureDescriptor textureCubeDescriptorWithPixelFormat: MTLPixelFormatRGBA8Unorm size: tex_info.width mipmapped: NO]];
    
    for (int i = 0; i < 6; i++)
    {
        [texture replaceRegion:MTLRegionMake2D(0, 0, tex_info.width, tex_info.width)
                   mipmapLevel:0
                         slice:i
                     withBytes:(uint8_t *)(tex_info.bitmapData) + (i * Npixels * 4)
                   bytesPerRow:4 * tex_info.width
                 bytesPerImage:Npixels * 4];
    }
    
    free(tex_info.bitmapData);
    
    return texture;
}

- (void)loadModel
{
    if (_structureModelGroup)
    {
        NSLog(@"IndexData length (bytes): %lu", (unsigned long)[[_structureModelGroup indexData] length]);
        NSLog(@"BytesPerIndex: %lu", [_structureModelGroup bytesPerIndex]);
        NSLog(@"IndexData count: %lu", [_structureModelGroup indexCount]);
        
        
        int i = 0;
        for (AAPLObjMaterialUsage *materialUsage in [_structureModelGroup materialUsages])
        {
            NSLog(@"MaterialUsage #%d: location: %lu, length: %lu",
                  i,
                  (unsigned long)[materialUsage indexRange].location,
                  (unsigned long)[materialUsage indexRange].length);
            
            if ([[materialUsage material] diffuseMapName])
            {
                NSString *diffuseMapResourceNameAndType = [[materialUsage material] diffuseMapName];
                NSArray *compAry = [diffuseMapResourceNameAndType componentsSeparatedByString: @"."];
                NSBundle *bundle = [NSBundle mainBundle];
                NSString *bundlePath = [bundle pathForResource: [compAry objectAtIndex: 0] ofType: [compAry objectAtIndex: 1]];
                id<MTLTexture> texture = [self load2DTextureWithName:[bundlePath UTF8String] pixelFormat:MTLPixelFormatRGBA8Unorm];
                [texture setLabel:[[bundlePath lastPathComponent] stringByDeletingPathExtension]];
                [_structureModelGroupDiffuseTextures addObject: texture];
            }
            
            if ([[materialUsage material] specularMapName])
            {
                NSString *specularMapResourceNameAndType = [[materialUsage material] specularMapName];
                NSArray *compAry = [specularMapResourceNameAndType componentsSeparatedByString: @"."];
                NSBundle *bundle = [NSBundle mainBundle];
                NSString *bundlePath = [bundle pathForResource: [compAry objectAtIndex: 0] ofType: [compAry objectAtIndex: 1]];
                id<MTLTexture> texture = [self load2DTextureWithName:[bundlePath UTF8String] pixelFormat:MTLPixelFormatRGBA8Unorm];
                [texture setLabel:[[bundlePath lastPathComponent] stringByDeletingPathExtension]];
                [_structureModelGroupSpecularTextures addObject: texture];
            }
            
            if ([[materialUsage material] bumpMapName])
            {
                NSString *bumpMapResourceNameAndType = [[materialUsage material] bumpMapName];
                NSArray *compAry = [bumpMapResourceNameAndType componentsSeparatedByString: @"."];
                NSBundle *bundle = [NSBundle mainBundle];
                NSString *bundlePath = [bundle pathForResource: [compAry objectAtIndex: 0] ofType: [compAry objectAtIndex: 1]];
                id<MTLTexture> texture = [self load2DTextureWithName:[bundlePath UTF8String] pixelFormat:MTLPixelFormatRGBA8Unorm];
                [texture setLabel:[[bundlePath lastPathComponent] stringByDeletingPathExtension]];
                [_structureModelGroupBumpTextures addObject: texture];
                
            }
            i++;
        }
        
    } else
    {
        NSLog(@"Failed to find group");
    }
}

#pragma mark RENDER

- (void)render:(AAPLView *)view
{
    dispatch_semaphore_wait(_inflight_semaphore, DISPATCH_TIME_FOREVER);
    
    // create a new command buffer for each renderpass to the current drawable
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // 1st pass (shadow depth map pass)
    [self renderShadowBufferForTime:_frameTime commandBuffer:commandBuffer];

    // ------ Begin 2nd pass (gbuffer pass) ------- //
    
    //Create main encoder used for gbuffer and light buffer
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:view.renderPassDescriptor];
    [encoder pushDebugGroup:@"g-buffer pass"];
    encoder.label = @"g-buffer";

    [encoder setDepthStencilState: _shadowDepthStencilState];
    
    //GBuffer and lighting render
    [self renderGBufferForTime:_frameTime renderEncoder:encoder];
    [self renderLightBufferForTime:_frameTime renderEncoder:encoder];
    
    //Combine the gBuffers for final lit scene (with sun)
    
    [encoder pushDebugGroup:@"sun"];
    [encoder setRenderPipelineState: _composition_pipeline];
    [encoder setCullMode: MTLCullModeNone];
    [encoder setFragmentBuffer: _sunDataBuffers[_currFrameIndex] offset: 0 atIndex: 0];
    
    [encoder setDepthStencilState: _compositionDepthState];
    [encoder setStencilReferenceValue: 128];
    [self drawQuadWithRect:encoder offset:0 useTexture:false];
    
    // end sun
    [encoder popDebugGroup];

    //Draw Sprites on top of lit scene
    
    [encoder pushDebugGroup:@"fairy sprites"];
    [encoder setRenderPipelineState: _fairy_pipeline];
    [encoder setDepthStencilState: _noDepthStencilState];
    [encoder setCullMode: MTLCullModeNone];
    
    [encoder setVertexBuffer: _lightDataBuffers[_currFrameIndex] offset: 0 atIndex: 0];
    [encoder setVertexBuffer: _fairySpriteBuffers[_currFrameIndex] offset: 0 atIndex: 1];
    
    [encoder setFragmentTexture: _fairyTexture atIndex: 0];
    [encoder setFragmentBuffer: _spriteBuffer offset: 0 atIndex: 0];
    
    [encoder drawPrimitives: MTLPrimitiveTypePoint vertexStart: 0 vertexCount: _fairyCount];
    
    // end fairy sprites
    [encoder popDebugGroup];

    // End 2nd pass (Gbuffer Pass)
    [encoder popDebugGroup];
    [encoder endEncoding];
    
    __block dispatch_semaphore_t block_sema = _inflight_semaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(block_sema);
    }];
    
    _currFrameIndex = (_currFrameIndex + 1)  % _numFrames;
    
    // schedule a present once the framebuffer is complete
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

- (void)drawQuadWithRect:(id<MTLRenderCommandEncoder>) encoder offset:(int)quadOffset useTexture:(bool)textured
{
    
    int offset = quadOffset * sizeof(float) * 12;
    
    [encoder setVertexBuffer: _quadPositionBuffer offset: offset atIndex: 0];
    
    if (textured)
    {
        [encoder setVertexBuffer: _quadTexcoordBuffer offset: 0 atIndex: 1];
    }
    
    [encoder drawPrimitives: MTLPrimitiveTypeTriangle vertexStart: 0 vertexCount: 6];
}

- (void)renderShadowBufferForTime:(CFTimeInterval) time commandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:_shadowRenderPassDescriptor];
    [encoder pushDebugGroup:@"shadow buffer pass"];
    encoder.label = @"shadow buffer";

    // setup encoder state
    [encoder setRenderPipelineState: _shadow_render_pipeline];
    [encoder setDepthStencilState: _shadowDepthStencilState];
    [encoder setCullMode: MTLCullModeFront];
    [encoder setDepthBias: 0.01 slopeScale: 1.0f clamp: 0.01];
    
    [encoder setVertexBuffer: _zOnlyProjectionBuffers[_currFrameIndex] offset: 0 atIndex: 1];
    [encoder setVertexBuffer: _structureVertexBuffer offset: 0 atIndex: 0];
    
    for (AAPLObjMaterialUsage *materialUsage in [_structureModelGroup materialUsages])
    {
        
        [encoder drawIndexedPrimitives: MTLPrimitiveTypeTriangle indexCount: [materialUsage indexRange].length indexType: _structureModelGroupIndexDataType indexBuffer: _structureIndexBuffer indexBufferOffset: [materialUsage indexRange].location * [_structureModelGroup bytesPerIndex]];
    }
    
    [encoder popDebugGroup];
    [encoder endEncoding];
}

- (void)renderGBufferForTime:(CFTimeInterval)time renderEncoder:(id<MTLRenderCommandEncoder>) encoder
{
    [encoder pushDebugGroup:@"skybox"];
    
    // Render the skybox and mark in stencil to not process these pixels in subsequent passes
    [encoder setRenderPipelineState: _skybox_render_pipeline];
    
    [encoder setVertexBuffer: _skyboxVertexBuffer offset: 0 atIndex: 0];
    [encoder setVertexBuffer: _skyboxMatrixBuffers[_currFrameIndex] offset: 0 atIndex: 1];
    
    [encoder setFragmentTexture: _skyboxTexture atIndex: 0];
    
    //Bind pixel constants
    [encoder setFragmentBuffer: _clearColorBuffer1 offset: 0 atIndex: 0];
    
    for (int i = 0; i < 6; ++i)
        [encoder drawPrimitives: MTLPrimitiveTypeTriangleStrip vertexStart: i * 4 vertexCount: 4];

    // end skybox
    [encoder popDebugGroup];
    
    //GBuffer Render
    [encoder pushDebugGroup:@"structure"];

    [encoder setRenderPipelineState: _gbuffer_render_pipeline];
    [encoder setCullMode: MTLCullModeBack];
    [encoder setDepthStencilState: _gBufferDepthStencilState];
    [encoder setStencilReferenceValue: 128];
    
    [encoder setVertexBuffer: _structureVertexBuffer offset: 0 atIndex: 0];
    [encoder setVertexBuffer: _modelMatricesBuffers[_currFrameIndex]  offset: 0 atIndex: 1];
    
    [encoder setFragmentBuffer: _clearColorBuffer2 offset: 0 atIndex: 0];
    
    NSInteger i = 0;
    for (AAPLObjMaterialUsage *materialUsage in [_structureModelGroup materialUsages])
    {
        
        [encoder setFragmentTexture: _structureModelGroupBumpTextures[i] atIndex: 0];
        [encoder setFragmentTexture: _structureModelGroupDiffuseTextures[i] atIndex: 1];
        [encoder setFragmentTexture: _structureModelGroupSpecularTextures[i] atIndex: 2];
        [encoder setFragmentTexture: _shadow_texture atIndex: 3];
        i++;
        
        [encoder drawIndexedPrimitives: MTLPrimitiveTypeTriangle indexCount: [materialUsage indexRange].length indexType: _structureModelGroupIndexDataType indexBuffer: _structureIndexBuffer indexBufferOffset: [materialUsage indexRange].location * [_structureModelGroup bytesPerIndex]];
    }
    
    // end structure
    [encoder popDebugGroup];
}

- (void)renderLightBufferForTime:(CFTimeInterval)time renderEncoder:(id<MTLRenderCommandEncoder>) encoder
{
    [encoder pushDebugGroup:@"light accumulation"];
    
    float near = 0.1f;

    id<MTLBuffer> lightModelMatricesBuffer = _lightModelMatrixBuffers[_currFrameIndex];
    id<MTLBuffer> lightDataBuffer = _lightDataBuffers[_currFrameIndex];
    
    LightFragmentInputs *gpuLights = (LightFragmentInputs *)[lightDataBuffer contents];
    LightModelMatrices *matrixData = (LightModelMatrices *)[lightModelMatricesBuffer contents];
    
    LightModelMatrices fairyMatrices[kNumFairies];
    float4x4 structureCameraMatrix = [self cameraMatrixForTime:_frameTime rateOfRotation:_structureCameraRotationRate];
    
    // update the lights
    [self updateLightsForTime:_frameTime];
    
    for (NSInteger i = 0; i < _fairyCount; i++)
    {
        // update each light
        LightModelMatrices &matrixState = fairyMatrices[i];
        
        matrixState.mvMatrix = structureCameraMatrix;
        float4x4 tempMatrix = translate(_lightData[i].light_position[0], _lightData[i].light_position[1], _lightData[i].light_position[2]);
        matrixState.mvMatrix = matrixState.mvMatrix * tempMatrix;
        
        tempMatrix = scale(_lightData[i].light_color_radius[3], _lightData[i].light_color_radius[3], _lightData[i].light_color_radius[3]);
        matrixState.mvMatrix = matrixState.mvMatrix * tempMatrix;
        matrixState.mvpMatrix = _projectionMatrix;
        matrixState.mvpMatrix = matrixState.mvpMatrix * matrixState.mvMatrix;
        
        memcpy(matrixData + i, &matrixState, sizeof(LightModelMatrices));
        
        _lightData[i].view_light_position =  structureCameraMatrix * _lightData[i].light_position;
        memcpy(gpuLights + i, &_lightData[i], sizeof(LightFragmentInputs));
        
        [encoder pushDebugGroup:@"stencil"];
        [encoder setRenderPipelineState: _light_mask_pipeline];
        
        // increment stencil on fragments in front of the backside of the volume
        [encoder setDepthStencilState: _lightMaskStencilState];
        [encoder setStencilReferenceValue: 128];
        [encoder setCullMode: MTLCullModeFront];
        
        [encoder setVertexBuffer: _lightModelVertexBuffer offset: 0 atIndex: 0];
        [encoder setVertexBuffer: lightModelMatricesBuffer offset: i * sizeof(LightModelMatrices) atIndex: 1];
        [encoder drawIndexedPrimitives: MTLPrimitiveTypeTriangle indexCount: 60 indexType: MTLIndexTypeUInt16 indexBuffer: _lightModelIndexBuffer indexBufferOffset: 0];
        
        // end stencil
        [encoder popDebugGroup];
        
        [encoder pushDebugGroup:@"volume"];
        // shade the front face if it won't clip through the front plane, otherwise use the back plane
        [encoder setRenderPipelineState: _light_color_pipeline];
        
        bool clip = (_lightData[i].light_position[2] + (_lightData[i].light_color_radius[3] * Utilities::circumscribe / Utilities::inscribe)) < near;
        if (clip)
        {
            [encoder setDepthStencilState: _lightColorStencilStateNoDepth];
            [encoder setCullMode: MTLCullModeFront];
        } else
        {
            [encoder setDepthStencilState: _lightColorStencilState];
            [encoder setCullMode: MTLCullModeBack];
        }
        
        [encoder setStencilReferenceValue: 128];
        
        [encoder setVertexBuffer: _lightModelVertexBuffer offset: 0 atIndex: 0];
        [encoder setVertexBuffer: lightModelMatricesBuffer offset: i * sizeof(LightModelMatrices) atIndex: 1];
        
        [encoder setFragmentBuffer: lightDataBuffer offset: i * sizeof(LightFragmentInputs) atIndex: 0];
        
        [encoder drawIndexedPrimitives: MTLPrimitiveTypeTriangle indexCount: 60 indexType: MTLIndexTypeUInt16 indexBuffer: _lightModelIndexBuffer indexBufferOffset: 0];
        
        // end light volume
        [encoder popDebugGroup];
    }
    
    // light accumulation
    [encoder popDebugGroup];
}

- (void)reshape:(AAPLView *)view
{
    // called by the view when orientation changes or layer is updated
    
    float aspect = fabs(view.bounds.size.width / view.bounds.size.height);
    _projectionMatrix = perspective_fov(75.0f, aspect, 0.1f, 25.0f);
}

#pragma mark UPDATE

- (void)update:(AAPLViewController *)controller
{
    _frameTime += controller.timeSinceLastDraw;
    
    // update shadow matrix for shadow pass
    float4x4 shadowMatrix = [self shadowMatrixForTime:_frameTime];
    float4x4 scaleMatrix = scale(_structureScale, _structureScale, _structureScale);
    shadowMatrix = shadowMatrix * scaleMatrix;
    memcpy([_zOnlyProjectionBuffers[_currFrameIndex] contents], &shadowMatrix, sizeof(float4x4));
    
    // -------- skybox updates -------- //
    float4x4 skyboxCameraMatrix = [self cameraMatrixForTime:_frameTime rateOfRotation:_skyboxCameraRotationRate];
    scaleMatrix = scale(_skyboxScale, _skyboxScale, _skyboxScale);
    skyboxCameraMatrix = skyboxCameraMatrix * scaleMatrix;
    
    // shadow matrix buffer
    float4x4 skyboxModelViewProjectionMatrix = _projectionMatrix;
    skyboxModelViewProjectionMatrix = skyboxModelViewProjectionMatrix * skyboxCameraMatrix;
    memcpy([_skyboxMatrixBuffers[_currFrameIndex] contents], &skyboxModelViewProjectionMatrix, sizeof(float4x4));
    
    // calculate camera matrix
    float4x4 cameraMatrix = [self cameraMatrixForTime:_frameTime rateOfRotation:_structureCameraRotationRate];
    float3x4 normalMatrix(cameraMatrix.columns[0], cameraMatrix.columns[1], cameraMatrix.columns[2]);

    // ------- gBuffer structure updates ------- //
    ModelMatrices* gBuffermatrixState = (ModelMatrices*)[_modelMatricesBuffers[_currFrameIndex] contents];
    gBuffermatrixState->mvMatrix = cameraMatrix;
    scaleMatrix = scale(_structureScale, _structureScale, _structureScale);
    gBuffermatrixState->mvMatrix = gBuffermatrixState->mvMatrix * scaleMatrix;
    
    //Inverse and Transpose the model matrix for the normal matrix....but if it's just a rotation and uniform scale
    //Inverse is the transpose so just copy it over.
    gBuffermatrixState->normalMatrix = gBuffermatrixState->mvMatrix;
    gBuffermatrixState->mvpMatrix = _projectionMatrix;
    gBuffermatrixState->mvpMatrix = gBuffermatrixState->mvpMatrix * gBuffermatrixState->mvMatrix;
    
    gBuffermatrixState->shadowMatrix = translate(0.5f, 0.5f, 0.0f);
    gBuffermatrixState->shadowMatrix = gBuffermatrixState->shadowMatrix * scale(0.5f, -0.5f, 1.0f);
    gBuffermatrixState->shadowMatrix = gBuffermatrixState->shadowMatrix * [self shadowMatrixForTime:_frameTime];
    gBuffermatrixState->shadowMatrix = gBuffermatrixState->shadowMatrix * scaleMatrix;
    
    // ------- sun updates ------- //
    MaterialSunData* sunData = (MaterialSunData*)[_sunDataBuffers[_currFrameIndex] contents];
    float3 direction = [self sunDirectionForTime:_frameTime];
    sunData->sunDirection = {direction.x, direction.y, direction.z, 0.0f};
    sunData->sunColor = {1.0f, 0.875f, 0.75f, 1.0f};
    sunData->sunColor = sunData->sunColor * sunData->sunDirection.y;
    sunData->sunDirection = normalMatrix * sunData->sunDirection.xyz;
    
    // ------- fairy sprites ------- //
    float4x4 mvpMatrix = _projectionMatrix;
    mvpMatrix = mvpMatrix * cameraMatrix;
    memcpy([_fairySpriteBuffers[_currFrameIndex] contents], &mvpMatrix, sizeof(float4x4));
}

- (void)updateLightsForTime:(CFTimeInterval) time
{
    NSInteger i;
    
    for (i = 0; i < kNumFairies / 2; i++)
    {
        double fairyTime = time / _fairySpeeds[i] + _fairyPhases[i];
        fairyTime -= floor(fairyTime);
        
        float fairyAlpha = MIN((0.5 - fabs(0.5f - fairyTime)) * 8.0f, 1.0f);
        float r = 0.5 + 2.0 * powf(fairyTime, 5.0f);
        
        _lightData[i].light_position = {cosf(_fairyAngles[i]) * r, (float)(fairyTime * 6.0f), sinf(_fairyAngles[i]) * r, 1.0f};
        _lightData[i].light_color_radius = _fairyColors[i] *  fairyAlpha;
        _lightData[i].light_color_radius[3] = kLightRadius;
    }
    
    for (; i < kNumFairies; i++)
    {
        float r = 2.0 + 0.85 * cos(time / (4.0 * _fairySpeeds[i]));
        float t = time * copysignf(fabsf(_fairyPhases[i]) + 0.25f, _fairyPhases[i] - 0.5) / 4.0f;
        
        _lightData[i].light_position = {cosf(t) * r, 1.5f, sinf(t) * r, 1.0f};
        _lightData[i].light_color_radius = _fairyColors[i];
        _lightData[i].light_color_radius[3] = kLightRadius;
    }
    
    _lightData[i].light_position = {0.0f, 2.0f, 2.0f, 1.0f};
    _lightData[i].light_color_radius = {1.0f, 0.875f, 0.75f, 1.0f};
    _lightData[i].light_color_radius[3] = 5.0f;
}

- (float3)sunDirectionForTime:(CFTimeInterval)time
{
    double sunTime = (time / 22.5f);
    sunTime -= floor(sunTime);
    sunTime = MIN(sunTime * 1.5, 1.0);
    
    float offAngle = Utilities::DegreesToRadians(-105.0f);
    float pathAngle = Utilities::DegreesToRadians(-sunTime * 180.0f);
    float pathScale = sinf(offAngle);
    
    return {pathScale * cosf(pathAngle), pathScale * sinf(pathAngle), cosf(offAngle)};
}

- (float4x4)cameraMatrixForTime:(CFTimeInterval)time  rateOfRotation:(float) rotationRate
{
    
    float4x4 cameraMatrix = translate(0.0f, -2.0f, 6.0f);
    float4x4 rotationMatrix = rotate(-15.0f, 1.0f, 0.0f, 0.0f);
    
    cameraMatrix = cameraMatrix * rotationMatrix;
    rotationMatrix = rotate(-time * rotationRate, 0.0f, 1.0f, 0.0f);
    cameraMatrix = cameraMatrix * rotationMatrix;
    
    return cameraMatrix;
    
}

- (float4x4)shadowMatrixForTime:(CFTimeInterval) time
{
    float3 sunLocation = [self sunDirectionForTime:time] * 12.0f;
    
    float4x4 cameraMatrix = lookAt(sunLocation, (float3){0.0f, 0.0f, 0.0f}, (float3){0.0f, 1.0f, 0.0f});
    float4x4 orthoMatrix = ortho2d_oc(-6.5f, 6.5f, -6.5f, 6.5f, 5.5f, 18.5f);
    
    return  orthoMatrix * cameraMatrix;
}

- (void)controller:(AAPLViewController *)controller willPause:(BOOL)pause
{
    // timer is suspended/resumed
    // Can do any non-rendering related background work here when suspended
}


@end
