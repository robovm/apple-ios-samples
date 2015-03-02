/*
 <samplecode>
 <abstract>
 Textured quad and compute shaders.
 </abstract>
 </samplecode>
 */

#include <metal_graphics>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_texture>

using namespace metal;

struct VertexInOut
{
    float4 m_Position [[position]];
    float2 m_TexCoord [[user(texturecoord)]];
};

vertex VertexInOut texturedQuadVertex(constant float4         *pPosition   [[ buffer(0) ]],
                                      constant packed_float2  *pTexCoords  [[ buffer(1) ]],
                                      constant float4x4       *pMVP        [[ buffer(2) ]],
                                      uint                     vid         [[ vertex_id ]])
{
    VertexInOut outVertices;
    
    outVertices.m_Position = *pMVP * pPosition[vid];
    outVertices.m_TexCoord = pTexCoords[vid];
    
    return outVertices;
}

fragment half4 texturedQuadFragment(VertexInOut      inFrag    [[ stage_in ]],
                                    texture2d<half>  tex2D     [[ texture(0) ]])
{
    constexpr sampler quad_sampler;
    
    half4 color = tex2D.sample(quad_sampler, inFrag.m_TexCoord);
    
    return color;
}

constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

kernel void grayscale(texture2d<half, access::read>  inTexture   [[ texture(0) ]],
                      texture2d<half, access::write> outTexture  [[ texture(1) ]],
                      uint2                          gid         [[ thread_position_in_grid ]])
{
    half4 inColor  = inTexture.read(gid);
    half  gray     = dot(inColor.rgb, kRec709Luma);
    half4 outColor = half4(gray, gray, gray, 1.0);
    
    outTexture.write(outColor, gid);
}
