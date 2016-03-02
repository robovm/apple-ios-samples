/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for managing the N-body compute resources.
 */

#import "CMNumerics.h"

#import "NBodyDefaults.h"
#import "NBodyPreferences.h"
#import "NBodyComputePrefs.h"

#import "MetalNBodyComputeStage.h"

const static uint32_t kNBodyFloat4Size = sizeof(simd::float4);

@implementation MetalNBodyComputeStage
{
@private
    BOOL _isStaged;
    
    uint32_t _multiplier;
    
    NSString*     _name;
    NSDictionary* _globals;
    NSDictionary* _parameters;
    
    id<MTLFunction>             m_Function;
    id<MTLComputePipelineState> m_Kernel;
    id<MTLBuffer>               m_Position[2];
    id<MTLBuffer>               m_Velocity[2];
    id<MTLBuffer>               m_Params;
    
    uint32_t mnStride;
    uint32_t mnRead;
    uint32_t mnWrite;
    
    uint64_t mnSize[3];
    uint64_t mnThreadDimX;
    
    simd::float4* mpHostPos[2];
    simd::float4* mpHostVel[2];
    
    NBody::Compute::Prefs  m_HostPrefs;
    NBody::Compute::Prefs* mpHostPrefs;
    
    MTLSize m_WGSize;
    MTLSize m_WGCount;
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        _name       = nil;
        _globals    = nil;
        _parameters = nil;
        
        _isStaged = NO;
        _multiplier  = 1;
        
        m_Function = nil;
        m_Kernel   = nil;
        m_Params   = nil;
        
        m_Position[0] = nil;
        m_Position[1] = nil;
        
        m_Velocity[0] = nil;
        m_Velocity[1] = nil;
        
        m_HostPrefs.particles    = NBody::Defaults::kParticles;
        m_HostPrefs.timestep     = NBody::Defaults::kTimestep;
        m_HostPrefs.damping      = NBody::Defaults::kDamping;
        m_HostPrefs.softeningSqr = NBody::Defaults::kSofteningSqr;
        
        mnSize[0] = mnStride * m_HostPrefs.particles;
        mnSize[1] = sizeof(NBody::Compute::Prefs);
        mnSize[2] = 0;
        
        mnStride = kNBodyFloat4Size;
        mnRead   = 0;
        mnWrite  = 1;
        
        mpHostPos[0] = nullptr;
        mpHostPos[1] = nullptr;
        
        mpHostVel[0] = nullptr;
        mpHostVel[1] = nullptr;
        
        mpHostPrefs = nullptr;
    } // if
    
    return self;
} // init

// Position buffer
- (nullable id<MTLBuffer>) buffer
{
    return m_Position[mnRead];
} // buffer

// Position host pointer
- (nullable simd::float4 *) position
{
    return mpHostPos[mnRead];
} // position

// Velocity host pointer
- (nullable simd::float4 *) velocity
{
    return mpHostVel[mnRead];
} // velocity

- (void) setMultiplier:(uint32_t)multiplier
{
    if(!_isStaged)
    {
        _multiplier = (multiplier) ? multiplier : 1;
    } // if
} // setMultiplier

// N-body simulation global parameters
- (void) setGlobals:(NSDictionary *)globals
{
    if(globals && !_isStaged)
    {
        _globals = globals;
        
        m_HostPrefs.particles = [_globals[kNBodyParticles] unsignedIntValue];
        
        mnSize[0] = mnStride * m_HostPrefs.particles;
    } // if
} // setGlobals

// N-body parameters for simulation types
- (void) setParameters:(NSDictionary *)parameters
{
    if(parameters)
    {
        _parameters = parameters;
        
        const float nSoftening = [_parameters[kNBodySoftening] floatValue];
        
        m_HostPrefs.timestep     = [_parameters[kNBodyTimestep]  floatValue];
        m_HostPrefs.damping      = [_parameters[kNBodyDamping]   floatValue];
        m_HostPrefs.softeningSqr = nSoftening * nSoftening;
        
        *mpHostPrefs = m_HostPrefs;
    } // if
} // seParameters

- (BOOL) _acquire:(nullable id<MTLDevice>)device
{
    if(device)
    {
        if(!_library)
        {
            NSLog(@">> ERROR: Metal library is nil!");
            
            return NO;
        } // if
        
        m_Function = [_library newFunctionWithName:(_name) ? _name : @"NBodyIntegrateSystem"];
        
        if(!m_Function)
        {
            NSLog(@">> ERROR: Failed to instantiate function!");
            
            return NO;
        } // if
        
        NSError* pError = nil;
        
        m_Kernel = [device newComputePipelineStateWithFunction:m_Function
                                                         error:&pError];
        
        if(!m_Kernel)
        {
            NSString* pDescription = [pError description];
            
            if(pDescription)
            {
                NSLog(@">> ERROR: Failed to instantiate kernel: {%@}!", pDescription);
            } // if
            else
            {
                NSLog(@">> ERROR: Failed to instantiate kernel!");
            } // else
            
            return NO;
        } // if
        
        mnThreadDimX = _multiplier * m_Kernel.threadExecutionWidth;
        
        if((m_HostPrefs.particles % mnThreadDimX) != 0)
        {
            NSLog(@">> ERROR: The number of bodies needs to be a multiple of the workgroup size!");
            
            return NO;
        } // if
        
        mnSize[2] = kNBodyFloat4Size * mnThreadDimX;
        
        m_WGCount = MTLSizeMake(m_HostPrefs.particles/mnThreadDimX, 1, 1);
        m_WGSize  = MTLSizeMake(mnThreadDimX, 1, 1);
        
        m_Position[mnRead] = [device newBufferWithLength:mnSize[0] options:0];
        
        if(!m_Position[mnRead])
        {
            NSLog(@">> ERROR: Failed to instantiate position buffer 1!");
            
            return NO;
        } // if
        
        mpHostPos[mnRead] = static_cast<simd::float4 *>([m_Position[mnRead] contents]);
        
        if(!mpHostPos[mnRead])
        {
            NSLog(@">> ERROR: Failed to get the base address to position buffer 1!");
            
            return NO;
        } // if
        
        m_Position[mnWrite] = [device newBufferWithLength:mnSize[0] options:0];
        
        if(!m_Position[mnWrite])
        {
            NSLog(@">> ERROR: Failed to instantiate position buffer 2!");
            
            return NO;
        } // if
        
        mpHostPos[mnWrite] = static_cast<simd::float4 *>([m_Position[mnWrite] contents]);
        
        if(!mpHostPos[mnWrite])
        {
            NSLog(@">> ERROR: Failed to get the base address to position buffer 2!");
            
            return NO;
        } // if
        
        m_Velocity[mnRead] = [device newBufferWithLength:mnSize[0] options:0];
        
        if(!m_Velocity[mnRead])
        {
            NSLog(@">> ERROR: Failed to instantiate velocity buffer 1!");
            
            return NO;
        } // if
        
        mpHostVel[mnRead] = static_cast<simd::float4 *>([m_Velocity[mnRead] contents]);
        
        if(!mpHostVel[mnRead])
        {
            NSLog(@">> ERROR: Failed to get the base address to velocity buffer 1!");
            
            return NO;
        } // if
        
        m_Velocity[mnWrite] = [device newBufferWithLength:mnSize[0] options:0];
        
        if(!m_Velocity[mnWrite])
        {
            NSLog(@">> ERROR: Failed to instantiate velocity buffer 2!");
            
            return NO;
        } // if
        
        mpHostVel[mnWrite] = static_cast<simd::float4 *>([m_Velocity[mnWrite] contents]);
        
        if(!mpHostVel[mnWrite])
        {
            NSLog(@">> ERROR: Failed to get the base address to velocity buffer 2!");
            
            return NO;
        } // if
        
        m_Params = [device newBufferWithLength:mnSize[1] options:0];
        
        if(!m_Params)
        {
            NSLog(@">> ERROR: Failed to instantiate compute kernel parameter buffer!");
            
            return NO;
        } // if
        
        mpHostPrefs = static_cast<NBody::Compute::Prefs *>([m_Params contents]);
        
        if(!mpHostPrefs)
        {
            NSLog(@">> ERROR: Failed to get the base address to compute kernel parameter buffer!");
            
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

// Generate all the necessary compute stage resources using a default system device
- (void) acquire:(nullable id<MTLDevice>)device
{
    if(!_isStaged)
    {
        _isStaged = [self _acquire:device];
    } // if
} // acquire

// Setup compute pipeline state and encode
- (void) encode:(nullable id<MTLCommandBuffer>)cmdBuffer
{
    if(cmdBuffer)
    {
        id<MTLComputeCommandEncoder> encoder = [cmdBuffer computeCommandEncoder];
        
        if(encoder)
        {
            [encoder setComputePipelineState:m_Kernel];
            
            [encoder setBuffer:m_Position[mnWrite]  offset:0 atIndex:0];
            [encoder setBuffer:m_Velocity[mnWrite]  offset:0 atIndex:1];
            [encoder setBuffer:m_Position[mnRead]   offset:0 atIndex:2];
            [encoder setBuffer:m_Velocity[mnRead]   offset:0 atIndex:3];
            
            [encoder setBuffer:m_Params offset:0 atIndex:4];
            
            [encoder setThreadgroupMemoryLength:mnSize[2] atIndex:0];
            
            [encoder dispatchThreadgroups:m_WGCount
                    threadsPerThreadgroup:m_WGSize];
            
            [encoder endEncoding];
        } // if
    } // if
} // encode

// Swap the read/write buffers
- (void) swapBuffers
{
    CM::swap(mnRead, mnWrite);
} // swapBuffers

@end
