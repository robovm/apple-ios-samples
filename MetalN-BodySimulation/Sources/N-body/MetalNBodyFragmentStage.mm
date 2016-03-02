/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for creating N-body simulation fragment stage.
 */

#import "NBodyDefaults.h"
#import "NBodyPreferences.h"

#import "MetalGaussianMap.h"

#import "MetalNBodySampler.h"

#import "MetalNBodyFragmentStage.h"

@implementation MetalNBodyFragmentStage
{
@private
    BOOL _isStaged;
    
    NSString*     _name;
    NSDictionary* _globals;
    
    id<MTLFunction>  _function;
    
    uint32_t mnParticles;
    uint32_t mnChannels;
    uint32_t mnTexRes;

    MetalGaussianMap*   mpGaussian;
    MetalNBodySampler*  mpSampler;
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        _name     = nil;
        _globals  = nil;
        _function = nil;
        
        _isStaged = NO;
        
        mnParticles = NBody::Defaults::kParticles;
        mnTexRes    = NBody::Defaults::kTexRes;
        mnChannels  = NBody::Defaults::kChannels;

        mpGaussian = nil;
        mpSampler  = nil;
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
        mnTexRes    = [_globals[kNBodyTexRes]    unsignedIntValue];
        mnChannels  = [_globals[kNBodyChannels]  unsignedIntValue];
    } // if
} // setParameters

- (BOOL) _acquire:(nullable id<MTLDevice>)device
{
    if(device)
    {
        if(!_library)
        {
            NSLog(@">> ERROR: Metal library is nil!");
            
            return NO;
        } // if
        
        _function = [_library newFunctionWithName:(_name) ? _name : @"NBodyLightingFragment"];
        
        if(!_function)
        {
            NSLog(@">> ERROR: Failed to instantiate fragment function!");
            
            return NO;
        } // if
        
        mpSampler = [MetalNBodySampler new];
        
        if(!mpSampler)
        {
            NSLog(@">> ERROR: Failed to instantiate a N-Body sampler object!");
            
            return NO;
        } // if
        
        mpSampler.device = device;
        
        if(!mpSampler.haveSampler)
        {
            NSLog(@">> ERROR: Failed to acquire a N-Body sampler resources!");
            
            return NO;
        } // if
        
        mpGaussian = [MetalGaussianMap new];
        
        if(!mpGaussian)
        {
            NSLog(@">> ERROR: Failed to instantiate a N-Body Gaussian texture object!");
            
            return NO;
        } // if
        
        mpGaussian.channels = mnChannels;
        mpGaussian.texRes   = mnTexRes;
        mpGaussian.device   = device;
        
        if(!mpGaussian.haveTexture)
        {
            NSLog(@">> ERROR: Failed to acquire a N-Body Gaussian texture resources!");
            
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

// Generate all the necessary fragment stage resources using a default system device
- (void) acquire:(nullable id<MTLDevice>)device
{
    if(!_isStaged)
    {
        _isStaged = [self _acquire:device];
    } // if
} // if

// Encode texture and sampler for the fragment stage
- (void) encode:(nullable id<MTLRenderCommandEncoder>)cmdEncoder
{
    [cmdEncoder setFragmentTexture:mpGaussian.texture     atIndex:0];
    [cmdEncoder setFragmentSamplerState:mpSampler.sampler atIndex:0];
} // encode

@end

