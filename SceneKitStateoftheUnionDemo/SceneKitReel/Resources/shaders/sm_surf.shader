uniform float surfIntensity;

float time = u_time * 0.5;
float factor = _surface.specular.r * 5.;

vec2 p = _surface.diffuseTexcoord * 2. * 6.28318530718 - 20.;
vec2 i = p;
float c = 1.0;
float inten = .05;

for (int n = 0; n < 5; n++)
{
    float t = time * (1.0 - (3.5 / float(n+1)));
    i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
    c += 1.0/length(vec2(p.y / (sin(i.x+t)/inten), p.y / (cos(i.y+t)/inten)));
}
c = 1.55-sqrt(c/5.);

vec3 col = clamp(vec3(pow(abs(c), 6.0)) + vec3(0.0, 0.35, 0.5), 0.0, 1.0);
_surface.emission.rgb = mix(_surface.emission.rgb,  col, surfIntensity * factor);
_surface.diffuse.rgb = mix(_surface.diffuse.rgb,  vec3(0.), surfIntensity * factor);
