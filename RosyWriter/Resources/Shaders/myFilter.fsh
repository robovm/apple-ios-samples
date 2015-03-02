
precision mediump float;

varying mediump vec2 coordinate;
uniform sampler2D videoframe;

void main()
{
	vec4 color = texture2D(videoframe, coordinate);
	gl_FragColor.bgra = vec4(color.b, 0.0 * color.g, color.r, color.a);
}