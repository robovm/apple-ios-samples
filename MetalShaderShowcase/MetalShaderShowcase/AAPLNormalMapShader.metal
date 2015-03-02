/*
 <samplecode>
 <abstract>
 A shader implementing normal mapping for the Metal Shader Showcase. This is a common technique that is used in many 3D applications that increases geometric detail without incurring high computational cost. This is done by storing surface details in a texture and then using that texture to change the normals of the object. </abstract>
 </samplecode>
 */

#include <metal_stdlib>
#include <metal_common>
#include <simd/simd.h>
#include "AAPLSharedTypes.h"

using namespace metal;

struct ColorInOut {
    float4 position [[position]];
    float2 uv;
    float3 light_direction_tangentspace;
    float3 eye_direction_tangentspace;
};

// Global constants
constant float3 light_position = float3(-1.0, 1.0, -1.0);
constant float4 light_color = float4(1.0, 1.0, 1.0, 1.0);

constant float4 materialAmbientColor = {0.18, 0.18, 0.18, 1.0};
constant float4 materialDiffuseColor = {0.4, 0.4, 0.4, 1.0};
constant float4 materialSpecularColor = {1.0, 1.0, 1.0, 1.0};
constant float  materialShine = 200.0;

// Normal map vertex shader function
vertex ColorInOut normal_map_vertex(device packed_float3* vertices [[ buffer(0) ]],
                                    device packed_float3* normals [[ buffer(1) ]],
                                    device packed_float2* uvs [[ buffer(2) ]],
                                    device packed_float3* tangents [[ buffer(3) ]],
                                    device packed_float3* bitangents [[ buffer(4) ]],
                                    constant AAPL::uniforms_t& uniforms [[ buffer(5) ]],
                                    unsigned int vid [[ vertex_id ]])
{
    ColorInOut out;
    
    float4x4 model_matrix = uniforms.model_matrix;
    float4x4 view_matrix = uniforms.view_matrix;
    float4x4 projection_matrix = uniforms.projection_matrix;
    float4x4 mvp_matrix = projection_matrix * view_matrix * model_matrix;
    float4x4 model_view_matrix = view_matrix * model_matrix;
    
    // Calculate the position of the object from the perspective of the camera
    float4 vertex_position_modelspace = float4(float3(vertices[vid]), 1.0f);
    out.position = mvp_matrix * vertex_position_modelspace;
    
    // Calculate the view vector from the perspective of the camera
    float3 vertex_position_cameraspace = ( view_matrix * model_matrix * vertex_position_modelspace ).xyz;
    float3 eye_direction_cameraspace = float3(0.0f,0.0f,0.0f) - vertex_position_cameraspace;
    
    // Calculate the direction of the light from the position of the camera
    float3 light_position_cameraspace = ( view_matrix * float4(light_position,1.0f)).xyz;
    float3 light_direction_cameraspace = light_position_cameraspace + eye_direction_cameraspace;

    out.uv = float2(uvs[vid]);
    
    // Calculate the TBN matrix using the tangent, bitangent, and normal. This is a matrix
    // that can be used to move any vector from camera space to tangent space (where we will
    // be doing all of our lighting calculations). We do this so that we can change the normal
    // based on the texture that is provided.
    float3x3 mv3x3;
    mv3x3[0].xyz = model_view_matrix[0].xyz;
    mv3x3[1].xyz = model_view_matrix[1].xyz;
    mv3x3[2].xyz = model_view_matrix[2].xyz;
    
    float3 tangent_cameraspace = mv3x3 * float3(tangents[vid]);
    float3 bitangent_cameraspace = mv3x3 * float3(bitangents[vid]);
    float3 normal_cameraspace = mv3x3 * float3(normals[vid]);
    float3x3 tbn = float3x3(tangent_cameraspace, bitangent_cameraspace, normal_cameraspace);
    tbn = transpose(tbn);
    
    // Pass along the light and eye directions in tangent space
    out.light_direction_tangentspace = tbn * light_direction_cameraspace;
    out.eye_direction_tangentspace = tbn * eye_direction_cameraspace;
    
    return out;
}

// Normal map fragment shader function
fragment half4 normal_map_fragment(ColorInOut in [[stage_in]],
                                   texture2d<float> normalTexture [[ texture(0) ]])
{
    constexpr sampler sampler2D;
    half4 color;
 
    // Calculate the ambient color
    float4 ambient_color = materialAmbientColor;
     
    // Calculate the normal from the texture map. This is done by reading the color from the
    // texture and storing that as a vector. Because the values are saved in an image, they
    // will have a range of [0,1]. To fully represent all possible normals, we need the values
    // in the range of [-1, 1]. We get them in this range by multiplying them by 2 and
    // subtracting 1. All lighting calculations are the same as with phong shading except that
    // they are all done in tangent space instead of camera space.
    float3 textureNormalValue = (normalTexture.sample(sampler2D, in.uv)).xyz;
    float3 textureNormal_tangentspace = normalize(textureNormalValue * 2.0f - 1.0f);
 
    // Calculate the diffuse color
    float3 n = textureNormal_tangentspace;
    float3 l = normalize(in.light_direction_tangentspace);
    float n_dot_l = saturate( dot(n, l) );
    float4 diffuse_color = light_color * n_dot_l * materialDiffuseColor;
 
    // Calculate the specular color
    float3 e = normalize(in.eye_direction_tangentspace);
    float3 r = -l + 2.0f * n_dot_l * n;
    float e_dot_r =  saturate( dot(e, r) );
 
    float4 specular_color = materialSpecularColor * light_color * pow(e_dot_r, materialShine);
 
    color = half4(ambient_color + diffuse_color + specular_color);
    return color;
 };