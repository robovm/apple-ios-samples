/*
 <samplecode>
 <abstract>
 A shader implementing image based fog for the Metal Shader Showcase. Fog is a common effect that is built in to OpenGL and is a good sample to show implemented in Metal. The effect is accomplished by setting a start to the fog, where the fog gives no contribution to the final color, and an end to the fog, where the final color is the fog color. Using these two numbers, you calculate how much fog is between the object and the camera, and color accordingly.
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
    float distance_to_object;
};

// Global constants
constant float3 light_position = float3(-1.0, 1.0, -1.0);
constant float4 light_color = float4(1.0, 1.0, 1.0, 1.0);
constant float3 fogColor = float3(0.65, 0.65, 0.65);
constant float fogStart = 0.5f;
constant float fogEnd = 0.77f;

constant float4 materialAmbientColor = float4(0.38, 0.18, 0.18, 1.0);
constant float4 materialDiffuseColor = float4(0.6, 0.5, 0.4, 1.0);
constant float4 materialSpecularColor = float4(1.0, 1.0, 1.0, 1.0);
constant float materialShine = 50.0;


float getFogComponent(float objectDistance);
float4 calculateColorWithFog(float objectDistance, float3 objectColor);


// Calculate fog component
float getFogComponent(float objectDistance)
{
    // Calculate what percent of fog is covering up the object with 0% at the fogStart
    // and 100% at the fogEnd.
    float fogComponent = (fogStart - objectDistance) / (fogEnd - fogStart);
    fogComponent = 1.0f - clamp(fogComponent, 0.0f, 1.0f);
    
    return fogComponent;
}

// Calculate the percieved color with the fog given the objects distance and color
float4 calculateColorWithFog(float objectDistance, float3 objectColor)
{
    // Calculate the color by linearly interpolating the object color and the fog color
    // based on the perecent of the fog that is covering up the object (i.e.
    // the fogComponent).
    float fogComponent = getFogComponent(objectDistance);
    float4 colorWithFog;
    colorWithFog.xyz = mix(objectColor, fogColor, fogComponent);
    colorWithFog.w = 1.0f;
    
    return colorWithFog;
}


// Fog vertex shader function
vertex ColorInOut fog_vertex(device packed_float3* vertices [[ buffer(0) ]],
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
    float4 vertex_position_modelspace = float4(float3(vertices[vid]), 1.0);
    out.position = mvp_matrix * vertex_position_modelspace;
    
    // Calculate the normal from the perspective of the camera
    float3 normal = normals[vid];
    out.normal_cameraspace = (normalize(model_view_matrix * float4(normal, 0.0))).xyz;
    
    // Calculate the view vector from the perspective of the camera
    float3 vertex_position_cameraspace = ( view_matrix * model_matrix * vertex_position_modelspace ).xyz;
    out.eye_direction_cameraspace = float3(0,0,0) - vertex_position_cameraspace;
    
    // Calculate the direction of the light from the position of the camera
    float3 light_position_cameraspace = ( view_matrix * float4(light_position,1)).xyz;
    out.light_direction_cameraspace = light_position_cameraspace + out.eye_direction_cameraspace;
    
    // Calculate the distance to the object which is used for how much fog obsures the object
    float4 position_modelviewspace = model_view_matrix * float4(float3(vertices[vid]), 1.0);
    out.distance_to_object = abs(position_modelviewspace.z/position_modelviewspace.w);;
    
    return out;
}

// Fog fragment shader function
fragment half4 fog_fragment(ColorInOut in [[stage_in]])
{
    half4 color;
    
    // Calculate the ambient color
    float4 ambient_color = materialAmbientColor;
    
    // Calculate the diffuse color
    float3 n = normalize(in.normal_cameraspace);
    float3 l = normalize(in.light_direction_cameraspace);
    float n_dot_l = saturate( dot(n, l) );
    float4 diffuse_color = light_color * n_dot_l * materialDiffuseColor;
    
    // Calculate the specular color
    float3 e = normalize(in.eye_direction_cameraspace);
    float3 r = -l + 2.0f * n_dot_l * n;
    float e_dot_r =  saturate( dot(e, r) );
    float4 specular_color = materialSpecularColor * light_color * pow(e_dot_r, materialShine);
    
    // Use the objects final color and distance to calculate the percieved color with fog
    float4 object_color = ambient_color + diffuse_color + specular_color;
    color = half4( calculateColorWithFog(in.distance_to_object, object_color.xyz) );
    
    return color;
};