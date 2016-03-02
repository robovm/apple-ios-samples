/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for creating and managing of N-body simulation vertex stage and resources.
 */

#import "CMNumerics.h"

#import "NBodyDefaults.h"

#import "MetalNBodyTransform.h"

#import "MetalNBodyVertexStage.h"

@implementation MetalNBodyVertexStage
{
@private
    BOOL  _isStaged;
    
    NSString* _name;
    
    simd::float4* _colors;
    
    id<MTLFunction>  _function;
    id<MTLBuffer>    _positions;
    
    id<MTLBuffer>  m_Colors;
    id<MTLBuffer>  m_PointSz;
    
    uint32_t mnParticles;
    
    float  mnPointSz;
    float* mpPointSz;
    
    MetalNBodyTransform*  mpTransform;
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        _isStaged = NO;

        _name      = nil;
        _function  = nil;
        _positions = nil;
        
        _colors = nullptr;
        
        mnPointSz   = NBody::Defaults::kPointSz;
        mnParticles = NBody::Defaults::kParticles;
        
        m_Colors  = nil;
        m_PointSz = nil;
        
        mpTransform = nil;
        mpPointSz   = nullptr;
    } // if
    
    return self;
} // init

// Number of point particles in the N-body simulation
- (void) setParticles:(uint32_t)particles
{
    mnParticles = (particles) ? particles : NBody::Defaults::kParticles;
} // setParticles

// Point particle size
- (void) setPointSz:(float)pointSz
{
    if(mpPointSz != nullptr)
    {
        *mpPointSz = CM::isLT(pointSz, mnPointSz) ? mnPointSz : pointSz;
    } // if
} // setPointSz

// Aspect ratio
- (void) setAspect:(float)aspect
{
    if(mpTransform)
    {
        mpTransform.aspect = aspect;
    } // if
} // setAspect

// Orthographic projection configuration type
- (void) setConfig:(uint32_t)config
{
    if(mpTransform)
    {
        mpTransform.config = config;
    } // if
} // setConfig

// Update the linear transformation mvp matrix
- (void) setUpdate:(BOOL)update
{
    if(mpTransform)
    {
        mpTransform.update = update;
    } // if
} // setUpdate

- (BOOL) _acquire:(nullable id<MTLDevice>)device
{
    if(device)
    {
        if(!_library)
        {
            NSLog(@">> ERROR: Metal library is nil!");
            
            return NO;
        } // if
        
        _function = [_library newFunctionWithName:(_name) ? _name : @"NBodyLightingVertex"];
        
        if(!_function)
        {
            NSLog(@">> ERROR: Failed to instantiate vertex function!");
            
            return NO;
        } // if
        
        m_Colors = [device newBufferWithLength:sizeof(simd::float4)*mnParticles options:0];
        
        if(!m_Colors)
        {
            NSLog(@">> ERROR: Failed to instantiate a new m_Colors buffer!");
            
            return NO;
        } // if
        
        _colors = static_cast<simd::float4 *>([m_Colors contents]);
        
        if(!_colors)
        {
            NSLog(@">> ERROR: Failed to acquire a host pointer for m_Colors buffer!");
            
            return NO;
        } // if
        
        m_PointSz = [device newBufferWithLength:sizeof(float) options:0];
        
        if(!m_PointSz)
        {
            NSLog(@">> ERROR: Failed to instantiate a new buffer for m_PointSz size!");
            
            return NO;
        } // if
        
        mpPointSz = static_cast<float *>([m_PointSz contents]);
        
        if(!mpPointSz)
        {
            NSLog(@">> ERROR: Failed to acquire a host pointer for buffer representing m_PointSz size!");
            
            return NO;
        } // if

        mpTransform = [MetalNBodyTransform new];
        
        if(!mpTransform)
        {
            NSLog(@">> ERROR: Failed to instantiate a N-Body linear transform object!");
            
            return NO;
        } // if
        
        mpTransform.device = device;
        
        if(!mpTransform.haveBuffer)
        {
            NSLog(@">> ERROR: Failed to acquire a N-Body transform buffer resource!");
            
            return NO;
        } // if

        return YES;
    } // if
    else
    {
        NSLog(@">> ERROR: Metal device is nil!");
    } // if
    
    return NO;
} // _acquire

// Generate all the necessary vertex stage resources using a default system device
- (void) acquire:(nullable id<MTLDevice>)device
{
    if(!_isStaged)
    {
        _isStaged = [self _acquire:device];
    } // if
} // acquire

// Encode the buffers for the vertex stage
- (void) encode:(nullable id<MTLRenderCommandEncoder>)cmdEncoder
{
    if(_positions)
    {
        [cmdEncoder setVertexBuffer:_positions         offset:0 atIndex:0];
        [cmdEncoder setVertexBuffer:m_Colors           offset:0 atIndex:1];
        [cmdEncoder setVertexBuffer:mpTransform.buffer offset:0 atIndex:2];
        [cmdEncoder setVertexBuffer:m_PointSz          offset:0 atIndex:3];
    } // if
} // encode

@end
