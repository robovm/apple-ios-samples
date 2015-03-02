/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import <string>

#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#import "AAPLTransforms.h"
#import "AAPLTexture.h"
#import "AAPLQuad.h"
#import "AAPLView.h"

#import "AAPLRenderer.h"

static const float kUIInterfaceOrientationLandscapeAngle = 35.0f;
static const float kUIInterfaceOrientationPortraitAngle  = 50.0f;

static const float kPrespectiveNear = 0.1f;
static const float kPrespectiveFar  = 100.0f;

static const uint32_t kSzSIMDFloat4x4         = sizeof(simd::float4x4);
static const uint32_t kSzBufferLimitsPerFrame = kSzSIMDFloat4x4;

static const uint32_t kInFlightCommandBuffers = 3;

@implementation AAPLRenderer
{
@private
    // Interface Orientation
    UIInterfaceOrientation  mnOrientation;
    
    // Renderer globals
    id <MTLCommandQueue>       m_CommandQueue;
    id <MTLLibrary>            m_ShaderLibrary;
    id <MTLDepthStencilState>  m_DepthState;
    
    // textured Quad
    AAPLTexture                   *mpInTexture;
    id <MTLRenderPipelineState>    m_PipelineState;
    
    // Quad representation
    AAPLQuad *mpQuad;
    
    // App control
    dispatch_semaphore_t  m_InflightSemaphore;
    
    // Dimensions
    CGSize  m_Size;
    
    // Viewing matrix is derived from an eye point, a reference point
    // indicating the center of the scene, and an up vector.
    simd::float4x4 m_LookAt;
    
    // Translate the object in (x,y,z) space.
    simd::float4x4 m_Translate;
    
    // Quad transform buffers
    simd::float4x4  m_Transform;
    id <MTLBuffer>  m_TransformBuffer;
}


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        // initialize properties
        _sampleCount             = 1;
        _depthPixelFormat        = MTLPixelFormatDepth32Float;
        _stencilPixelFormat      = MTLPixelFormatInvalid;
        _constantDataBufferIndex = 0;
        
        // create a default system device
        _device = MTLCreateSystemDefaultDevice();
        
        if(!_device)
        {
            NSLog(@">> ERROR: Failed creating a device!");
            
            // assert here becuase if the default system device isn't
            //  created, then we shouldn't continue
            assert(0);
        } // if

        // create a new command queue
        m_CommandQueue = [_device newCommandQueue];
        
        if(!m_CommandQueue)
        {
            NSLog(@">> ERROR: Failed creating a command queue!");
            
            // assert here becuase if the command queue isn't created,
            // then we shouldn't continue
            assert(0);
        } // if
        
        m_ShaderLibrary = [_device newDefaultLibrary];
        
        if(!m_ShaderLibrary)
        {
            NSLog(@">> ERROR: Failed creating a default shader library!");
            
            // assert here becuase if the shader libary isn't loading,
            // then we shouldn't contiue
            assert(0);
        } // if
        
        m_InflightSemaphore = dispatch_semaphore_create(kInFlightCommandBuffers);
    }
    
    return self;
}

- (void)cleanup
{
    m_PipelineState   = nil;
    m_ShaderLibrary   = nil;
    m_TransformBuffer = nil;
    m_DepthState      = nil;
    m_CommandQueue    = nil;
    mpInTexture       = nil;
    mpQuad            = nil;
}

#pragma mark Setup

- (void)configure:(AAPLView *)view
{
    view.depthPixelFormat   = _depthPixelFormat;
    view.stencilPixelFormat = _stencilPixelFormat;
    view.sampleCount        = _sampleCount;
    
    if(![self preparePipelineState])
    {
        NSLog(@">> ERROR: Failed creating a depth stencil state descriptor!");
        
        assert(0);
    }
    
    if(![self prepareTexturedQuad:@"Default" ext:@"jpg"])
    {
        NSLog(@">> ERROR: Failed creating a textured quad!");
        
        assert(0);
    }
    
    if(![self prepareDepthStencilState])
    {
        NSLog(@">> ERROR: Failed creating a depth stencil state!");
        
        assert(0);
    }
    
    if(![self prepareTransformBuffer])
    {
        NSLog(@">> ERROR: Failed creating a transform buffer!");
        
        assert(0);
    }
    
    // Default orientation is unknown
    mnOrientation = UIInterfaceOrientationUnknown;
    
    // Create linear transformation matrices
    [self prepareTransforms];
}

- (BOOL) preparePipelineState
{
    // get the fragment function from the library
    id <MTLFunction> fragmentProgram = [m_ShaderLibrary newFunctionWithName:@"texturedQuadFragment"];
    
    if(!fragmentProgram)
        NSLog(@">> ERROR: Couldn't load fragment function from default library");
    
    // get the vertex function from the library
    id <MTLFunction> vertexProgram = [m_ShaderLibrary newFunctionWithName:@"texturedQuadVertex"];
    
    if(!vertexProgram)
        NSLog(@">> ERROR: Couldn't load vertex function from default library");
    
    //  create a pipeline state for the quad
    MTLRenderPipelineDescriptor *pQuadPipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
    
    if(!pQuadPipelineStateDescriptor)
    {
        NSLog(@">> ERROR: Failed creating a pipeline state descriptor!");
        
        return NO;
    } // if
    
    pQuadPipelineStateDescriptor.depthAttachmentPixelFormat      = _depthPixelFormat;
    pQuadPipelineStateDescriptor.stencilAttachmentPixelFormat    = MTLPixelFormatInvalid;
    pQuadPipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    pQuadPipelineStateDescriptor.sampleCount      = _sampleCount;
    pQuadPipelineStateDescriptor.vertexFunction   = vertexProgram;
    pQuadPipelineStateDescriptor.fragmentFunction = fragmentProgram;
    
    NSError *pError = nil;
    m_PipelineState = [_device newRenderPipelineStateWithDescriptor:pQuadPipelineStateDescriptor
                                                               error:&pError];
    if(!m_PipelineState)
    {
        NSLog(@">> ERROR: Failed acquiring pipeline state descriptor: %@", pError);
        
        return NO;
    } // if
    
    return YES;
} // preparePipelineState

- (BOOL) prepareDepthStencilState
{
    MTLDepthStencilDescriptor *pDepthStateDesc = [MTLDepthStencilDescriptor new];
    
    if(!pDepthStateDesc)
    {
        NSLog(@">> ERROR: Failed creating a depth stencil descriptor!");
        
        return NO;
    } // if
    
    pDepthStateDesc.depthCompareFunction = MTLCompareFunctionAlways;
    pDepthStateDesc.depthWriteEnabled    = YES;
    
    m_DepthState = [_device newDepthStencilStateWithDescriptor:pDepthStateDesc];
    
    if(!m_DepthState)
    {
        return NO;
    } // if
    
    return YES;
} // _prepareDepthStencilState

- (BOOL) prepareTexturedQuad:(NSString *)texStr
                         ext:(NSString *)extStr
{
    mpInTexture = [[AAPLTexture alloc] initWithResourceName:texStr
                                                  extension:extStr];
    mpInTexture.texture.label = texStr;
    
    BOOL isAcquired = [mpInTexture finalize:_device];
    if(!isAcquired)
    {
        NSLog(@">> ERROR: Failed creating an input 2d texture!");
        
        return NO;
    } // if
    
    m_Size.width  = mpInTexture.width;
    m_Size.height = mpInTexture.height;
    
    mpQuad = [[AAPLQuad alloc] initWithDevice:_device];
    
    if(!mpQuad)
    {
        NSLog(@">> ERROR: Failed creating a quad object!");
        
        return NO;
    } // if
    
    mpQuad.size = m_Size;
    
    return YES;
} // _prepareTexturedQuad

- (BOOL) prepareTransformBuffer
{
    // allocate regions of memory for the constant buffer
    m_TransformBuffer = [_device newBufferWithLength:kSzBufferLimitsPerFrame
                                              options:0];
    
    if(!m_TransformBuffer)
    {
        return NO;
    } // if
    
    m_TransformBuffer.label = @"TransformBuffer";
    
    return YES;
} // _prepareTransformBuffer

- (void) prepareTransforms
{
    // Create a viewing matrix derived from an eye point, a reference point
    // indicating the center of the scene, and an up vector.
    simd::float3 eye    = {0.0, 0.0, 0.0};
    simd::float3 center = {0.0, 0.0, 1.0};
    simd::float3 up     = {0.0, 1.0, 0.0};
    
    m_LookAt = AAPL::Math::lookAt(eye, center, up);
    
    // Translate the object in (x,y,z) space.
    m_Translate = AAPL::Math::translate(0.0f, -0.25f, 2.0f);
} // _prepareTransforms

#pragma mark Render

- (void) encode:(id <MTLRenderCommandEncoder>)renderEncoder
{
    // set context state with the render encoder
    [renderEncoder pushDebugGroup:@"encode quad"];
    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderEncoder setDepthStencilState:m_DepthState];
    
    [renderEncoder setRenderPipelineState:m_PipelineState];
    
    [renderEncoder setVertexBuffer:m_TransformBuffer
                            offset:0
                           atIndex:2 ];
    
    [renderEncoder setFragmentTexture:mpInTexture.texture
                              atIndex:0];
    
    // Encode quad vertex and texture coordinate buffers
    [mpQuad encode:renderEncoder];
    
    // tell the render context we want to draw our primitives
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:6
                    instanceCount:1];
    
    [renderEncoder endEncoding];
    [renderEncoder popDebugGroup];
    
} // _encode

- (void)reshape:(AAPLView *)view;
{
    // To correctly compute the aspect ration determine the device
    // interface orientation.
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    // Update the quad and linear _transformation matrices, if and
    // only if, the device orientation is changed.
    if(mnOrientation != orientation)
    {
        // Update the device orientation
        mnOrientation = orientation;
        
        // Get the bounds for the current rendering layer
        mpQuad.bounds = view.layer.frame;
    
        // Based on the device orientation, set the angle in degrees
        // between a plane which passes through the camera position
        // and the top of your screen and another plane which passes
        // through the camera position and the bottom of your screen.
        float dangle = 0.0f;
        
        switch(mnOrientation)
        {
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
                dangle = kUIInterfaceOrientationLandscapeAngle;
                break;
                
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationPortraitUpsideDown:
            default:
                dangle = kUIInterfaceOrientationPortraitAngle;
                break;
        } // switch
        
        // Describes a tranformation matrix that produces a perspective projection
        const float near   = kPrespectiveNear;
        const float far    = kPrespectiveFar;
        const float rangle = AAPL::Math::radians(dangle);
        const float length = near * std::tan(rangle);
        
        float right   = length/mpQuad.aspect;
        float left    = -right;
        float top     = length;
        float bottom  = -top;
        
        simd::float4x4 perspective = AAPL::Math::frustum_oc(left, right, bottom, top, near, far);
        
        // Create a viewing matrix derived from an eye point, a reference point
        // indicating the center of the scene, and an up vector.
        m_Transform = m_LookAt * m_Translate;
        
        // Create a linear _transformation matrix
        m_Transform = perspective * m_Transform;
        
        // Update the buffer associated with the linear _transformation matrix
        float *pTransform = (float *)[m_TransformBuffer contents];
        
        std::memcpy(pTransform, &m_Transform, kSzSIMDFloat4x4);
    }
}

- (void)render:(AAPLView *)view
{
    dispatch_semaphore_wait(m_InflightSemaphore, DISPATCH_TIME_FOREVER);
    
    id <MTLCommandBuffer> commandBuffer = [m_CommandQueue commandBuffer];
    
    // create a render command encoder so we can render into something
    MTLRenderPassDescriptor *renderPassDescriptor = view.renderPassDescriptor;
    if (renderPassDescriptor)
    {
        // Get a render encoder
        id <MTLRenderCommandEncoder>  renderEncoder
        = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        // Encode into a renderer
        [self encode:renderEncoder];
        
        //Dispatch the command buffer
        __block dispatch_semaphore_t dispatchSemaphore = m_InflightSemaphore;
        
        [commandBuffer addCompletedHandler:^(id <MTLCommandBuffer> cmdb){
            dispatch_semaphore_signal(dispatchSemaphore);
        }];
        
        // Present and commit the command buffer
        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
    }
    
}

// Note this method is called from the thread the main game loop is run
- (void)update:(AAPLViewController *)controller
{
    // not used in this sample
}

// called whenever the main game loop is paused, such as when the app is backgrounded
- (void)viewController:(AAPLViewController *)controller willPause:(BOOL)pause
{
    // not used in this sample
}

@end
