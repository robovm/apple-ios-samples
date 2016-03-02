/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for rendering (encoding into Metal pipeline components of) N-Body simulation and presenting the frame
 */

#import "NBodyDefaults.h"
#import "NBodyPreferences.h"

#import "MetalNBodyComputeStage.h"
#import "MetalNBodyRenderStage.h"
#import "MetalNBodyPresenter.h"

@implementation MetalNBodyPresenter
{
@private
    BOOL _haveEncoder;
    BOOL _isEncoded;
    
    NSDictionary* _globals;
    NSDictionary* _parameters;
    
    id<MTLLibrary>        m_Library;
    id<MTLCommandBuffer>  m_CmdBuffer;
    id<MTLCommandQueue>   m_CmdQueue;
    
    MetalNBodyRenderStage*   mpRender;
    MetalNBodyComputeStage*  mpCompute;
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        _haveEncoder = NO;
        _isEncoded   = NO;
        
        _globals    = nil;
        _parameters = nil;
        
        m_CmdBuffer = nil;
        m_CmdQueue  = nil;
        m_Library   = nil;
        
        mpRender  = nil;
        mpCompute = nil;
    } // if
    
    return self;
} // init

// N-body simulation global parameters
- (void) setGlobals:(NSDictionary *)globals
{
    _globals = globals;
    
    if(mpRender)
    {
        mpRender.globals = _globals;
    } // if
} // setParameters

// N-body parameters for simulation types
- (void) setParameters:(NSDictionary *)parameters
{
    _parameters = parameters;
    
    if(mpRender)
    {
        mpRender.parameters = _parameters;
    } // if
} // setParameters

// Aspect ratio
- (void) setAspect:(float)aspect
{
    if(mpRender)
    {
        mpRender.aspect = aspect;
    } // if
} // setAspect

// Orthographic projection configuration type
- (void) setConfig:(uint32_t)config
{
    if(mpRender)
    {
        mpRender.config = config;
    } // if
} // setConfig

// Update the linear transformation mvp matrix
- (void) setUpdate:(BOOL)update
{
    if(mpRender)
    {
        mpRender.update = update;
    } // if
} // setUpdate

// Color host pointer
- (nullable simd::float4 *) colors
{
    simd::float4* pColors = nullptr;
    
    if(mpRender)
    {
        pColors = mpRender.colors;
    } // if

    return pColors;
} // colors

// Position host pointer
- (nullable simd::float4 *) position
{
    simd::float4* pPosition = nullptr;
    
    if(mpCompute)
    {
        pPosition = mpCompute.position;
    } // if
    
    return pPosition;
} // position

// Velocity host pointer
- (nullable simd::float4 *) velocity
{
    simd::float4* pVelocity = nullptr;
    
    if(mpCompute)
    {
        pVelocity = mpCompute.velocity;
    } // if
    
    return pVelocity;
} // velocity

- (BOOL) _acquire:(nullable id<MTLDevice>)device
{
    if(device)
    {
        m_Library = [device newDefaultLibrary];
        
        if(!m_Library)
        {
            NSLog(@">> ERROR: Failed to instantiate a new default m_Library!");
            
            return NO;
        } // if
        
        m_CmdQueue = [device newCommandQueue];
        
        if(!m_CmdQueue)
        {
            NSLog(@">> ERROR: Failed to instantiate a new command queue!");
            
            return NO;
        } // if
        
        mpCompute = [MetalNBodyComputeStage new];
        
        if(!mpCompute)
        {
            NSLog(@">> ERROR: Failed to instantiate a N-Body compute object!");
            
            return NO;
        } // if
        
        mpCompute.globals = _globals;
        mpCompute.library = m_Library;
        mpCompute.device  = device;
        
        if(!mpCompute.isStaged)
        {
            NSLog(@">> ERROR: Failed to acquire a N-Body compute resources!");
            
            return NO;
        } // if

        mpRender = [MetalNBodyRenderStage new];
        
        if(!mpRender)
        {
            NSLog(@">> ERROR: Failed to instantiate a N-Body render stage object!");
            
            return NO;
        } // if
        
        mpRender.globals = _globals;
        mpRender.library = m_Library;
        mpRender.device  = device;

        if(!mpRender.isStaged)
        {
            NSLog(@">> ERROR: Failed to acquire a N-Body render stage resources!");

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

// Generate all the resources (including fragment, vertex and compute stages)
// for rendering N-Body simulation
- (void) acquire:(nullable id<MTLDevice>)device
{
    if(!_haveEncoder)
    {
        _haveEncoder = [self _acquire:device];
    } // if
} // acquire

- (BOOL) _encode:(nullable id<CAMetalDrawable>)drawable
{
    m_CmdBuffer = [m_CmdQueue commandBuffer];
    
    if(!m_CmdBuffer)
    {
        NSLog(@">> ERROR: Failed to acquire a command buffer!");
        
        return NO;
    } // if
    
    mpCompute.parameters = _parameters;
    mpCompute.cmdBuffer  = m_CmdBuffer;
    
    mpRender.positions = mpCompute.buffer;
    mpRender.cmdBuffer = m_CmdBuffer;
    mpRender.drawable  = drawable;
    
    [m_CmdBuffer presentDrawable:drawable];
    [m_CmdBuffer commit];
    
    [mpCompute swapBuffers];
    
    return YES;
} // _encode

// Encode vertex, fragment, and compute stages, then present the drawable
- (void) encode:(nullable id<CAMetalDrawable>)drawable
{
    _isEncoded = [self _encode:drawable];
} // encode

// Wait until the render encoding is complete
- (void) finish
{
    if(m_CmdBuffer)
    {
        [m_CmdBuffer waitUntilCompleted];
    } // if
} // finish

@end
