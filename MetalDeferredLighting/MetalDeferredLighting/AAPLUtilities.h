/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
      Utilities for AAPLDeferredLighting
      
 */

#ifndef __AAPL_UTILITIES_H__
#define __AAPL_UTILITIES_H__

#import <simd/simd.h>

using namespace simd;

struct ImageInfo
{
    uint     width;
    uint     height;
    uint     bitsPerPixel;
    bool     hasAlpha;
    void     *bitmapData;
};

// Pipeline Error Handling ******************************************************************
static void CheckPipelineError(id<MTLRenderPipelineState> pipeline, NSError *error)
{
    if (pipeline == nil)
    {
        NSLog(@"Failed to create pipeline. error is %@", [error description]);
        assert(0);
    }
}

//Shader Loading ***************************************************************
static id<MTLFunction> _newFunctionFromLibrary(id<MTLLibrary> library, NSString *name)
{
    id<MTLFunction> func = [library newFunctionWithName: name];
    if (!func)
    {
        NSLog(@"failed to find function %@ in the library", name);
        assert(0);
    }
    return func;
}
/////////////////////////////////////////////////////
// Misc Utitility functions
namespace Utilities
{
    const float PI = 3.14159265359f;
    
    float DegreesToRadians(float degree)
    {
        return (degree * PI / 180.0f);
    }
    
    const float inscribe = 0.755761314076171f;    // sqrtf(3.0) / 12.0 * (3.0 + sqrtf(5.0))
    const float circumscribe = 0.951056516295154; // 0.25 * sqrtf(10.0 + 2.0 * sqrtf(5.0))
    
    static float randomFloat(float min, float max)
    {
        double mix = (double)random() / RAND_MAX;
        return min + (max - min) * mix;
    }
    
    static float4 randomColor(void)
    {
        float4 color = {randomFloat(0.0, 1.0), randomFloat(0.0, 1.0), randomFloat(0.0, 1.0), 0.0f};
        
        return normalize(color);
    }
}
/////////////////////////////////////////////////////////
// Texture loading and conversion
static void RGB8ImageToRGBA8(ImageInfo *tex_info)
{
    
    assert(tex_info != NULL);
    assert(tex_info->bitsPerPixel == 24);
    
    NSUInteger stride = tex_info->width * 4;
    void *newPixels = malloc(stride * tex_info->height);
    
    uint32_t *dstPixel = static_cast<uint32_t *>(newPixels);
    uint8_t r, g, b, a;
    a = 255;
    
    NSUInteger sourceStride = tex_info->width * tex_info->bitsPerPixel / 8;
    
    for (int j = 0; j < tex_info->height; j++)
    {
        for (int i = 0; i < sourceStride; i += 3)
        {
            uint8_t *srcPixel = (uint8_t *)(tex_info->bitmapData) + i + (sourceStride * j);
            r = *srcPixel;
            srcPixel++;
            g = *srcPixel;
            srcPixel++;
            b = *srcPixel;
            srcPixel++;
            
            *dstPixel = (static_cast<uint32_t>(a) << 24 | static_cast<uint32_t>(b) << 16 | static_cast<uint32_t>(g) << 8 | static_cast<uint32_t>(r));
            dstPixel++;
            
        }
    }
    
    free(tex_info->bitmapData);
    tex_info->bitmapData = static_cast<unsigned char *>(newPixels);
    tex_info->hasAlpha = true;
    tex_info->bitsPerPixel = 32;
}

static void CreateImageInfo(const char *name, ImageInfo &tex_info)
{
    tex_info.bitmapData = NULL;
    
    UIImage* baseImage = [UIImage imageWithContentsOfFile: [NSString stringWithUTF8String: name]];
    CGImageRef image = baseImage.CGImage;
    
    if (!image)
    {
        return;
    }
    
    tex_info.width = (uint)CGImageGetWidth(image);
    tex_info.height = (uint)CGImageGetHeight(image);
    tex_info.bitsPerPixel = (uint)CGImageGetBitsPerPixel(image);
    tex_info.hasAlpha = CGImageGetAlphaInfo(image) != kCGImageAlphaNone;
    uint sizeInBytes = tex_info.width * tex_info.height * tex_info.bitsPerPixel / 8;
    uint bytesPerRow = tex_info.width * tex_info.bitsPerPixel / 8;
    
    tex_info.bitmapData = malloc(sizeInBytes);
    CGContextRef context = CGBitmapContextCreate(tex_info.bitmapData, tex_info.width, tex_info.height, 8, bytesPerRow, CGImageGetColorSpace(image), CGImageGetBitmapInfo(image));
    
    CGContextDrawImage(context, CGRectMake(0, 0, tex_info.width, tex_info.height), image);
    
    CGContextRelease(context);
    
}

#endif
