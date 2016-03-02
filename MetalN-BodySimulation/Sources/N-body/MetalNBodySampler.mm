/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for creating a sampler.
 */

#import "MetalNBodySampler.h"

@implementation MetalNBodySampler
{
@private
    BOOL _haveSampler;
    
    id<MTLSamplerState>  _sampler;
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        _haveSampler = NO;
        _sampler     = nil;
    } // if
    
    return self;
} // init

- (BOOL) _acquire:(nullable id<MTLDevice>)device
{
    if(device)
    {
        MTLSamplerDescriptor* pDescriptor = [MTLSamplerDescriptor new];
        
        if(!pDescriptor)
        {
            NSLog(@">> ERROR: Failed to instantiate sampler descriptor!");
            
            return NO;
        } // if
        
        pDescriptor.minFilter             = MTLSamplerMinMagFilterLinear;
        pDescriptor.magFilter             = MTLSamplerMinMagFilterLinear;
        pDescriptor.sAddressMode          = MTLSamplerAddressModeRepeat;
        pDescriptor.tAddressMode          = MTLSamplerAddressModeRepeat;
        pDescriptor.mipFilter             = MTLSamplerMipFilterNotMipmapped;
        pDescriptor.maxAnisotropy         = 1U;
        pDescriptor.normalizedCoordinates = YES;
        pDescriptor.lodMinClamp           = 0.0;
        pDescriptor.lodMaxClamp           = 255.0;
        
        _sampler = [device newSamplerStateWithDescriptor:pDescriptor];
        
        if(!_sampler)
        {
            NSLog(@">> ERROR: Failed to instantiate sampler state with descriptor!");
            
            return NO;
        } // else
        
        return YES;
    } // else
    else
    {
        NSLog(@">> ERROR: Metal device is nil!");
    } // if

    return NO;
} // _acquire

- (void) acquire:(nullable id<MTLDevice>)device
{
    if(!_haveSampler)
    {
        _haveSampler = [self _acquire:device];
    } // if
} // acquire

@end

