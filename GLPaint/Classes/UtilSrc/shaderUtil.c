/*
     File: shaderUtil.c
 Abstract: Functions that compile, link and validate shader programs.
  Version: 1.13
 
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include "ShaderUtil.h"
#include "debug.h"


#define LogInfo printf
#define LogError printf


/* Compile a shader from the provided source(s) */
GLint glueCompileShader(GLenum target, GLsizei count, const GLchar **sources, GLuint *shader)
{
	GLint logLength, status;

	*shader = glCreateShader(target);	
	glShaderSource(*shader, count, sources, NULL);
	glCompileShader(*shader);
	glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetShaderInfoLog(*shader, logLength, &logLength, log);
		LogInfo("Shader compile log:\n%s", log);
		free(log);
	}

	glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
	if (status == 0)
	{
		int i;
		
		LogError("Failed to compile shader:\n");
		for (i = 0; i < count; i++)
			LogInfo("%s", sources[i]);	
	}
	glError();
	
	return status;
}


/* Link a program with all currently attached shaders */
GLint glueLinkProgram(GLuint program)
{
	GLint logLength, status;
	
	glLinkProgram(program);
	glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(program, logLength, &logLength, log);
		LogInfo("Program link log:\n%s", log);
		free(log);
	}
	
	glGetProgramiv(program, GL_LINK_STATUS, &status);
	if (status == 0)
		LogError("Failed to link program %d", program);
	glError();
	
	return status;
}


/* Validate a program (for i.e. inconsistent samplers) */
GLint glueValidateProgram(GLuint program)
{
	GLint logLength, status;
	
	glValidateProgram(program);
	glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(program, logLength, &logLength, log);
		LogInfo("Program validate log:\n%s", log);
		free(log);
	}

	glGetProgramiv(program, GL_VALIDATE_STATUS, &status);
	if (status == 0)
		LogError("Failed to validate program %d", program);
	glError();
	
	return status;
}


/* Return named uniform location after linking */
GLint glueGetUniformLocation(GLuint program, const GLchar *uniformName)
{
    GLint loc;

    loc = glGetUniformLocation(program, uniformName);

    return loc;
}


/* Convenience wrapper that compiles, links, enumerates uniforms and attribs */
GLint glueCreateProgram(const GLchar *vertSource, const GLchar *fragSource,
                       GLsizei attribNameCt, const GLchar **attribNames, 
                       const GLint *attribLocations,
                       GLsizei uniformNameCt, const GLchar **uniformNames, 
                       GLint *uniformLocations,
                       GLuint *program)
{
	GLuint vertShader = 0, fragShader = 0, prog = 0, status = 1, i;
	
	prog = glCreateProgram();

	status *= glueCompileShader(GL_VERTEX_SHADER, 1, &vertSource, &vertShader);
	status *= glueCompileShader(GL_FRAGMENT_SHADER, 1, &fragSource, &fragShader);
	glAttachShader(prog, vertShader);
	glAttachShader(prog, fragShader);
	
	for (i = 0; i < attribNameCt; i++)
	{
		if(strlen(attribNames[i]))
			glBindAttribLocation(prog, attribLocations[i], attribNames[i]);
	}
	
	status *= glueLinkProgram(prog);
	status *= glueValidateProgram(prog);

	if (status)
	{	
        for(i = 0; i < uniformNameCt; i++)
		{
            if(strlen(uniformNames[i]))
			    uniformLocations[i] = glueGetUniformLocation(prog, uniformNames[i]);
		}
		*program = prog;
	}
	if (vertShader)
		glDeleteShader(vertShader);
	if (fragShader)
		glDeleteShader(fragShader);
	glError();
		
	return status;
}
