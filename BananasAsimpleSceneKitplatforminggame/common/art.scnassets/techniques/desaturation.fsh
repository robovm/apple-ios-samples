uniform sampler2D colorSampler;
uniform float Saturation;

varying vec2 uv;

void main() {
	vec4 color = texture2D(colorSampler, uv);
    
    vec4 scaledColor = color * vec4(0.3, 0.59, 0.11, 1.0);
    float luminance = scaledColor.r + scaledColor.g + scaledColor.b ;
    vec4 lerped = mix(vec4(luminance,luminance,luminance,color.a), color, Saturation);
    gl_FragColor = lerped;
}

