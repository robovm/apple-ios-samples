/*
 <samplecode>
 <abstract>
 A shader implementing sphere mapping for the Metal Shader Showcase. Environment mapping is used for reflections and refractions in many real time graphics applications, and this is one possible implementation of the technique. This is done by using a texture of a mirrored sphere that captures the environment. Because it is a sphere, it captures all possible reflection angles a viewer could see. Thus, we calculate the reflection vector from the object, and use the texture to lookup what is reflected there.
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
    float3 normal_cameraspace;
    float3 eye_direction_cameraspace;
    float3 light_direction_cameraspace;
    float3 position_cameraspace;
};

// Global constants
constant float3 light_position = float3(-1.0, 1.0, -1.0);
constant float4 light_color = float4(1.0, 1.0, 1.0, 1.0);
constant float reflectiveFactor = 0.4f;
constant float4 materialAmbientColor = {0.18, 0.18, 0.18, 1.0};
constant float4 materialDiffuseColor = {0.4, 0.4, 0.4, 1.0};
constant float4 materialSpecularColor = {1.0, 1.0, 1.0, 1.0};
constant float  materialShine = 50.0;

// Sphere map vertex shader function
vertex ColorInOut sphere_map_vertex(device packed_float3* vertices [[ buffer(0) ]],
                                    device packed_float3* normals [[ buffer(1) ]],
                                    constant AAPL::uniforms_t& uniforms [[ buffer(2) ]],
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
    
    // Calculate the normal from the perspective of the camera
    float3 normal = normals[vid];
    out.normal_cameraspace = (normalize(model_view_matrix * float4(normal, 0.0f))).xyz;
    
    // Calculate the view vector from the perspective of the camera
    float3 vertex_position_cameraspace = ( view_matrix * model_matrix * vertex_position_modelspace ).xyz;
    out.eye_direction_cameraspace = float3(0.0f,0.0f,0.0f) - vertex_position_cameraspace;
    
    // Calculate the direction of the light from the position of the camera
    float3 light_position_cameraspace = ( view_matrix * float4(light_position,1)).xyz;
    out.light_direction_cameraspace = light_position_cameraspace + out.eye_direction_cameraspace;
    
    out.position_cameraspace = normalize( (model_view_matrix * vertex_position_modelspace).xyz );
    
    return out;
}

// Sphere map fragment shader function. It uses a texture that represents a spherical mirror to lookup
// the color reflected by the environment in any direction seen by the viewer.
fragment half4 sphere_map_fragment(ColorInOut in [[stage_in]],
                                   texture2d<float>  tex2D     [[ texture(0) ]])
{
    constexpr sampler sampler2D;
    float3 phong_color;
    
    // Calculate the ambient color
    float4 ambient_color = materialAmbientColor;
    
    // Calculate the diffuse color
    float3 n = normalize(in.normal_cameraspace);
    float3 l = normalize(in.light_direction_cameraspace);
    float n_dot_l = saturate( dot(n, l) );
    float4 diffuse_color = light_color * n_dot_l * materialDiffuseColor;
    
    // Calculate the specular color
    float3 e = normalize(in.eye_direction_cameraspace);
    float3 r = -l + 2 * n_dot_l * n;
    float e_dot_r =  saturate( dot(e,r) );
    float4 specular_color = materialSpecularColor * light_color * pow(e_dot_r, materialShine);
    
    // Calculate the phong color
    phong_color = (ambient_color + diffuse_color + specular_color).rgb;
    
    // Calculate the uv coordinate of the reflected color. To do this we need the view's reflection
    // vector and the view vector. The view's reflection vector is calculated using the reflection
    // method on the position of the object in camera space and the normal in camera space. Because
    // we are in camera space we know the view vector is <0, 0, 1>. To find the uv coordinate given
    // the view vector and the reflection vector, we must find the sphere's normal. To do that we add
    // the view vector (viewVec) to the reflection vector (rVec). Then we must normalize it. We do
    // this by calculating the length of the vector (m) and dividing the current vector by the length.
    // This normal describes a point on the image of the sphere in the range [-1,1]. To get this to map
    // to the uv coordinate range of [0,1] we multiply by a half and add a half.
    float3 rVec = reflect(in.position_cameraspace, normalize(in.normal_cameraspace));
    float3 viewVec(0,0,1);
    float3 sNormal = rVec + viewVec;
    
    float m = length(sNormal);
    sNormal /= m;
    
    float2 uv;
    uv.x = (0.5 * sNormal.x) + 0.5f;
    uv.y = (0.5 * sNormal.y) + 0.5f;
    
    // Use the uv coordinate to get the reflective color
    float3 reflectiveColor = (tex2D.sample(sampler2D, uv)).rgb;
    
    // Calculate the final color by mixing the phong and the reflective color
    float4 final_color;
    final_color.rgb = mix(phong_color, reflectiveColor, reflectiveFactor);
    final_color.a = 1.0f;
    
    return half4(final_color);
};
