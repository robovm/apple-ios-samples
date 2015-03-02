/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import <Metal/Metal.h>
#import <simd/simd.h>

#import "AAPLQuad.h"

static const uint32_t kCntQuadTexCoords = 6;
static const uint32_t kSzQuadTexCoords  = kCntQuadTexCoords * sizeof(simd::float2);

static const uint32_t kCntQuadVertices = kCntQuadTexCoords;
static const uint32_t kSzQuadVertices  = kCntQuadVertices * sizeof(simd::float4);

static const simd::float4 kQuadVertices[kCntQuadVertices] =
{
    { -1.0f,  -1.0f, 0.0f, 1.0f },
    {  1.0f,  -1.0f, 0.0f, 1.0f },
    { -1.0f,   1.0f, 0.0f, 1.0f },
    
    {  1.0f,  -1.0f, 0.0f, 1.0f },
    { -1.0f,   1.0f, 0.0f, 1.0f },
    {  1.0f,   1.0f, 0.0f, 1.0f }
};

static const simd::float2 kQuadTexCoords[kCntQuadTexCoords] =
{
    { 0.0f, 0.0f },
    { 1.0f, 0.0f },
    { 0.0f, 1.0f },
    
    { 1.0f, 0.0f },
    { 0.0f, 1.0f },
    { 1.0f, 1.0f }
};

@implementation AAPLQuad
{
@private
    // textured Quad
    id <MTLBuffer>  m_VertexBuffer;
    id <MTLBuffer>  m_TexCoordBuffer;
    
    // Dimensions
    CGSize  _size;
    CGRect  _bounds;
    float   _aspect;
    
    // Indicies
    NSUInteger  _vertexIndex;
    NSUInteger  _texCoordIndex;
    NSUInteger  _samplerIndex;
    
    // Scale
    simd::float2 m_Scale;
}

- (instancetype) initWithDevice:(id <MTLDevice>)device
{
    self = [super init];
    
    if(self)
    {
        if(!device)
        {
            NSLog(@">> ERROR: Invalid device!");
            
            return nil;
        } // if
        
        m_VertexBuffer = [device newBufferWithBytes:kQuadVertices
                                             length:kSzQuadVertices
                                            options:MTLResourceOptionCPUCacheModeDefault];
        
        if(!m_VertexBuffer)
        {
            NSLog(@">> ERROR: Failed creating a vertex buffer for a quad!");
            
            return nil;
        } // if
        m_VertexBuffer.label = @"quad vertices";
        
        m_TexCoordBuffer = [device newBufferWithBytes:kQuadTexCoords
                                               length:kSzQuadTexCoords
                                              options:MTLResourceOptionCPUCacheModeDefault];
        
        if(!m_TexCoordBuffer)
        {
            NSLog(@">> ERROR: Failed creating a 2d texture coordinate buffer!");
            
            return nil;
        } // if
        m_TexCoordBuffer.label = @"quad texcoords";
        
        _vertexIndex   = 0;
        _texCoordIndex = 1;
        _samplerIndex  = 0;
        
        _size   = CGSizeMake(0.0, 0.0);
        _bounds = CGRectMake(0.0, 0.0, 0.0, 0.0);
        
        _aspect = 1.0f;
        
        m_Scale = 1.0f;
    } // if
    
    return self;
} // _setupWithTexture

- (void) setBounds:(CGRect)bounds
{
    _bounds = bounds;
    _aspect = fabsf(_bounds.size.width / _bounds.size.height);
    
    float         aspect = 1.0f/_aspect;
    simd::float2  scale  = 0.0f;
    
    scale.x = aspect * _size.width / _bounds.size.width;
    scale.y = _size.height / _bounds.size.height;
    
    // Did the scaling factor change
    BOOL bNewScale = (scale.x != m_Scale.x) || (scale.y != m_Scale.y);
    
    // Set the (x,y) bounds of the quad
    if(bNewScale)
    {
        // Update the scaling factor
        m_Scale = scale;
        
        // Update the vertex buffer with the quad bounds
        simd::float4 *pVertices = (simd::float4 *)[m_VertexBuffer contents];
        
        if(pVertices != NULL)
        {
            // First triangle
            pVertices[0].x = -m_Scale.x;
            pVertices[0].y = -m_Scale.y;
            
            pVertices[1].x =  m_Scale.x;
            pVertices[1].y = -m_Scale.y;
            
            pVertices[2].x = -m_Scale.x;
            pVertices[2].y =  m_Scale.y;
            
            // Second triangle
            pVertices[3].x =  m_Scale.x;
            pVertices[3].y = -m_Scale.y;
            
            pVertices[4].x = -m_Scale.x;
            pVertices[4].y =  m_Scale.y;
            
            pVertices[5].x =  m_Scale.x;
            pVertices[5].y =  m_Scale.y;
        } // if
    } // if
} // setBounds

- (void) encode:(id <MTLRenderCommandEncoder>)renderEncoder
{    
    [renderEncoder setVertexBuffer:m_VertexBuffer
                            offset:0
                           atIndex:_vertexIndex ];
    
    [renderEncoder setVertexBuffer:m_TexCoordBuffer
                            offset:0
                           atIndex:_texCoordIndex ];
} // encode

@end
