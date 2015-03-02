uniform float lightIntensity;

float diff = max(0.0, dot(_surface.normal, _light.direction));
vec3 lmDiffuse = mix(1.0, 0.1, lightIntensity) * (diff * _light.intensity.rgb);

float back = lightIntensity * max(0.0, 0.18 + 0.29 * dot(_surface.normal, -_light.direction));
lmDiffuse += (back * _light.intensity.rgb);

// rim/fresnel
float fn = lightIntensity * 1.0 * pow(1.0 - dot(_surface.normal, _surface.view), 1.3);
lmDiffuse += (fn * _light.intensity.rgb);

_lightingContribution.diffuse += lmDiffuse;
