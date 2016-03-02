/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for instantiating and encoding of vertex and fragment stages.
 */

#import "NBodyDefaults.h"
#import "NBodyPreferences.h"

#import "MetalNBodyRenderPipeline.h"
#import "MetalNBodyRenderPassDescriptor.h"
#import "MetalNBodyFragmentStage.h"
#import "MetalNBodyVertexStage.h"

#import "MetalNBodyRenderStage.h"

@implementation MetalNBodyRenderStage
{
@private
    BOOL _isStaged;
    BOOL _isEncoded;
    
    NSDictionary* _globals;
    NSDictionary* _parameters;
    
    id<MTLCommandBuffer>  _cmdBuffer;
    id<MTLLibrary>        _library;
    id<MTLBuffer>         _positions;
    
    uint32_t mnParticles;
    
    MetalNBodyFragmentStage*         mpFragment;
    MetalNBodyVertexStage*           mpVertex;
    MetalNBodyRenderPassDescriptor*  mpDescriptor;
    MetalNBodyRenderPipeline*        mpPipeline;
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        _isStaged  = NO;
        _isEncoded = NO;
        
        _globals    = nil;
        _parameters = nil;
        _library    = nil;
        _cmdBuffer  = nil;
        _positions  = nil;
        
        mnParticles = NBody::Defaults::kParticles;
        
        mpDescriptor = nil;
        mpPipeline   = nil;
        mpFragment   = nil;
        mpVertex     = nil;
    } // if
    
    return self;
} // init

// N-body simulation global parameters
- (void) setGlobals:(NSDictionary *)globals
{
    if(globals && !_isStaged)
    {
        _globals = globals;
        
        mnParticles = [_globals[kNBodyParticles] unsignedIntValue];
        
        if(mpFragment)
        {
            mpFragment.globals = globals;
        } // if
    } // if
} // setParameters

// N-body parameters for simulation types
- (void) setParameters:(NSDictionary *)parameters
{
    if(parameters)
    {
        _parameters = parameters;
        
        if(mpVertex)
        {
            mpVertex.pointSz = [parameters[kNBodyPointSize] floatValue];
        } // if
    } // if
} // setParameters

// Aspect ratio
- (void) setAspect:(float)aspect
{
    if(mpVertex)
    {
        mpVertex.aspect = aspect;
    } // if
} // setAspect

// Orthographic projection configuration type
- (void) setConfig:(uint32_t)config
{
    if(mpVertex)
    {
        mpVertex.config = config;
    } // if
} // setConfig

// Update the linear transformation mvp matrix
- (void) setUpdate:(BOOL)update
{
    if(mpVertex)
    {
        mpVertex.update = update;
    } // if
} // setUpdate

// Color host pointer
- (nullable simd::float4 *) colors
{
    simd::float4* pColors = nullptr;
    
    if(mpVertex)
    {
        pColors = mpVertex.colors;
    } // if
    
    return pColors;
} // colors

- (BOOL) _acquire:(nullable id<MTLDevice>)device
{
    if(device)
    {
        if(!_library)
        {
            NSLog(@">> ERROR: Failed to instantiate a new default m_Library!");
            
            return NO;
        } // if
        
        mpVertex = [MetalNBodyVertexStage new];
        
        if(!mpVertex)
        {
            NSLog(@">> ERROR: Failed to instantiate a N-Body vertex stage object!");
            
            return NO;
        } // if
        
        mpVertex.particles = mnParticles;
        mpVertex.library   = _library;
        mpVertex.device    = device;
        
        if(!mpVertex.isStaged)
        {
            NSLog(@">> ERROR: Failed to acquire a N-Body vertex stage resources!");
            
            return NO;
        } // if
        
        mpFragment = [MetalNBodyFragmentStage new];
        
        if(!mpFragment)
        {
            NSLog(@">> ERROR: Failed to instantiate a N-Body fragment stage object!");
            
            return NO;
        } // if
        
        mpFragment.globals = _globals;
        mpFragment.library = _library;
        mpFragment.device  = device;
       
        if(!mpFragment.isStaged)
        {
            NSLog(@">> ERROR: Failed to acquire a N-Body fragment stage resources!");
            
            return NO;
        } // if
        
        mpPipeline = [MetalNBodyRenderPipeline new];
        
        if(!mpPipeline)
        {
            NSLog(@">> ERROR: Failed to instantiate a N-Body render pipeline object!");
            
            return NO;
        } // if
        
        mpPipeline.fragment = mpFragment.function;
        mpPipeline.vertex   = mpVertex.function;
        mpPipeline.device   = device;
        
        if(!mpPipeline.haveDescriptor)
        {
            NSLog(@">> ERROR: Failed to acquire a N-Body render pipeline resources!");
            
            return NO;
        } // if
        
        mpDescriptor = [MetalNBodyRenderPassDescriptor new];
        
        if(!mpDescriptor)
        {
            NSLog(@">> ERROR: Failed to instantiate a N-Body render pass descriptor object!");
            
            return NO;
        } // if
        
        return YES;
    } // if
    else
    {
        NSLog(@">> ERROR: Metal device is nil!");
    } // if
    
    return NO;
} // acquire

// Generate all the fragment, vertex and stages
- (void) acquire:(nullable id<MTLDevice>)device
{
    if(!_isStaged)
    {
        _isStaged = [self _acquire:device];
    } // if
} // acquire

- (BOOL) _encode:(nullable id<CAMetalDrawable>)drawable
{
    if(!_cmdBuffer)
    {
        NSLog(@">> ERROR: Command buffer is nil!");
        
        return NO;
    } // if
    
    if(!drawable)
    {
        NSLog(@">> ERROR: Drawable is nil!");
        
        return NO;
    } // if
    
    mpDescriptor.drawable = drawable;
    
    if(!mpDescriptor.haveTexture)
    {
        NSLog(@">> ERROR: Failed to acquire a texture from a CA drawable!");
        
        return NO;
    } // if
    
    id<MTLRenderCommandEncoder> renderEncoder
    = [_cmdBuffer renderCommandEncoderWithDescriptor:mpDescriptor.descriptor];
    
    if(!renderEncoder)
    {
        NSLog(@">> ERROR: Failed to acquire a render command encoder!");
        
        return NO;
    } // if
    
    [renderEncoder setRenderPipelineState:mpPipeline.render];
    
    mpVertex.positions  = _positions;
    mpVertex.cmdEncoder = renderEncoder;
    
    mpFragment.cmdEncoder = renderEncoder;
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypePoint
                      vertexStart:0
                      vertexCount:mnParticles
                    instanceCount:1];
    
    [renderEncoder endEncoding];
    
    return YES;
} // _encode

// Encode vertex and fragment stages
- (void) encode:(nullable id<CAMetalDrawable>)drawable
{
    _isEncoded = [self _encode:drawable];
} // encode

@end
