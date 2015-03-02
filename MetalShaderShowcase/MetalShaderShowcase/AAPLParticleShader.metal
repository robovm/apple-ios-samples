/*
 <samplecode>
 <abstract>
 A shader representing a particle system for the Metal Shader Showcase. Particles are a common effect implemented in many 3D applications.  Each particle's initial random direction and birth offset is passed into the vertex shader. It uses these values to calculate the particles position based on the current time. Then the fragment shader uses these points and colors them as circles that fade out at the edges.
 </abstract>
 </samplecode>
 */

#include <metal_stdlib>
#include <metal_common>
#include <simd/simd.h>
#include "AAPLSharedTypes.h"

using namespace metal;

struct ColorInOut {
    float4 position [[position]];
    float point_size [[point_size]];
    float t;
    float lifespan;
};

// Global constants
constant float POINT_SIZE = 60.0f;
constant float3 a = float3(0.0, -1.8f, 0.0);
constant float3 x_0 = float3(0.0, 0.1, 0.0);


// Phong vertex shader function
vertex ColorInOut particle_vertex(device packed_float3* initialDirection [[ buffer(0) ]],
                                  device float* birthOffsets [[ buffer(1) ]],
                                  constant AAPL::uniforms_t& uniforms [[ buffer(2) ]],
                                  unsigned int vid [[ vertex_id ]])
{
    ColorInOut out;
    
    float4x4 model_matrix = uniforms.model_matrix;
    float4x4 view_matrix = uniforms.view_matrix;
    float4x4 projection_matrix = uniforms.projection_matrix;
    float4x4 mvp_matrix = projection_matrix * view_matrix * model_matrix;
    
    // Have the particles repeat their movement by keeping their time between 0 and their
    // lifespan.
    float t = fmod(uniforms.t + birthOffsets[vid], uniforms.lifespan);
    
    // Calculate the position of the particle based on the physics equation for motion:
    // x = x_0 + (v_0 * t) + (1/2)(a * t^2)
    float3 v_0 = float3( initialDirection[vid] );
    float3 vertex_position_modelspace =  x_0 + (v_0 * t) + (0.5f * a * t * t);
    out.position = mvp_matrix * float4(vertex_position_modelspace, 1.0f);
    
    out.point_size = POINT_SIZE;
    out.t = t;
    out.lifespan = uniforms.lifespan;
    return out;
}

// Phong fragment shader function
fragment half4 particle_fragment(ColorInOut in [[stage_in]], float2 uv[[point_coord]])
{
    half4 color = half4(0.0f, 0.0f, 1.0f, 1.0f);
    
    // Make the particle fade off as it gets older by multiplying the percentage of life
    // left for the particle by it's color.
    float lifeAlpha = (in.lifespan - in.t) / in.lifespan;
    color *= lifeAlpha;
    
    // Make the particles circular by using the uv coordinate to calculate the distance
    // this fragment is from the center of the particle. We set its color as more
    // transparent the closer it gets to the edge of the circle where the center of the
    // circle is completely opaque and the edge of the circle is completely transparent.
    float2 uvPos = uv;
    
    uvPos.x -= 0.5f;
    uvPos.y -= 0.5f;
    
    uvPos *= 2.0f;
    
    float dist = sqrt(uvPos.x*uvPos.x + uvPos.y*uvPos.y);
    float circleAlpha = saturate(1.0f-dist);
    
    color *= circleAlpha;
    
    return half4(color.r, color.g, color.b, circleAlpha*lifeAlpha);
};