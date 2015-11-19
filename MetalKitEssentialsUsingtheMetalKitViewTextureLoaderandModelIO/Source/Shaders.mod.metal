
#include <metal_graphics>
#include <metal_geometric>
#include <metal_texture>
#include <metal_common>
#include <metal_matrix>
#include "SHaderTypes.h"

using namespace metal;

typedef float2 vec2;
typedef float3 vec3;
typedef float4 vec4;

constant float PI = 3.1415926535897932384626433832795;

//
// Structures
//

struct ShadingValues {
    vec3 surfacePosition;
    vec3 N;
    vec3 V;
    vec3 L;
    vec3 shadingBasisX;
    vec3 shadingBasisY;
};

struct DerivedShadingValues {
    vec3 H;
    vec3 reflected;
    float NdotL;
    float NdotV;
    float NdotH;
    float LdotH;
    float FL;
    float FV;
    float FH;
    float diffuseRoughness;
    vec3 irradianceColor;
    vec3 reflectedColor;
    vec3 environmentColor;
};

struct MaterialValues {
    vec3 baseColor;
    vec3 baseColorHueSat;
    vec3 aoValue;
    float baseColorLuminance;
    float specular;
    float specularTint;
    float metallic;
    float sheen;
    float sheenTint;
    float roughness;
    float anisotropic;
    float clearcoat;
    float clearcoatGloss;
    float subsurface;
};

//
// Utility
//

float sqr(float a);
float sqr(float a) {
    return a * a;
}

vec4 srgbToLinear(vec4 c);
vec4 srgbToLinear(vec4 c) {
    vec4 gamma = vec4(1.0/2.2);
    return pow(c, gamma);
}

vec4 linearToSrgba(vec4 c);
vec4 linearToSrgba(vec4 c) {
    vec4 gamma = vec4(2.2);
    return pow(c, gamma);
}

float SchlickFresnel(float u);
float SchlickFresnel(float u) {
    float m = clamp(1.0 - u, 0.0, 1.0);
    return pow(m, 5.0);
}


float smithG_GGX(float Ndotv, float alphaG);
float smithG_GGX(float Ndotv, float alphaG) {
    float a = alphaG*alphaG;
    float b = Ndotv*Ndotv;
    return 1.0 / (Ndotv + sqrt(a + b - a*b));
}

// Generalized Trowbridge-Reitz
//
float GTR1(float NdotH, float a);
float GTR1(float NdotH, float a) {
    if (a >= 1.0) return 1.0/PI;
    float a2 = a*a;
    float t = 1.0 + (a2-1.0)*NdotH*NdotH;
    return (a2-1.0) / (PI*log(a2)*t);
}

// Generalized Trowbridge-Reitz, with GGX divided out
//
float GTR2_aniso(float NdotH, float HdotX, float HdotY, float ax, float ay);
float GTR2_aniso(float NdotH, float HdotX, float HdotY, float ax, float ay) {
    return 1.0 / ( PI * ax*ay * sqr( sqr(HdotX/ax) + sqr(HdotY/ay) + NdotH*NdotH ));
}

MaterialValues materialValues(constant AAPLPhysicalLightMaterialUniforms *materialData,
                              vec2 textureCoordinate, vec2 aoCoordinate) {
    MaterialValues mv;
    
#ifdef TEXTURED
    mv.baseColor = srgbToLinear(texture(baseColorTexture, textureCoordinate, 0.0) * frameData->u_baseColor).xyz;
#else
    mv.baseColor = srgbToLinear(materialData->u_baseColor).xyz;
#endif
    
#ifdef AO_TEXTURE
    mv.aoValue = max(srgbToLinear(texture(aoTexture, aoCoordinate, 0.0)).xyz, vec3(controlMask.x));
#else
    mv.aoValue = vec3(1.0);
#endif
    
#ifdef AO_VERTEX
    vec4 vbColor = max(vec4(varOcclusion,varOcclusion,varOcclusion,1), vec4(controlMask.z));
    mv.aoValue *= vbColor.xyz;
#endif
    
    mv.baseColorLuminance = 0.3 * mv.baseColor.x + 0.6 * mv.baseColor.y + 0.1 * mv.baseColor.z; // approximation of luminance
    mv.baseColorHueSat = mv.baseColorLuminance > 0.0 ? mv.baseColor / mv.baseColorLuminance : vec3(1); // remove luminance
    
    mv.specular = materialData->u_specular;
    mv.specularTint = materialData->u_specularTint;
    mv.metallic = materialData->u_metallic;
    mv.sheen = materialData->u_sheen;
    mv.sheenTint = materialData->u_sheenTint;
    mv.roughness = materialData->u_roughness;
    mv.anisotropic = materialData->u_anisotropic;
    mv.clearcoat = materialData->u_clearcoat;
    mv.clearcoatGloss = materialData->u_clearcoatGloss;
    mv.subsurface = materialData->u_subsurface;
    return mv;
}

DerivedShadingValues derivedShadingValues(MaterialValues mv, ShadingValues sv);
DerivedShadingValues derivedShadingValues(MaterialValues mv, ShadingValues sv) {
    DerivedShadingValues dsv;
    dsv.H = normalize(sv.L + sv.V);
    dsv.reflected = reflect(-sv.V, sv.N);
    dsv.NdotL = max(0.0, dot(sv.N, sv.L));
    dsv.NdotV = max(0.0, dot(sv.N, sv.V));
    dsv.NdotH = max(0.0, dot(sv.N, dsv.H));
    dsv.LdotH = max(0.0, dot(sv.L, dsv.H));
    dsv.FL = SchlickFresnel(dsv.NdotL);
    dsv.FV = SchlickFresnel(dsv.NdotV);
    dsv.FH = SchlickFresnel(dsv.LdotH);
    
    dsv.diffuseRoughness = mv.roughness;
    
    dsv.irradianceColor = vec3(0.5,0.5,0.5);// srgbToLinear(textureLod(irradianceSampler, dsv.reflected, mv.roughness * 8.0)).xyz;
    dsv.irradianceColor *= (1 - mv.roughness) * 0.33 + 0.66;
    dsv.reflectedColor = vec3(0,0,0);//srgbToLinear(texture(reflectiveEnvironmentSampler, dsv.reflected)).xyz;
    dsv.environmentColor = vec3(0,0,0);//srgbToLinear(texture(reflectiveEnvironmentSampler, dsv.reflected)).xyz;
    
    // add in a spot to represent the sun
    dsv.environmentColor += vec3(min(1.0, dsv.FL));
    return dsv;
}

vec3 diffuseOutput(MaterialValues mv, ShadingValues sv, DerivedShadingValues dsv);
vec3 diffuseOutput(MaterialValues mv, ShadingValues sv, DerivedShadingValues dsv) {
    // Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
    // and mix in diffuse retro-reflection based on roughness
    float Fd90 = 0.5 + 2.0 * sqr(dsv.LdotH) * dsv.diffuseRoughness;
    float Fd = mix(1.0, Fd90, dsv.FL) + mix(1.0, Fd90, dsv.FV);
    
    // Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
    // 1.25 scale is used to (roughly) preserve albedo
    // Fss90 used to "flatten" retroreflection based on roughness
    float Fss90 = sqr(dsv.LdotH) * dsv.diffuseRoughness;
    float Fss = mix(1.0, Fss90, dsv.FL) * mix(1.0, Fss90, dsv.FV);
    // 1.25 scale is used to (roughly) preserve albedo
    float ss = 1.25 * (Fss * (1.0 / (dsv.NdotL + dsv.NdotV) - 0.5) + 0.5);
    
    vec3 diffuseOutput = ((1.0/PI) * mix(Fd, ss, mv.subsurface) * mv.baseColor) * (1.0 - mv.metallic);
    return diffuseOutput;
}

vec3 clearcoatOutput(MaterialValues mv, ShadingValues sv, DerivedShadingValues dsv);
vec3 clearcoatOutput(MaterialValues mv, ShadingValues sv, DerivedShadingValues dsv) {
    // clearcoat (ior = 1.5 -> F0 = 0.04)
    float Dr = GTR1(dsv.NdotH, mix(.6, 0.001, mv.clearcoatGloss));
    float Fr = mix(0.1, 0.4, dsv.FH);
    float clearcoatRoughness = sqr(dsv.diffuseRoughness * 0.5 + 0.5);
    float Gr = smithG_GGX(dsv.NdotL, clearcoatRoughness) * smithG_GGX(dsv.NdotV, clearcoatRoughness);
    
    vec3 clearcoatOutput = mv.clearcoat * Gr * Fr * Dr * dsv.environmentColor;
    return clearcoatOutput;
}

vec3 specularOutput(MaterialValues mv, ShadingValues sv, DerivedShadingValues dsv);
vec3 specularOutput(MaterialValues mv, ShadingValues sv, DerivedShadingValues dsv) {
    //float specularRoughness = dsv.diffuseRoughness * (1.0 - mv.metallic) + mv.metallic;
    float specularRoughness = mv.roughness * 0.5 + 0.5;
    float aspect = sqrt(1.0 - mv.anisotropic * 0.9);
    //float alphaAniso = specularRoughness;
    float alphaAniso = sqr(specularRoughness);
    float ax = max(0.0001, alphaAniso / aspect);
    float ay = max(0.0001, alphaAniso * aspect);
    float Ds = GTR2_aniso(dsv.NdotH, dot(dsv.H, sv.shadingBasisX), dot(dsv.H, sv.shadingBasisY), ax, ay);
    vec3 Cspec0 = mv.specular * mix(vec3(1.0), mv.baseColorHueSat, mv.specularTint);
    vec3 Fs = mix(Cspec0, vec3(1), dsv.FH);
    float alphaG = sqr(specularRoughness * 0.5 + 0.5);
    float Gs = smithG_GGX(dsv.NdotL, alphaG) * smithG_GGX(dsv.NdotV, alphaG);
    
    vec3 specularOutput = (Ds * Gs * Fs * dsv.irradianceColor) * (1.0 + mv.metallic * mv.baseColor) + mv.metallic * dsv.irradianceColor * mv.baseColor;
    return specularOutput;
}

vec3 sheenOutput(MaterialValues mv, ShadingValues sv, DerivedShadingValues dsv);
vec3 sheenOutput(MaterialValues mv, ShadingValues sv, DerivedShadingValues dsv) {
    vec3 Csheen = mix(vec3(1.0), mv.baseColorHueSat, mv.sheenTint);
    vec3 Fsheen = Csheen * dsv.FV * mv.sheen;
    
    vec3 light_color = vec3(6.0) * dsv.NdotL + (vec3(3.0) * dsv.irradianceColor * (1.0 - dsv.NdotL));
    //vec3 sheenOutput = Fsheen * (1.0 - mv.metallic);
    vec3 sheenOutput = Fsheen;
    return sheenOutput;
}



//
// Illuminate
//


// all input colors must be linear, not SRGB.
//
vec4 illuminate(int sampleNumber, float sampleDivisor,
                MaterialValues mv, ShadingValues sv, DerivedShadingValues dsv);
vec4 illuminate(int sampleNumber, float sampleDivisor,
                MaterialValues mv, ShadingValues sv, DerivedShadingValues dsv) {
    
    // DIFFUSE
    // 2pi to integrate the entire dome, 0.5 as intensity
    vec3 light_color = vec3(2.0 * PI * 0.3) * (dsv.NdotL + dsv.irradianceColor * (1.0 - dsv.NdotL) * mv.aoValue);
    vec3 diffuseOut = diffuseOutput(mv, sv, dsv) * light_color;
    
    // AMBIENCE
    const float environmentContribution = 0.0;
    vec3 ambienceOutput = mv.baseColor * dsv.environmentColor * environmentContribution * mv.aoValue;
    
    // CLEARCOAT
    vec3 clearcoatOut = clearcoatOutput(mv, sv, dsv);
    
    // SPECULAR
    vec3 specularOut = specularOutput(mv, sv, dsv);
    
    // SHEEN
    vec3 sheenOut = sheenOutput(mv, sv, dsv) * light_color;
    
    return vec4(diffuseOut + ambienceOutput + clearcoatOut + specularOut + sheenOut, 1);
}

struct VertexOutput {
    float4 pos [[position]];
    float4 normal;
    float4 color;
    float2 uv;
};

struct VertexInput {
    float4  position [[ attribute(kVertexAttributePosition) ]];
    float4  color    [[ attribute(kVertexAttributeColor)    ]];
    float4  normal   [[ attribute(kVertexAttributeNormal)   ]];
    float4  texcoord [[ attribute(kVertexAttributeTexcoord) ]];
};

vertex VertexOutput vertexLight(VertexInput current [[ stage_in ]],
                                constant AAPLPhysicalLightFrameUniforms *frameData   [[ buffer(kFrameUniformBuffer) ]],
                                constant AAPLPhysicalLightMaterialUniforms *materialData [[ buffer(kMaterialUniformBuffer) ]])
{
    VertexOutput out;
    float4 position = current.position;
    position.w = 1.0;
    out.pos = frameData->projectionView * position;
    out.uv = current.texcoord.xy;
    out.color = current.color;
    out.normal = current.color;
    return out;
}

constexpr sampler testSampler(coord::normalized,
                              address::clamp_to_zero,
                              filter::linear);

fragment float4 fragmentLight(VertexOutput in [[stage_in]],
                              constant AAPLPhysicalLightFrameUniforms *frameData   [[ buffer(kFrameUniformBuffer) ]],
                              constant AAPLPhysicalLightMaterialUniforms *materialData [[ buffer(kMaterialUniformBuffer) ]])
{
    MaterialValues mv = materialValues(materialData, in.uv, in.uv);
    ShadingValues sv;
    
    sv.surfacePosition = in.pos.xyz;
    sv.N = in.normal.xyz;
    sv.V = normalize(vec3(0.2, 0.2, 0.5));
    sv.L = normalize(vec3(0.2, 0.2, 0.8));
    sv.shadingBasisX = vec3(1,0,0);
    sv.shadingBasisY = vec3(0,1,0);
    
    DerivedShadingValues dsv = derivedShadingValues(mv, sv);
    float4 out;
#if 0
    out = illuminate(0, 1.0, mv, sv, dsv);
    out.w = 1.0f;
#else
    out = in.color;
#endif
    
    return out;
}