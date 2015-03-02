// #version 120

attribute vec4 a_position;
varying vec2 uv;

void main(void)
{
	gl_Position = a_position;
    uv = (a_position.xy + 1.0) * 0.5;
}
