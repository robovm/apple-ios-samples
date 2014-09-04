/*
     File: Imaging.c
 Abstract: 
  Version: 1.3
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

//
//  Simple 2D image processing using OpenGL ES1.1
//
//  The key concepts here are described at
//  http://www.graficaobscura.com/interp/index.html
//  http://www.graficaobscura.com/matrix/index.html
//
//  The only tricky part is how to process inputs outside of [0..1] in the fixed-function pipeline.
//  Simple algebra provides a solution for extrapolation to  [0..2]:
//
//  lerp = Src*t + Dst*(1-t), where (Src, Dst, t) [0..1]
//  if t = 2, then
//  lerp = Src*(2t) + Dst*(1-2t)
//       = 2(Src*t  + Dst*(0.5-t))
//
//  Now, the inputs (Src, Dst, t) are inside [0..1], and the final multiply by 2 can be done with
//  TexEnv. Extrapolation by values larger than 2 can be handled by iteration.
//
//  With that solved, the rest of the problem is simply mapping math operations to TexEnv state.
//  Equations that are too complex to fit in the available texture units have to be broken apart
//  into multiple passes. In that case, a scratch FBO is used to store intermediate results.
//
//  This sample demonstrates mapping simple filters like Brightness, Contrast, Saturation,
//  Hue rotation, and Sharpness to TexEnv. Additional filters such as Convolution, Invert,
//  Sepia, etc can be similarly implemented.
//
//  For details on the available TexEnv COMBINE operators, see the ES1.1 specification, or
//  the equivalent desktop GL extensions:
//  http://www.opengl.org/registry/specs/ARB/texture_env_combine.txt
//  http://www.opengl.org/registry/specs/ARB/texture_env_dot3.txt
//
//  Note: the PowerVR MBX does not support all possible COMBINE state permutations. A debug utility
//  is used here to validate the TexEnv state against known hardware errata.
//


#include <sys/time.h>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include "Texture.h"


// Information about the GL renderer
RendererInfo renderer;
// Framebuffer objects
GLuint SystemFBO, DegenFBO, ScratchFBO;
// Images used for filtering
Image Input, Half, Degen, Scratch;
// Geometry for a fullscreen quad
V2fT2f fullquad[4] = {
	{ 0, 0, 0, 0 },
	{ 1, 0, 1, 0 },
	{ 0, 1, 0, 1 },
	{ 1, 1, 1, 1 },
};
// Geometry for a fullscreen quad, flipping texcoords upside down
V2fT2f flipquad[4] = {
	{ 0, 0, 0, 1 },
	{ 1, 0, 1, 1 },
	{ 0, 1, 0, 0 },
	{ 1, 1, 1, 0 },
};


// The following filters change the TexEnv state in various ways.
// To reduce state change overhead, the convention adopted here is
// that each filter is responsible for setting up common state, and
// restoring uncommon state to the default.
//
// Common state for this application is defined as:
// GL_TEXTURE_ENV_MODE
// GL_COMBINE_RGB, GL_COMBINE_ALPHA
// GL_SRC[012]_RGB, GL_SRC[012]_ALPHA
// GL_TEXTURE_ENV_COLOR
//
// Uncommon state for this application is defined as:
// GL_OPERAND[012]_RGB, GL_OPERAND[012]_ALPHA
// GL_RGB_SCALE, GL_ALPHA_SCALE
//
// For all filters, the texture's alpha channel is passed through unchanged.
// If you need the alpha channel for compositing purposes, be mindful of
// premultiplication that may have been performed by your image loader.


static void brightness(V2fT2f *quad, float t)	// t [0..2]
{
	// One pass using one unit:
	// brightness < 1.0 biases towards black
	// brightness > 1.0 biases towards white
	//
	// Note: this additive definition of brightness is
	// different than what matrix-based adjustment produces,
	// where the brightness factor is a scalar multiply.
	//
	// A +/-1 bias will produce the full range from black to white,
	// whereas the scalar multiply can never reach full white.

	glVertexPointer  (2, GL_FLOAT, sizeof(V2fT2f), &quad[0].x);
	glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	if (t > 1.0f)
	{
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_ADD);
		glColor4f(t-1, t-1, t-1, t-1);
	}
	else
	{
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_SUBTRACT);
		glColor4f(1-t, 1-t, 1-t, 1-t);
	}
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PRIMARY_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_TEXTURE);

	validateTexEnv();
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}


static void contrast(V2fT2f *quad, float t)	// t [0..2]
{
	GLfloat h = t*0.5f;
	
	// One pass using two units:
	// contrast < 1.0 interpolates towards grey
	// contrast > 1.0 extrapolates away from grey
	//
	// Here, the general extrapolation 2*(Src*t + Dst*(0.5-t))
	// can be simplified, because Dst is a constant (grey).
	// That results in: 2*(Src*t + 0.25 - 0.5*t)
	//
	// Unit0 calculates Src*t
	// Unit1 adds 0.25 - 0.5*t
	// Since 0.5*t will be in [0..0.5], it can be biased up and the addition done in signed space.

	glVertexPointer  (2, GL_FLOAT, sizeof(V2fT2f), &quad[0].x);
	glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_MODULATE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PRIMARY_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_TEXTURE);

	glActiveTexture(GL_TEXTURE1);
	glEnable(GL_TEXTURE_2D);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_ADD_SIGNED);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_PREVIOUS);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PRIMARY_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB,     GL_SRC_ALPHA);
	glTexEnvi(GL_TEXTURE_ENV, GL_RGB_SCALE,        2);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_PREVIOUS);

	glColor4f(h, h, h, 0.75 - 0.5 * h);	// 2x extrapolation
	validateTexEnv();
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Restore state
	glDisable(GL_TEXTURE_2D);
	glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB,     GL_SRC_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_RGB_SCALE,        1);
	glActiveTexture(GL_TEXTURE0);
}


static void greyscale(V2fT2f *quad, float t)	// t = 1 for standard perceptual weighting
{
	GLfloat lerp[4] = { 1.0, 1.0, 1.0, 0.5 };
	GLfloat avrg[4] = { .667, .667, .667, 0.5 };	// average
	GLfloat prcp[4] = { .646, .794, .557, 0.5 };	// perceptual NTSC
	GLfloat dot3[4] = { prcp[0]*t+avrg[0]*(1-t), prcp[1]*t+avrg[1]*(1-t), prcp[2]*t+avrg[2]*(1-t), 0.5 };
	
	// One pass using two units:
	// Unit 0 scales and biases into [0.5..1.0]
	// Unit 1 dot products with perceptual weights

	glVertexPointer  (2, GL_FLOAT, sizeof(V2fT2f), &quad[0].x);
	glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_INTERPOLATE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_CONSTANT);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC2_RGB,         GL_CONSTANT);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_TEXTURE);
	glTexEnvfv(GL_TEXTURE_ENV,GL_TEXTURE_ENV_COLOR, lerp);

	// Note: we prefer to dot product with primary color, because
	// the constant color is stored in limited precision on MBX
	glActiveTexture(GL_TEXTURE1);
	glEnable(GL_TEXTURE_2D);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_DOT3_RGB);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_PREVIOUS);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PRIMARY_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_PREVIOUS);

	glColor4f(dot3[0], dot3[1], dot3[2], dot3[3]);
	validateTexEnv();
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Restore state
	glDisable(GL_TEXTURE_2D);
	glActiveTexture(GL_TEXTURE0);
}


static void extrapolate(V2fT2f *quad, float t)	// t [0..2]
{
	int i;
		
	// t < 1.0 interpolates towards degenerate image
	// t > 1.0 extrapolates away from degenerate image
	//
	// Unlike the simpler filters, extrapolation from an arbitrary image
	// requires two passes to implement 2*(Src*t + Dst(0.5-t)).
	//
	// The extrapolation works in both directions, but when t <= 1.0f,
	// the interpolation can be done in a single pass, which is faster.
	//
	// The degenerate image to extrapolate from is generated
	// outside of this function. It can be cached for a static image,
	// or regenerated every frame for dynamic content.

	if (t <= 1.0f)
	{
		// One pass using two units:
		// Unit 0 samples the input image
		// Unit 1 interpolates towards the degenerate image

		glVertexPointer  (2, GL_FLOAT, sizeof(V2fT2f), &quad[0].x);
		glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
		glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_REPLACE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_TEXTURE);

		glClientActiveTexture(GL_TEXTURE1);
		glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_2D, Degen.texID);
		glEnable(GL_TEXTURE_2D);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_INTERPOLATE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PREVIOUS);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC2_RGB,         GL_PRIMARY_COLOR);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_PREVIOUS);
		glColor4f(0.0, 0.0, 0.0, 1.0f-t);
		validateTexEnv();
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

		// Restore state
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glClientActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, Half.texID);
		glDisable(GL_TEXTURE_2D);
		glActiveTexture(GL_TEXTURE0);
	}
	else
	{
		GLint fbo, tex, viewport[4], blend;
		float h = t*0.5f;
		V2fT2f flipquad[4];

		for (i = 0; i < 4; i++)
		{
			flipquad[i].s = quad[i].s;
			flipquad[i].t = quad[3-i].t;
		}
		
		// Push state
		glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, &fbo);
		glGetIntegerv(GL_TEXTURE_BINDING_2D, &tex);
		glGetIntegerv(GL_VIEWPORT, viewport);
		glGetIntegerv(GL_BLEND, &blend);
	
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, ScratchFBO);
		glViewport(0, 0, Scratch.wide*Scratch.s, Scratch.high*Scratch.t);
		glClear(GL_COLOR_BUFFER_BIT);
		glDisable(GL_BLEND);
		glBindTexture(GL_TEXTURE_2D, Degen.texID);
		glVertexPointer  (2, GL_FLOAT, sizeof(V2fT2f), &quad[0].x);
		glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &flipquad[0].s);
		glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_MODULATE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PRIMARY_COLOR);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_TEXTURE);

		// Note: we prefer to sample 0.5 from a texture, because
		// the constant color is stored in limited precision on MBX
		glActiveTexture(GL_TEXTURE1);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, Half.texID);
		glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
		if (h < 0.5)
		{
			float bias = 0.5-h;
			
			// First pass: 0.5 + degenerate * bias;
			glColor4f(bias, bias, bias, 1.0);
			glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_ADD);
		}
		else
		{
			float bias = h-0.5;
			
			// First pass: 0.5 - degenerate * bias;
			glColor4f(bias, bias, bias, 1.0);
			glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_SUBTRACT);
		}
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PREVIOUS);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_PREVIOUS);
		validateTexEnv();
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
		// Second pass: 2.0 * (Src * h + first - 0.5)
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, fbo);
		glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
		if (blend) glEnable(GL_BLEND);
		glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
		glClientActiveTexture(GL_TEXTURE1);
		glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glBindTexture(GL_TEXTURE_2D, Scratch.texID);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_ADD_SIGNED);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,    GL_PREVIOUS);
		glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,    GL_TEXTURE);
		glTexEnvi(GL_TEXTURE_ENV, GL_RGB_SCALE,   2);
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, tex);
		glColor4f(h, h, h, 1.0);
		validateTexEnv();
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
		// Restore state
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glClientActiveTexture(GL_TEXTURE0);
		glActiveTexture(GL_TEXTURE1);
		glTexEnvi(GL_TEXTURE_ENV, GL_RGB_SCALE,   1);
		glBindTexture(GL_TEXTURE_2D, Half.texID);
		glDisable(GL_TEXTURE_2D);
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, tex);
	}
}


// Matrix Utilities for Hue rotation
static void matrixmult(float a[4][4], float b[4][4], float c[4][4])
{
	int x, y;
	float temp[4][4];

	for(y=0; y<4; y++)
		for(x=0; x<4; x++)
			temp[y][x] = b[y][0] * a[0][x] + b[y][1] * a[1][x] + b[y][2] * a[2][x] + b[y][3] * a[3][x];
	for(y=0; y<4; y++)
		for(x=0; x<4; x++)
			c[y][x] = temp[y][x];
}


static void xrotatemat(float mat[4][4], float rs, float rc)
{
	mat[0][0] = 1.0;
	mat[0][1] = 0.0;
	mat[0][2] = 0.0;
	mat[0][3] = 0.0;

	mat[1][0] = 0.0;
	mat[1][1] = rc;
	mat[1][2] = rs;
	mat[1][3] = 0.0;

	mat[2][0] = 0.0;
	mat[2][1] = -rs;
	mat[2][2] = rc;
	mat[2][3] = 0.0;

	mat[3][0] = 0.0;
	mat[3][1] = 0.0;
	mat[3][2] = 0.0;
	mat[3][3] = 1.0;
 }


static void yrotatemat(float mat[4][4], float rs, float rc)
{
	mat[0][0] = rc;
	mat[0][1] = 0.0;
	mat[0][2] = -rs;
	mat[0][3] = 0.0;

	mat[1][0] = 0.0;
	mat[1][1] = 1.0;
	mat[1][2] = 0.0;
	mat[1][3] = 0.0;

	mat[2][0] = rs;
	mat[2][1] = 0.0;
	mat[2][2] = rc;
	mat[2][3] = 0.0;

	mat[3][0] = 0.0;
	mat[3][1] = 0.0;
	mat[3][2] = 0.0;
	mat[3][3] = 1.0;
}


static void zrotatemat(float mat[4][4], float rs, float rc)
{
	mat[0][0] = rc;
	mat[0][1] = rs;
	mat[0][2] = 0.0;
	mat[0][3] = 0.0;

	mat[1][0] = -rs;
	mat[1][1] = rc;
	mat[1][2] = 0.0;
	mat[1][3] = 0.0;

	mat[2][0] = 0.0;
	mat[2][1] = 0.0;
	mat[2][2] = 1.0;
	mat[2][3] = 0.0;

	mat[3][0] = 0.0;
	mat[3][1] = 0.0;
	mat[3][2] = 0.0;
	mat[3][3] = 1.0;
}


static void huematrix(GLfloat mat[4][4], float angle)
{
	float mag, rot[4][4];
	float xrs, xrc;
	float yrs, yrc;
	float zrs, zrc;

	// Rotate the grey vector into positive Z
	mag = sqrt(2.0);
	xrs = 1.0/mag;
	xrc = 1.0/mag;
	xrotatemat(mat, xrs, xrc);
	mag = sqrt(3.0);
	yrs = -1.0/mag;
	yrc = sqrt(2.0)/mag;
	yrotatemat(rot, yrs, yrc);
	matrixmult(rot, mat, mat);

	// Rotate the hue
	zrs = sin(angle);
	zrc = cos(angle);
	zrotatemat(rot, zrs, zrc);
	matrixmult(rot, mat, mat);

	// Rotate the grey vector back into place
	yrotatemat(rot, -yrs, yrc);
	matrixmult(rot,  mat, mat);
	xrotatemat(rot, -xrs, xrc);
	matrixmult(rot,  mat, mat);
}


static void hue(V2fT2f *quad, float t)	// t [0..2] == [-180..180] degrees
{
	GLfloat mat[4][4];
	GLfloat lerp[4] = { 1.0, 1.0, 1.0, 0.5 };

	// Color matrix rotation can be expressed as three dot products
	// Each DOT3 needs inputs prescaled to [0.5..1.0]

	// Construct 3x3 matrix
	huematrix(mat, (t-1.0)*M_PI);

	// Prescale matrix weights
	mat[0][0] *= 0.5; mat[0][0] += 0.5;
	mat[0][1] *= 0.5; mat[0][1] += 0.5;
	mat[0][2] *= 0.5; mat[0][2] += 0.5;
	mat[0][3] = 1.0;

	mat[1][0] *= 0.5; mat[1][0] += 0.5;
	mat[1][1] *= 0.5; mat[1][1] += 0.5;
	mat[1][2] *= 0.5; mat[1][2] += 0.5;
	mat[1][3] = 1.0;

	mat[2][0] *= 0.5; mat[2][0] += 0.5;
	mat[2][1] *= 0.5; mat[2][1] += 0.5;
	mat[2][2] *= 0.5; mat[2][2] += 0.5;
	mat[2][3] = 1.0;

	glVertexPointer  (2, GL_FLOAT, sizeof(V2fT2f), &quad[0].x);
	glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_INTERPOLATE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_CONSTANT);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC2_RGB,         GL_CONSTANT);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_TEXTURE);
	glTexEnvfv(GL_TEXTURE_ENV,GL_TEXTURE_ENV_COLOR, lerp);

	// Note: we prefer to dot product with primary color, because
	// the constant color is stored in limited precision on MBX
	glActiveTexture(GL_TEXTURE1);
	glEnable(GL_TEXTURE_2D);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_DOT3_RGB);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_PREVIOUS);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PRIMARY_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_PREVIOUS);

	// Red channel
	glColorMask(1,0,0,0);
	glColor4f(mat[0][0], mat[0][1], mat[0][2], mat[0][3]);
	validateTexEnv();
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Green channel
	glColorMask(0,1,0,0);
	glColor4f(mat[1][0], mat[1][1], mat[1][2], mat[1][3]);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	// Blue channel
	glColorMask(0,0,1,0);
	glColor4f(mat[2][0], mat[2][1], mat[2][2], mat[2][3]);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	// Restore state
	glDisable(GL_TEXTURE_2D);
	glActiveTexture(GL_TEXTURE0);
	glColorMask(1,1,1,1);
}


static void blur(V2fT2f *quad, float t)	// t = 1
{
	GLint tex;
	V2fT2f tmpquad[4];
	float offw = t / Input.wide;
	float offh = t / Input.high;
	int i;
	
	glGetIntegerv(GL_TEXTURE_BINDING_2D, &tex);

	// Three pass small blur, using rotated pattern to sample 17 texels:
	//
	// .\/.. 
	// ./\\/ 
	// \/X/\   rotated samples filter across texel corners
	// /\\/. 
	// ../\. 
	
	// Pass one: center nearest sample
	glVertexPointer  (2, GL_FLOAT, sizeof(V2fT2f), &quad[0].x);
	glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &quad[0].s);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glColor4f(1.0/5, 1.0/5, 1.0/5, 1.0);
	validateTexEnv();
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	// Pass two: accumulate two rotated linear samples
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	for (i = 0; i < 4; i++)
	{
		tmpquad[i].x = quad[i].s + 1.5 * offw;
		tmpquad[i].y = quad[i].t + 0.5 * offh;
		tmpquad[i].s = quad[i].s - 1.5 * offw;
		tmpquad[i].t = quad[i].t - 0.5 * offh;
	}
	glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &tmpquad[0].x);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glActiveTexture(GL_TEXTURE1);
	glEnable(GL_TEXTURE_2D);
	glClientActiveTexture(GL_TEXTURE1);
	glTexCoordPointer(2, GL_FLOAT, sizeof(V2fT2f), &tmpquad[0].s);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glBindTexture(GL_TEXTURE_2D, tex);
	glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB,      GL_INTERPOLATE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_RGB,         GL_TEXTURE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC1_RGB,         GL_PREVIOUS);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC2_RGB,         GL_PRIMARY_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND2_RGB,     GL_SRC_COLOR);
	glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,    GL_REPLACE);
	glTexEnvi(GL_TEXTURE_ENV, GL_SRC0_ALPHA,       GL_PRIMARY_COLOR);

	glColor4f(0.5, 0.5, 0.5, 2.0/5);
	validateTexEnv();
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	// Pass three: accumulate two rotated linear samples
	for (i = 0; i < 4; i++)
	{
		tmpquad[i].x = quad[i].s - 0.5 * offw;
		tmpquad[i].y = quad[i].t + 1.5 * offh;
		tmpquad[i].s = quad[i].s + 0.5 * offw;
		tmpquad[i].t = quad[i].t - 1.5 * offh;
	}
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	// Restore state
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glClientActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, Half.texID);
	glDisable(GL_TEXTURE_2D);
	glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND2_RGB,     GL_SRC_ALPHA);
	glActiveTexture(GL_TEXTURE0);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glDisable(GL_BLEND);
}


void drawGL(int wide, int high, float val, int mode)
{
	static int prevmode = -1;
	typedef void (*procfunc)(V2fT2f *, float);

	typedef struct {
		procfunc func;
		procfunc degen;
	} Filter;

	const Filter filter[] = {
		{ brightness             },
		{ contrast               },
		{ extrapolate, greyscale },
		{ hue                    },
		{ extrapolate, blur      },	// The blur could be exaggerated by downsampling to half size
	};
	#define NUM_FILTERS (sizeof(filter)/sizeof(filter[0]))
	rt_assert(mode < NUM_FILTERS);
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrthof(0, wide, 0, high, -1, 1);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glScalef(wide, high, 1);
	
	glBindTexture(GL_TEXTURE_2D, Input.texID);
		
	if (prevmode != mode)
	{
		prevmode = mode;
		if (filter[mode].degen)
		{
			// Cache degenerate image, potentially a different size than the system framebuffer
			glBindFramebufferOES(GL_FRAMEBUFFER_OES, DegenFBO);
			glViewport(0, 0, Degen.wide*Degen.s, Degen.high*Degen.t);
			// The entire framebuffer won't be written to if the image was padded to POT.
			// In this case, clearing is a performance win on TBDR systems.
			glClear(GL_COLOR_BUFFER_BIT);
			glDisable(GL_BLEND);
			filter[mode].degen(fullquad, 1.0);
			glBindFramebufferOES(GL_FRAMEBUFFER_OES, SystemFBO);
		}
	}

	// Render filtered image to system framebuffer
	glViewport(0, 0, wide, high);
	filter[mode].func(flipquad, val);
	glCheckError();
}


void initGL(void)
{
	int i;

	// Query renderer capabilities that affect this app's rendering paths
	renderer.extension[APPLE_texture_2D_limited_npot] =
		(0 != strstr((char *)glGetString(GL_EXTENSIONS), "GL_APPLE_texture_2D_limited_npot"));
	renderer.extension[IMG_texture_format_BGRA8888] =
		(0 != strstr((char *)glGetString(GL_EXTENSIONS), "GL_IMG_texture_format_BGRA8888"));
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &renderer.maxTextureSize);

	// Constant state for the lifetime of the app-- position and unit0 are always used
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

	// Load image into texture
	loadTexture("Image.png", &Input, &renderer);

	// Modify quad texcoords to match (possibly padded) image
	for (i = 0; i < 4; i++)
	{
		fullquad[i].s *= Input.s;
		fullquad[i].t *= Input.t;
		flipquad[i].s *= Input.s;
		flipquad[i].t *= Input.t;
	}
	
	// Create 1x1 for default constant texture
	// To enable a texture unit, a valid texture has to be bound even if the combine modes do not access it
	GLubyte half[4] = { 0x80, 0x80, 0x80, 0x80 };
	glActiveTexture(GL_TEXTURE1);
	glGenTextures(1, &Half.texID);
	Half.wide = Half.high = 1;
	Half.s = Half.t = 1.0;
	glBindTexture(GL_TEXTURE_2D, Half.texID);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, half);
	glActiveTexture(GL_TEXTURE0);

	// Remember the FBO being used for the display framebuffer
	glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, (GLint *)&SystemFBO);

	// Create scratch textures and FBOs
	glGenTextures(1, &Degen.texID);
	Degen.wide = Input.wide;
	Degen.high = Input.high;
	Degen.s = Input.s;
	Degen.t = Input.t;
	glBindTexture(GL_TEXTURE_2D, Degen.texID);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Degen.wide, Degen.high, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glGenFramebuffersOES(1, &DegenFBO);
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, DegenFBO);
	glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, Degen.texID, 0);
	rt_assert(GL_FRAMEBUFFER_COMPLETE_OES == glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
	
	glGenTextures(1, &Scratch.texID);
	Scratch.wide = Input.wide;
	Scratch.high = Input.high;
	Scratch.s = Input.s;
	Scratch.t = Input.t;
	glBindTexture(GL_TEXTURE_2D, Scratch.texID);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Scratch.wide, Scratch.high, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glGenFramebuffersOES(1, &ScratchFBO);
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, ScratchFBO);
	glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, Scratch.texID, 0);
	rt_assert(GL_FRAMEBUFFER_COMPLETE_OES == glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, SystemFBO);
	
	glCheckError();
}
