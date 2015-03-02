/*
 <samplecode>
 <abstract>
 A shader implementing cel shading for the Metal Shader Showcase. This is a common implementation of non-photorealistic rendering technique. This effect is accomplished by breaking down the diffuse component into 3 different shades and the specular into only one. The diffuse color is decided upon by calculating the angle between the normal and the light vector, and setting three different angles as the boundaries of these regions. It is similarly done with the specular component with only one angle between the viewer and the reflection vector determining the boundary. </abstract>
 </samplecode>
 */

#include <metal_stdlib>
#include <metal_common>
#include <simd/simd.h>
#include "AAPLSharedTypes.h"

using namespace metal;

struct ColorInOut {
    float4 position [[position]];
    float shine;
    float3 normal_cameraspace;
    float3 eye_direction_cameraspace;
    float3 light_direction_cameraspace;
};

constant float3 light_position = float3(-1.0, 1.0, -1.0);
constant float4 light_color = float4(1.0, 1.0, 1.0, 1.0);
constant float4 materialAmbientColor = {0.18, 0.18, 0.18, 1.0};
constant float4 materialDiffuseColor = {0.4, 0.4, 0.4, 1.0};
constant float4 materialSpecularColor = {1.0, 1.0, 1.0, 1.0};
constant float  materialShine = 50.0;
constant float d1 = 0.1;
constant float d2 = 0.6;
constant float d3 = 1.0;


// Cel Shading vertex shader function
vertex ColorInOut cel_shading_vertex(device packed_float3* vertices [[ buffer(0) ]],
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
    
    return out;
}

// Cel Shading fragment shader function.
fragment half4 cel_shading_fragment(ColorInOut in [[stage_in]])
{
    half4 color;
    
    // Calculate the ambient color
    float4 ambient_color = materialAmbientColor;
    
    // Calculate the diffuse color. The diffuse color is one of three shades: a bright color,
    // a mid-range color, or a dark color. This is decided upon based on the angle between the
    // normal and the light, and the three values we set as the edges of the shades (d1, d2,
    // and d3). If the pixel is on the border of any two shades (i.e. it is within an epsilon
    // value we define as the derivative of the diffuse factor), we linearly interpolate between
    // the two colors to create a more natural looking, smooth transition.
    float3 n = normalize(in.normal_cameraspace);
    float3 l = normalize(in.light_direction_cameraspace);
    float n_dot_l = dot(n, l);
    
    float diffuse_factor = saturate( n_dot_l );
    float epsilon = fwidth(diffuse_factor);
    
    // If it is on the border of the first two colors, smooth it
    if ( (diffuse_factor > d1 - epsilon) && (diffuse_factor < d1 + epsilon) )
    {
        diffuse_factor = mix(d1, d2, smoothstep(d1-epsilon, d1+epsilon, diffuse_factor));
    }
    // If it is on the border of the second two colors, smooth it
    else if ( (diffuse_factor > d2 - epsilon) && (diffuse_factor < d2 + epsilon) )
    {
        diffuse_factor = mix(d2, d3, smoothstep(d2-epsilon, d2+epsilon, diffuse_factor));
    }
    // If it is the darkest color
    else if (diffuse_factor < d1)
    {
        diffuse_factor = 0.0;
    }
    // If is is the mid-range color
    else if (diffuse_factor < d2)
    {
        diffuse_factor = d2;
    }
    // It is the brightest color
    else
    {
        diffuse_factor = d3;
    }
    
    float4 diffuse_color = light_color * diffuse_factor * materialDiffuseColor;
    
    // Calculate the specular color. This is done in a similar fashion to how the diffuse color
    // is calculated. We see if the angle between the viewer and the reflected light is small. If
    // is it, we color it the specular color. If it is on the border of the specular highlight
    // (i.e. it is within an epsilon value we define as the derivative of the specular factor),
    // we linearly interpolate between the two colors to create a more natural looking, smooth
    // transition.
    float3 e = normalize(in.eye_direction_cameraspace);
    float3 r = -l + 2.0f * n_dot_l * n;
    float e_dot_r =  saturate( dot(e, r) );
    
    float specular_factor = pow(e_dot_r, materialShine);
    epsilon = fwidth(specular_factor);
    
    // If it is on the edge of the specular highlight
    if ( (specular_factor > 0.5f - epsilon) && (specular_factor < 0.5f + epsilon) )
    {
        specular_factor = smoothstep(0.5f - epsilon, 0.5f + epsilon, specular_factor);
    }
    // It is either in or out of the highlight
    else
    {
        specular_factor = step(0.5f, specular_factor);
    }
    
    float4 specular_color = materialSpecularColor * light_color * specular_factor;
    
    color = half4(ambient_color + diffuse_color + specular_color);
    
    return color;
};