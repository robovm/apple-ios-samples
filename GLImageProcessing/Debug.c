/*
     File: Debug.c
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

#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#include "Debug.h"


// Debug utility: validate the current texture environment against MBX errata.
// Assert if we use a state combination not supported by the MBX hardware.
void validateTexEnv(void)
{
	#if DEBUG
	typedef struct {
		GLint combine;
		GLint src[3];
		GLint op[3];
		GLint scale;
	} Channel;

	typedef struct {
		GLint enabled;
		GLint binding;
		GLint mode;
		Channel rgb;
		Channel a;
		GLfloat color[4];
	} TexEnv;

	// MBX supports two texture units
	TexEnv unit[2];
	GLint active;
	int i, prev = -1;

	glGetIntegerv(GL_ACTIVE_TEXTURE, &active);
	for (i = 0; i < 2; i++)
	{
		glActiveTexture(GL_TEXTURE0+i);
		unit[i].enabled = glIsEnabled(GL_TEXTURE_2D);
		glGetIntegerv(GL_TEXTURE_BINDING_2D, &unit[i].binding);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE,  &unit[i].mode);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_COMBINE_RGB,       &unit[i].rgb.combine);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_SRC0_RGB,          &unit[i].rgb.src[0]);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_SRC1_RGB,          &unit[i].rgb.src[1]);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_SRC2_RGB,          &unit[i].rgb.src[2]);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_OPERAND0_RGB,      &unit[i].rgb.op[0]);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_OPERAND1_RGB,      &unit[i].rgb.op[1]);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_OPERAND2_RGB,      &unit[i].rgb.op[2]);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_RGB_SCALE,         &unit[i].rgb.scale);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_COMBINE_ALPHA,     &unit[i].a.combine);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_SRC0_ALPHA,        &unit[i].a.src[0]);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_SRC1_ALPHA,        &unit[i].a.src[1]);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_SRC2_ALPHA,        &unit[i].a.src[2]);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA,    &unit[i].a.op[0]);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA,    &unit[i].a.op[1]);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_OPERAND2_ALPHA,    &unit[i].a.op[2]);
		glGetTexEnviv(GL_TEXTURE_ENV, GL_ALPHA_SCALE,       &unit[i].a.scale);
		glGetTexEnvfv(GL_TEXTURE_ENV, GL_TEXTURE_ENV_COLOR, &unit[i].color[0]);

		if (unit[i].enabled == 0) continue;
		if (unit[i].mode != GL_COMBINE) continue;

		// PREVIOUS on unit 0 means PRIMARY_COLOR.
		if (i == 0)
		{
			int j;

			for (j = 0; j < 3; j++)
			{
				if (unit[i].rgb.src[j] == GL_PREVIOUS)
					unit[i].rgb.src[j] = GL_PRIMARY_COLOR;
				if (unit[i].a.src[j] == GL_PREVIOUS)
					unit[i].a.src[j] = GL_PRIMARY_COLOR;
			}
		}

		// If the value of COMBINE_RGB is MODULATE, only one of the two multiplicands can use an ALPHA operand.
		rt_assert(!(unit[i].rgb.combine == GL_MODULATE &&
		           (unit[i].rgb.op[0] == GL_SRC_ALPHA || unit[i].rgb.op[0] == GL_ONE_MINUS_SRC_ALPHA) &&
		           (unit[i].rgb.op[1] == GL_SRC_ALPHA || unit[i].rgb.op[1] == GL_ONE_MINUS_SRC_ALPHA)));

		// If the value of COMBINE_RGB is INTERPOLATE and either SRC0 or SRC1 uses an ALPHA operand, SRC2 can not be CONSTANT or PRIMARY_COLOR or use an ALPHA operand.
		rt_assert(!(unit[i].rgb.combine == GL_INTERPOLATE &&
		           (unit[i].rgb.op[0] == GL_SRC_ALPHA || unit[i].rgb.op[0] == GL_ONE_MINUS_SRC_ALPHA ||
		            unit[i].rgb.op[1] == GL_SRC_ALPHA || unit[i].rgb.op[1] == GL_ONE_MINUS_SRC_ALPHA) &&
		           (unit[i].rgb.op[2] == GL_SRC_ALPHA || unit[i].rgb.op[2] == GL_ONE_MINUS_SRC_ALPHA ||
		            unit[i].rgb.src[2] == GL_CONSTANT || unit[i].rgb.src[2] == GL_PRIMARY_COLOR)));

		// If the value of COMBINE_RGB is INTERPOLATE and SRC0 and SRC1 are CONSTANT or PRIMARY COLOR, SRC2 can not be CONSTANT or PRIMARY_COLOR or use an ALPHA operand.
		rt_assert(!(unit[i].rgb.combine == GL_INTERPOLATE &&
		          ((unit[i].rgb.src[0] == GL_CONSTANT      && unit[i].rgb.src[1] == GL_CONSTANT) ||
		           (unit[i].rgb.src[0] == GL_PRIMARY_COLOR && unit[i].rgb.src[1] == GL_PRIMARY_COLOR)) &&
		           (unit[i].rgb.op[2] == GL_SRC_ALPHA || unit[i].rgb.op[2] == GL_ONE_MINUS_SRC_ALPHA ||
		            unit[i].rgb.src[2] == GL_CONSTANT || unit[i].rgb.src[2] == GL_PRIMARY_COLOR)));

		// If the value of COMBINE_RGB is DOT3_RGB or DOT3_RGBA, only one of the sources can be PRIMARY_COLOR or use an ALPHA operand.
		rt_assert(!((unit[i].rgb.combine == GL_DOT3_RGB || unit[i].rgb.combine == GL_DOT3_RGBA) &&
		            (unit[i].rgb.src[0] == GL_PRIMARY_COLOR || unit[i].rgb.op[0] == GL_SRC_ALPHA || unit[i].rgb.op[0] == GL_ONE_MINUS_SRC_ALPHA) &&
		            (unit[i].rgb.src[1] == GL_PRIMARY_COLOR || unit[i].rgb.op[1] == GL_SRC_ALPHA || unit[i].rgb.op[1] == GL_ONE_MINUS_SRC_ALPHA)));

		// If the value of COMBINE_RGB is SUBTRACT, SCALE_RGB must be 1.0.
		rt_assert(!(unit[i].rgb.combine == GL_SUBTRACT && unit[i].rgb.scale != 1));

		if (unit[i].rgb.combine != GL_DOT3_RGBA)
		{
			// If the value of COMBINE_ALPHA is MODULATE or INTERPOLATE, only one of the two multiplicands can be CONSTANT.
			rt_assert(!(unit[i].a.combine == GL_MODULATE    &&  unit[i].a.src[0] == GL_CONSTANT && unit[i].a.src[1] == GL_CONSTANT));
			rt_assert(!(unit[i].a.combine == GL_INTERPOLATE && (unit[i].a.src[0] == GL_CONSTANT || unit[i].a.src[1] == GL_CONSTANT) && unit[i].a.src[2] == GL_CONSTANT));
	
			// If the value of COMBINE_ALPHA is SUBTRACT, SCALE_ALPHA must be 1.0.
			rt_assert(!(unit[i].a.combine == GL_SUBTRACT && unit[i].a.scale != 1));
		}
		
		// The value of TEXTURE_ENV_COLOR must be the same for all texture units that CONSTANT is used on.
		if (unit[i].rgb.src[0] == GL_CONSTANT ||
		   (unit[i].rgb.src[1] == GL_CONSTANT && unit[i].rgb.combine != GL_REPLACE) ||
		   (unit[i].rgb.src[2] == GL_CONSTANT && unit[i].rgb.combine == GL_INTERPOLATE) ||
		   (unit[i].rgb.combine != GL_DOT3_RGBA &&
		   (unit[i].a.src[0] == GL_CONSTANT ||
		   (unit[i].a.src[1] == GL_CONSTANT && unit[i].a.combine != GL_REPLACE) ||
		   (unit[i].a.src[2] == GL_CONSTANT && unit[i].a.combine == GL_INTERPOLATE))))
		{
			if (prev >= 0)
				rt_assert(!(unit[prev].color[0] != unit[i].color[0] ||
							unit[prev].color[1] != unit[i].color[1] ||
							unit[prev].color[2] != unit[i].color[2] ||
							unit[prev].color[3] != unit[i].color[3]));
			prev = i;
		}
	}

	glActiveTexture(active);
	glCheckError();
	#endif /* DEBUG */
}
