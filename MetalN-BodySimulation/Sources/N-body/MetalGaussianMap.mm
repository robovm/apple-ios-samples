/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Utility class for creating a 2d Gaussian texture.
 */

#import <iostream>

#import <simd/simd.h>

#import "CFQueueGenerator.h"

#import "CMNumerics.h"

#import "MetalGaussianMap.h"

typedef enum : uint32_t
{
    eCChannelIsUnkown = 0,
    eCChannelIsR,
    eCChannelIsRG,
    eCChannelIsRGB,
    eCChannelIsRGBA
} CChannels;

@implementation MetalGaussianMap
{
@private
    BOOL _haveTexture;

    id<MTLTexture> _texture;
    
    uint32_t _texRes;
    uint32_t _width;
    uint32_t _height;
    uint32_t _channels;
    uint32_t _rowBytes;
    
    MTLRegion m_Region;
        
    dispatch_queue_t  m_DQueue[2];
    
    CFQueueGenerator* mpQGen;
}

- (instancetype) init
{
    self = [super init];
    
    if(self)
    {
        _texture     = nil;
        _texRes      = 64;
        _width       = _texRes;
        _height      = _texRes;
        _channels    = 4;
        _rowBytes    = _width * _channels;
        _haveTexture = NO;
        
        m_DQueue[0] = nullptr;
        m_DQueue[1] = nullptr;
        
        mpQGen = nil;

        m_Region = MTLRegionMake2D(0, 0, _width, _height);
    } // if
    
    return self;
} // init

- (void) setTexRes:(uint32_t)texRes
{
    _texRes = (texRes) ? texRes : 64;
    _width  = _texRes;
    _height = _texRes;
    
    m_Region = MTLRegionMake2D(0, 0, _width, _height);
} // setResolution

- (void) setChannels:(uint32_t)channels
{
    _channels = (channels) ? channels : 4;
} // setChannels

- (void) _initImage:(nonnull uint8_t *)pImage;
{
    const float nDelta = 2.0f / float(_texRes);
    
    __block int32_t i = 0;
    __block int32_t j = 0;
    
    __block simd::float2 w = -1.0f;
    
    dispatch_apply(_texRes, m_DQueue[0], ^(size_t y) {
        w.y += nDelta;
        
        dispatch_apply(_texRes, m_DQueue[1], ^(size_t x) {
            w.x += nDelta;
            
            float d = simd::length(w);
            float t = 1.0f;
            
            t = CM::isLT(d, t) ? d : 1.0f;
            
            // Hermite interpolation where u = {1, 0} and v = {0, 0}
            uint32_t nColor = uint8_t(255.0f * ((2.0f * t - 3.0f) * t * t + 1.0f));
            
            switch(_channels)
            {
                case eCChannelIsRGBA:
                    pImage[j+3] = nColor;
                    
                case eCChannelIsRGB:
                    pImage[j+2] = nColor;
                    
                case eCChannelIsRG:
                    pImage[j+1] = nColor;
                    
                case eCChannelIsR:
                default:
                    pImage[j] = nColor;
                    break;
            } // switch
            
            i += 2;
            j += _channels;
        });
        
        w.x = -1.0f;
    });
} // _initImage

- (BOOL) _newQueues
{
    if(!mpQGen)
    {
        mpQGen = [CFQueueGenerator new];
    } // if
    
    if(mpQGen)
    {
        if(!m_DQueue[0])
        {
            mpQGen.label = "com.apple.metal.gaussianmap.ycoord";
            
            m_DQueue[0] = mpQGen.queue;
        } // if
        
        if(!m_DQueue[1])
        {
            mpQGen.label = "com.apple.metal.gaussianmap.xcoord";
            
            m_DQueue[1] = mpQGen.queue;
        } // if
    } // if

    return (m_DQueue[0] != nullptr) && (m_DQueue[1] != nullptr);
} // _newQueues

// Generate the Gaussian image
- (nullable uint8_t*) _newImage
{
    uint8_t* pImage = nullptr;
    
    if([self _newQueues])
    {
        pImage = new (std::nothrow) uint8_t[_channels * _texRes * _texRes];
        
        if(pImage != nullptr)
        {
            [self _initImage:pImage];
        } // if
        else
        {
            NSLog(@">> ERROR: Failed allocating backing-store for a Gaussian image!");
        } // else
    } // if
    
    return pImage;
} // _newImage

// Generate a Gaussian texture
- (BOOL) _acquire:(nullable id<MTLDevice>)device
{
    if(device)
    {
        // Create a Metal texture descriptor
        MTLTextureDescriptor* pDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                         width:_width
                                                                                        height:_height
                                                                                     mipmapped:NO];
        
        if(!pDesc)
        {
            return NO;
        } // if
        
        // Create a Metal texture from a descriptor
        _texture = [device newTextureWithDescriptor:pDesc];
        
        if(!_texture)
        {
            return NO;
        } // if
        
        // Generate a Gaussian image data
        uint8_t* pImage = [self _newImage];
        
        if(!pImage)
        {
            return NO;
        } // if
        
        _rowBytes = _width * _channels;
        
        // Upload the Gaussian image into the Metal texture
        [_texture  replaceRegion:m_Region
                     mipmapLevel:0
                       withBytes:pImage
                     bytesPerRow:_rowBytes];
        
        delete [] pImage;
        
        return YES;
    } // if
    else
    {
        NSLog(@">> ERROR: Metal device is nil!");
    } // if
    
    return NO;
} // _acquire

// Generate a texture from samples generated by convolving the initial
// data with a Gaussian white noise
- (void) acquire:(nullable id<MTLDevice>)device
{
    if(!_haveTexture)
    {
        _haveTexture = [self _acquire:device];
    } // if
} // acquire

@end
