/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Environment mapping shader that mixes several textures.
 */

#include <metal_graphics>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_texture>
#include <metal_stdlib>

#include "AAPLSharedTypes.h"

using namespace metal;

struct EnvMapVertexOutput
{
    float4 position [[position]];
    float4 eye;
    half4 color;
    float3 eye_normal;
    float3 normal;
    float2 uv;
};

typedef struct
{
    packed_float3 position;
    packed_float3 normal;
    packed_float2 texCoord;
} vertex_t;

constant float4 copper_ambient = float4(0.19125f, 0.0735f, 0.0225f, 1.0f);
constant float4 copper_diffuse = float4(0.7038f, 0.27048f, 0.0828f, 1.0f);
constant float3 light_position = float3(0.0f, 1.0f, -1.0f);

vertex EnvMapVertexOutput reflectQuadVertex(device vertex_t* vertex_array [[ buffer(QUAD_VERTEX_BUFFER) ]],
                                            constant AAPL::uniforms_t& uniforms [[ buffer(QUAD_VERTEX_CONSTANT_BUFFER) ]],
                                            uint vid [[vertex_id]])
{
    // get per vertex data
    float3 position = float3(vertex_array[vid].position);
    float3 normal = float3(vertex_array[vid].normal);
    float2 uv = float2(vertex_array[vid].texCoord);
    
    // output transformed geometry data
    EnvMapVertexOutput out;
    out.position = uniforms.modelview_projection_matrix * float4(position, 1.0);
    out.normal = normalize(uniforms.normal_matrix * float4(normal, 0.0)).xyz;
    
    // fix the uv's to fit the video camera's coordinate system and the device's orientation
    switch (uniforms.orientation)
    {
        case AAPL::PortraitUpsideDown:
            out.uv.x = 1.0f - uv.y;
            out.uv.y = uv.x;
            break;
        case AAPL::Portrait:
            out.uv.x = uv.y;
            out.uv.y = 1.0f - uv.x;
            break;
        case AAPL::LandscapeLeft:
            out.uv.x = 1.0f - uv.x;
            out.uv.y = 1.0f - uv.y;
            break;
        case AAPL::LandscapeRight:
            out.uv.x = uv.x;
            out.uv.y = uv.y;
            break;
        default:
            out.uv.x = 0;
            out.uv.y = 0;
            break;
    }

    // calculate the incident vector and normal vectors for reflection in the quad's modelview space
    out.eye = normalize(uniforms.modelview_matrix * float4(position, 1.0));
    out.eye_normal = normalize(uniforms.modelview_matrix * float4(normal, 0.0)).xyz;
    
    // calculate diffuse lighting with the material color
    float n_dot_l = dot(out.normal, normalize(light_position));
    n_dot_l = fmax(0.0, n_dot_l);
    out.color = half4(copper_ambient) + half4(copper_diffuse * n_dot_l);
    
    return out;
}

fragment half4 reflectQuadFragment(EnvMapVertexOutput in [[stage_in]],
                                    texturecube<half> env_tex [[ texture(QUAD_ENVMAP_TEXTURE) ]],
                                    texture2d<half> tex [[ texture(QUAD_IMAGE_TEXTURE) ]],
                                    constant AAPL::uniforms_t& uniforms [[ buffer(QUAD_FRAGMENT_CONSTANT_BUFFER) ]])
{
    // get reflection vector
    float3 reflect_dir = reflect(in.eye.xyz, in.eye_normal);
    
    // return reflection vector to world space
    float4 reflect_world = uniforms.inverted_view_matrix * float4(reflect_dir, 0.0);
    
    // use the inverted reflection vector to sample from the cube map
    constexpr sampler s_cube(filter::linear, mip_filter::linear);
    half4 tex_color = env_tex.sample(s_cube, reflect_world.xyz);
    
    // sample from the 2d textured quad as well
    constexpr sampler s_quad(filter::linear);
    half4 image_color = tex.sample(s_quad, in.uv);
    
    // combine with texture, light, and envmap reflaction
    half4 color = mix(in.color, image_color, 0.9h);
    color = mix(tex_color, color, 0.6h);
    
    return color;
}
