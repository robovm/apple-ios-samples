uniform float Amplitude;

float eval(vec3 p) {
    float py = p.y;
    p.y = 0.;
    return length(p) + 0.25 * Amplitude*sin(0.5 * py + u_time * 5.0);
}

vec3 computeNormal(vec3 p, vec3 n) {
    vec3 e = vec3(0.1, 0, 0);
    return normalize(n - Amplitude * vec3(	eval(p + e.xyy) - eval(p - e.xyy),
                                          eval(p + e.yxy) - eval(p - e.yxy),
                                          eval(p + e.yyx) - eval(p - e.yyx)) );
}

#pragma body

vec3 p = _geometry.position.xyz;

float disp = eval(p);
vec2 nrm = normalize(_geometry.normal.xz);

_geometry.position.xz = nrm * disp;
_geometry.normal.xyz = computeNormal(p, _geometry.normal);

