/*
     File: OpenGLRenderer.m
 Abstract: 
 The OpenGLRenderer class creates and draws objects.
 Most of the code is OS independent.
 
  Version: 1.7
 
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "OpenGLRenderer.h"
#import "matrixUtil.h"
#import "imageUtil.h"
#import "modelUtil.h"
#import "sourceUtil.h"


#define GetGLError()									\
{														\
	GLenum err = glGetError();							\
	while (err != GL_NO_ERROR) {						\
		NSLog(@"GLError %s set in File:%s Line:%d\n",	\
				GetGLErrorString(err),					\
				__FILE__,								\
				__LINE__);								\
		err = glGetError();								\
	}													\
}

// Toggle this to disable vertex buffer objects
// (i.e. use client-side vertex array objects)
// This must be 1 if using the GL3 Core Profile on the Mac
#define USE_VERTEX_BUFFER_OBJECTS 1

// Toggle this to disable the rendering the reflection
// and setup of the GLSL progam, model and FBO used for 
// the reflection.
#define RENDER_REFLECTION 1


// Indicies to which we will set vertex array attibutes
// See buildVAO and buildProgram
enum {
	POS_ATTRIB_IDX,
	NORMAL_ATTRIB_IDX,
	TEXCOORD_ATTRIB_IDX
};

#ifndef NULL
#define NULL 0
#endif

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@implementation OpenGLRenderer

#if RENDER_REFLECTION
demoModel* m_quadModel;
GLenum m_quadPrimType;
GLenum m_quadElementType;
GLuint m_quadNumElements;
GLuint m_reflectVAOName;
GLuint m_reflectTexName;
GLuint m_reflectFBOName;
GLuint m_reflectWidth;
GLuint m_reflectHeight;
GLuint m_reflectPrgName;
GLint  m_reflectModelViewUniformIdx;
GLint  m_reflectProjectionUniformIdx;
GLint m_reflectNormalMatrixUniformIdx;
#endif // RENDER_REFLECTION


GLuint m_characterPrgName;
GLint m_characterMvpUniformIdx;
GLuint m_characterVAOName;
GLuint m_characterTexName;
demoModel* m_characterModel;
GLenum m_characterPrimType;
GLenum m_characterElementType;
GLuint m_characterNumElements;
GLfloat m_characterAngle;


GLuint m_viewWidth;
GLuint m_viewHeight;

GLboolean m_useVBOs;

- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height
{
	glViewport(0, 0, width, height);

	m_viewWidth = width;
	m_viewHeight = height;
}

- (void) render
{
	// Set up the modelview and projection matricies
	GLfloat modelView[16];
	GLfloat projection[16];
	GLfloat mvp[16];
	
#if RENDER_REFLECTION
	
	// Bind our refletion FBO and render our scene

	glBindFramebuffer(GL_FRAMEBUFFER, m_reflectFBOName);

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glViewport(0, 0, m_reflectWidth, m_reflectHeight);
	
	mtxLoadPerspective(projection, 90, (float)m_reflectWidth / (float)m_reflectHeight,5.0,10000);

	mtxLoadIdentity(modelView);
	
	// Invert Y so that everything is rendered up-side-down
	// as it should with a reflection
	
	mtxScaleApply(modelView, 1, -1, 1);
	mtxTranslateApply(modelView, 0, 300, -800);
	mtxRotateXApply(modelView, -90.0f);	
	mtxRotateApply(modelView, m_characterAngle, 0.7, 0.3, 1);	
	
	mtxMultiply(mvp, projection, modelView);
	
	// Use the program that we previously created
	glUseProgram(m_characterPrgName);
	
	// Set the modelview projection matrix that we calculated above
	// in our vertex shader
	glUniformMatrix4fv(m_characterMvpUniformIdx, 1, GL_FALSE, mvp);
	
	// Bind our vertex array object
	glBindVertexArray(m_characterVAOName);
	
	// Bind the texture to be used
	glBindTexture(GL_TEXTURE_2D, m_characterTexName);
	
	// Cull front faces now that everything is flipped 
	// with our inverted reflection transformation matrix
	glCullFace(GL_FRONT);
	
	// Draw our object
	if(m_useVBOs)
	{
		glDrawElements(GL_TRIANGLES, m_characterNumElements, m_characterElementType, 0);
	}
	else 
	{
		glDrawElements(GL_TRIANGLES, m_characterNumElements, m_characterElementType, m_characterModel->elements);
	}
	
	// Bind our default FBO to render to the screen
	glBindFramebuffer(GL_FRAMEBUFFER, m_defaultFBOName);

	glViewport(0, 0, m_viewWidth, m_viewHeight);
	
#endif // RENDER_REFLECTION
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	// Use the program for rendering our character
	glUseProgram(m_characterPrgName);
	
	// Calculate the projection matrix
	mtxLoadPerspective(projection, 90, (float)m_viewWidth / (float)m_viewHeight,5.0,10000);
	
	// Calculate the modelview matrix to render our character 
	//  at the proper position and rotation
	mtxLoadTranslate(modelView, 0, 150, -450);
	mtxRotateXApply(modelView, -90.0f);	
	mtxRotateApply(modelView, m_characterAngle, 0.7, 0.3, 1);
	
	// Multiply the modelview and projection matrix and set it in the shader
	mtxMultiply(mvp, projection, modelView);
	
	// Have our shader use the modelview projection matrix 
	// that we calculated above
	glUniformMatrix4fv(m_characterMvpUniformIdx, 1, GL_FALSE, mvp);
	
	// Bind the texture to be used
	glBindTexture(GL_TEXTURE_2D, m_characterTexName);
	
	// Bind our vertex array object
	glBindVertexArray(m_characterVAOName);
	
	// Cull back faces now that we no longer render 
	// with an inverted matrix
	glCullFace(GL_BACK);
	
	// Draw our character
	if(m_useVBOs)
	{
		glDrawElements(GL_TRIANGLES, m_characterNumElements, m_characterElementType, 0);
	}
	else 
	{
		glDrawElements(GL_TRIANGLES, m_characterNumElements, m_characterElementType, m_characterModel->elements);
	}
	
#if RENDER_REFLECTION
	
	// Use our shader for reflections
	glUseProgram(m_reflectPrgName);
	
	mtxLoadTranslate(modelView, 0, -50, -250);
	
	// Multiply the modelview and projection matrix and set it in the shader
	mtxMultiply(mvp, projection, modelView);
	
	// Set the modelview matrix that we calculated above
	// in our vertex shader
	glUniformMatrix4fv(m_reflectModelViewUniformIdx, 1, GL_FALSE, modelView);
	
	// Set the projection matrix that we calculated above
	// in our vertex shader
	glUniformMatrix4fv(m_reflectProjectionUniformIdx, 1, GL_FALSE, mvp);
	
	float normalMatrix[9];
	
	// Calculate the normal matrix so that we can 
	// generate texture coordinates in our fragment shader
	
	// The normal matrix needs to be the inverse transpose of the 
	//   top left 3x3 portion of the modelview matrix
	// We don't need to calculate the inverse transpose matrix
	//   here because this will always be an orthonormal matrix
	//   thus the the inverse tranpose is the same thing
	mtx3x3FromTopLeftOf4x4(normalMatrix, modelView);
	
	// Set the normal matrix for our shader to use
	glUniformMatrix3fv(m_reflectNormalMatrixUniformIdx, 1, GL_FALSE, normalMatrix);
		
	// Bind the texture we rendered-to above (i.e. the reflection texture)
	glBindTexture(GL_TEXTURE_2D, m_reflectTexName);

#if !ESSENTIAL_GL_PRACTICES_IOS
	// Generate mipmaps from the rendered-to base level
	//   Mipmaps reduce shimmering pixels due to better filtering
	// This call is not accelarated on iOS 4 so do not use
	//   mipmaps here
	glGenerateMipmap(GL_TEXTURE_2D);
#endif
	
	// Bind our vertex array object
	glBindVertexArray(m_reflectVAOName);
	
	// Draw our refection plane
	if(m_useVBOs)
	{
		glDrawElements(GL_TRIANGLES, m_quadNumElements, m_quadElementType, 0);
	}
	else 
	{
		glDrawElements(GL_TRIANGLES, m_quadNumElements, m_quadElementType, m_quadModel->elements);
	}
#endif // RENDER_REFLECTION
	
	// Update the angle so our character keeps spinning
	m_characterAngle++;
}

static GLsizei GetGLTypeSize(GLenum type)
{
	switch (type) {
		case GL_BYTE:
			return sizeof(GLbyte);
		case GL_UNSIGNED_BYTE:
			return sizeof(GLubyte);
		case GL_SHORT:
			return sizeof(GLshort);
		case GL_UNSIGNED_SHORT:
			return sizeof(GLushort);
		case GL_INT:
			return sizeof(GLint);
		case GL_UNSIGNED_INT:
			return sizeof(GLuint);
		case GL_FLOAT:
			return sizeof(GLfloat);
	}
	return 0;
}

- (GLuint) buildVAO:(demoModel*)model
{	
	
	GLuint vaoName;
	
	// Create a vertex array object (VAO) to cache model parameters
	glGenVertexArrays(1, &vaoName);
	glBindVertexArray(vaoName);
	
	if(m_useVBOs)
	{
		GLuint posBufferName;
		
		// Create a vertex buffer object (VBO) to store positions
		glGenBuffers(1, &posBufferName);
		glBindBuffer(GL_ARRAY_BUFFER, posBufferName);
		
		// Allocate and load position data into the VBO
		glBufferData(GL_ARRAY_BUFFER, model->positionArraySize, model->positions, GL_STATIC_DRAW);
		
		// Enable the position attribute for this VAO
		glEnableVertexAttribArray(POS_ATTRIB_IDX);
		
		// Get the size of the position type so we can set the stride properly
		GLsizei posTypeSize = GetGLTypeSize(model->positionType);
		
		// Set up parmeters for position attribute in the VAO including, 
		//  size, type, stride, and offset in the currenly bound VAO
		// This also attaches the position VBO to the VAO
		glVertexAttribPointer(POS_ATTRIB_IDX,		// What attibute index will this array feed in the vertex shader (see buildProgram)
							  model->positionSize,	// How many elements are there per position?
							  model->positionType,	// What is the type of this data?
							  GL_FALSE,				// Do we want to normalize this data (0-1 range for fixed-pont types)
							  model->positionSize*posTypeSize, // What is the stride (i.e. bytes between positions)?
							  BUFFER_OFFSET(0));	// What is the offset in the VBO to the position data?
		
		
		if(model->normals)
		{
			GLuint normalBufferName;
			
			// Create a vertex buffer object (VBO) to store positions
			glGenBuffers(1, &normalBufferName);
			glBindBuffer(GL_ARRAY_BUFFER, normalBufferName);
			
			// Allocate and load normal data into the VBO
			glBufferData(GL_ARRAY_BUFFER, model->normalArraySize, model->normals, GL_STATIC_DRAW);
			
			// Enable the normal attribute for this VAO
			glEnableVertexAttribArray(NORMAL_ATTRIB_IDX);
			
			// Get the size of the normal type so we can set the stride properly
			GLsizei normalTypeSize = GetGLTypeSize(model->normalType);
			
			// Set up parmeters for position attribute in the VAO including, 
			//   size, type, stride, and offset in the currenly bound VAO
			// This also attaches the position VBO to the VAO
			glVertexAttribPointer(NORMAL_ATTRIB_IDX,	// What attibute index will this array feed in the vertex shader (see buildProgram)
								  model->normalSize,	// How many elements are there per normal?
								  model->normalType,	// What is the type of this data?
								  GL_FALSE,				// Do we want to normalize this data (0-1 range for fixed-pont types)
								  model->normalSize*normalTypeSize, // What is the stride (i.e. bytes between normals)?
								  BUFFER_OFFSET(0));	// What is the offset in the VBO to the normal data?
		}
		
		if(model->texcoords)
		{
			GLuint texcoordBufferName;
			
			// Create a VBO to store texcoords
			glGenBuffers(1, &texcoordBufferName);
			glBindBuffer(GL_ARRAY_BUFFER, texcoordBufferName);
			
			// Allocate and load texcoord data into the VBO
			glBufferData(GL_ARRAY_BUFFER, model->texcoordArraySize, model->texcoords, GL_STATIC_DRAW);
			
			// Enable the texcoord attribute for this VAO
			glEnableVertexAttribArray(TEXCOORD_ATTRIB_IDX);
			
			// Get the size of the texcoord type so we can set the stride properly
			GLsizei texcoordTypeSize = GetGLTypeSize(model->texcoordType);
			
			// Set up parmeters for texcoord attribute in the VAO including,
			//   size, type, stride, and offset in the currenly bound VAO
			// This also attaches the texcoord VBO to VAO
			glVertexAttribPointer(TEXCOORD_ATTRIB_IDX,	// What attibute index will this array feed in the vertex shader (see buildProgram)
								  model->texcoordSize,	// How many elements are there per texture coord?
								  model->texcoordType,	// What is the type of this data in the array?
								  GL_TRUE,				// Do we want to normalize this data (0-1 range for fixed-point types)
								  model->texcoordSize*texcoordTypeSize,  // What is the stride (i.e. bytes between texcoords)?
								  BUFFER_OFFSET(0));	// What is the offset in the VBO to the texcoord data?
		}
		
		GLuint elementBufferName;	
		
		// Create a VBO to vertex array elements
		// This also attaches the element array buffer to the VAO
		glGenBuffers(1, &elementBufferName);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferName);
		
		// Allocate and load vertex array element data into VBO
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, model->elementArraySize, model->elements, GL_STATIC_DRAW);	
	}
	else
	{
		
		// Enable the position attribute for this VAO
		glEnableVertexAttribArray(POS_ATTRIB_IDX);
		
		// Get the size of the position type so we can set the stride properly
		GLsizei posTypeSize = GetGLTypeSize(model->positionType);
		
		// Set up parmeters for position attribute in the VAO including,
		//  size, type, stride, and offset in the currenly bound VAO
		// This also attaches the position array in memory to the VAO
		glVertexAttribPointer(POS_ATTRIB_IDX,  // What attibute index will this array feed in the vertex shader? (also see buildProgram)
							  model->positionSize,  // How many elements are there per position?
							  model->positionType,  // What is the type of this data
							  GL_FALSE,				// Do we want to normalize this data (0-1 range for fixed-pont types)
							  model->positionSize*posTypeSize, // What is the stride (i.e. bytes between positions)?
							  model->positions);    // Where is the position data in memory?
		
		if(model->normals)
		{			
			// Enable the normal attribute for this VAO
			glEnableVertexAttribArray(NORMAL_ATTRIB_IDX);
			
			// Get the size of the normal type so we can set the stride properly
			GLsizei normalTypeSize = GetGLTypeSize(model->normalType);
			
			// Set up parmeters for position attribute in the VAO including, 
			//   size, type, stride, and offset in the currenly bound VAO
			// This also attaches the position VBO to the VAO
			glVertexAttribPointer(NORMAL_ATTRIB_IDX,	// What attibute index will this array feed in the vertex shader (see buildProgram)
								  model->normalSize,	// How many elements are there per normal?
								  model->normalType,	// What is the type of this data?
								  GL_FALSE,				// Do we want to normalize this data (0-1 range for fixed-pont types)
								  model->normalSize*normalTypeSize, // What is the stride (i.e. bytes between normals)?
								  model->normals);	    // Where is normal data in memory?
		}
		
		if(model->texcoords)
		{
			// Enable the texcoord attribute for this VAO
			glEnableVertexAttribArray(TEXCOORD_ATTRIB_IDX);
			
			// Get the size of the texcoord type so we can set the stride properly
			GLsizei texcoordTypeSize = GetGLTypeSize(model->texcoordType);
			
			// Set up parmeters for texcoord attribute in the VAO including, 
			//   size, type, stride, and offset in the currenly bound VAO
			// This also attaches the texcoord array in memory to the VAO	
			glVertexAttribPointer(TEXCOORD_ATTRIB_IDX,	// What attibute index will this array feed in the vertex shader (see buildProgram)
								  model->texcoordSize,	// How many elements are there per texture coord?
								  model->texcoordType,	// What is the type of this data in the array?
								  GL_FALSE,				// Do we want to normalize this data (0-1 range for fixed-point types)
								  model->texcoordSize*texcoordTypeSize,  // What is the stride (i.e. bytes between texcoords)?
								  model->texcoords);	// Where is the texcood data in memory?
		}
	}
	
	GetGLError();
	
	return vaoName;
}

-(void)destroyVAO:(GLuint) vaoName
{
	GLuint index;
	GLuint bufName;
	
	// Bind the VAO so we can get data from it
	glBindVertexArray(vaoName);
	
	// For every possible attribute set in the VAO
	for(index = 0; index < 16; index++)
	{
		// Get the VBO set for that attibute
		glGetVertexAttribiv(index , GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
		
		// If there was a VBO set...
		if(bufName)
		{
			//...delete the VBO
			glDeleteBuffers(1, &bufName);
		}
	}
	
	// Get any element array VBO set in the VAO
	glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, (GLint*)&bufName);
	
	// If there was a element array VBO set in the VAO
	if(bufName)
	{
		//...delete the VBO
		glDeleteBuffers(1, &bufName);
	}
	
	// Finally, delete the VAO
	glDeleteVertexArrays(1, &vaoName);
	
	GetGLError();
}


-(GLuint) buildTexture:(demoImage*) image
{
	GLuint texName;
	
	// Create a texture object to apply to model
	glGenTextures(1, &texName);
	glBindTexture(GL_TEXTURE_2D, texName);
	
	// Set up filter and wrap modes for this texture object
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	
	// Indicate that pixel rows are tightly packed 
	//  (defaults to stride of 4 which is kind of only good for
	//  RGBA or FLOAT data types)
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
	
	// Allocate and load image data into texture
	glTexImage2D(GL_TEXTURE_2D, 0, image->format, image->width, image->height, 0,
				 image->format, image->type, image->data);

	// Create mipmaps for this texture for better image quality
	glGenerateMipmap(GL_TEXTURE_2D);
	
	GetGLError();
	
	return texName;
}


-(void) deleteFBOAttachment:(GLenum) attachment
{    
    GLint param;
    GLuint objName;
	
    glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment,
                                          GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,
                                          &param);
	
    if(GL_RENDERBUFFER == param)
    {
        glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment,
                                              GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
                                              &param);
		
        objName = ((GLuint*)(&param))[0];
        glDeleteRenderbuffers(1, &objName);
    }
    else if(GL_TEXTURE == param)
    {
        
        glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment,
                                              GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
                                              &param);
		
        objName = ((GLuint*)(&param))[0];
        glDeleteTextures(1, &objName);
    }
    
}

-(void) destroyFBO:(GLuint) fboName
{ 
	if(0 == fboName)
	{
		return;
	}
    
    glBindFramebuffer(GL_FRAMEBUFFER, fboName);
	
	
    GLint maxColorAttachments = 1;
	
	
	// OpenGL ES on iOS 4 has only 1 attachment. 
	// There are many possible attachments on OpenGL 
	// on MacOSX so we query how many below
	#if !ESSENTIAL_GL_PRACTICES_IOS
	glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &maxColorAttachments);
	#endif
	
	GLint colorAttachment;
	
	// For every color buffer attached
    for(colorAttachment = 0; colorAttachment < maxColorAttachments; colorAttachment++)
    {
		// Delete the attachment
		[self deleteFBOAttachment:(GL_COLOR_ATTACHMENT0+colorAttachment)];
	}
	
	// Delete any depth or stencil buffer attached
    [self deleteFBOAttachment:GL_DEPTH_ATTACHMENT];
	
    [self deleteFBOAttachment:GL_STENCIL_ATTACHMENT];
	
    glDeleteFramebuffers(1,&fboName);
}



-(GLuint) buildFBOWithWidth:(GLuint)width andHeight:(GLuint) height
{
	GLuint fboName;
	
	GLuint colorTexture;
	
	// Create a texture object to apply to model
	glGenTextures(1, &colorTexture);
	glBindTexture(GL_TEXTURE_2D, colorTexture);
	
	// Set up filter and wrap modes for this texture object
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
#if ESSENTIAL_GL_PRACTICES_IOS
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
#else
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
#endif
	
	// Allocate a texture image with which we can render to
	// Pass NULL for the data parameter since we don't need to load image data.
	//     We will be generating the image by rendering to this texture
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 
				 width, height, 0,
				 GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	
	GLuint depthRenderbuffer;
	glGenRenderbuffers(1, &depthRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
	
	glGenFramebuffers(1, &fboName);
	glBindFramebuffer(GL_FRAMEBUFFER, fboName);	
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorTexture, 0);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
	
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		[self destroyFBO:fboName];
		return 0;
	}
	
	GetGLError();
	
	return fboName;
}

-(GLuint) buildProgramWithVertexSource:(demoSource*)vertexSource
					withFragmentSource:(demoSource*)fragmentSource
							withNormal:(BOOL)hasNormal
						  withTexcoord:(BOOL)hasTexcoord
{
	GLuint prgName;
	
	GLint logLength, status;
	
	// String to pass to glShaderSource
	GLchar* sourceString = NULL;  
	
	// Determine if GLSL version 140 is supported by this context.
	//  We'll use this info to generate a GLSL shader source string  
	//  with the proper version preprocessor string prepended
	float  glLanguageVersion;
	
#if ESSENTIAL_GL_PRACTICES_IOS
	sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "OpenGL ES GLSL ES %f", &glLanguageVersion);
#else
	sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &glLanguageVersion);	
#endif
	
	// GL_SHADING_LANGUAGE_VERSION returns the version standard version form 
	//  with decimals, but the GLSL version preprocessor directive simply
	//  uses integers (thus 1.10 should 110 and 1.40 should be 140, etc.)
	//  We multiply the floating point number by 100 to get a proper
	//  number for the GLSL preprocessor directive
	GLuint version = 100 * glLanguageVersion;
	
	// Get the size of the version preprocessor string info so we know 
	//  how much memory to allocate for our sourceString
	const GLsizei versionStringSize = sizeof("#version 123\n");
	
	// Create a program object
	prgName = glCreateProgram();
	
	// Indicate the attribute indicies on which vertex arrays will be
	//  set with glVertexAttribPointer
	//  See buildVAO to see where vertex arrays are actually set
	glBindAttribLocation(prgName, POS_ATTRIB_IDX, "inPosition");
	
	if(hasNormal)
	{
		glBindAttribLocation(prgName, NORMAL_ATTRIB_IDX, "inNormal");
	}
	
	if(hasTexcoord)
	{
		glBindAttribLocation(prgName, TEXCOORD_ATTRIB_IDX, "inTexcoord");
	}
	
	//////////////////////////////////////
	// Specify and compile VertexShader //
	//////////////////////////////////////
	
	// Allocate memory for the source string including the version preprocessor information
	sourceString = malloc(vertexSource->byteSize + versionStringSize);
	
	// Prepend our vertex shader source string with the supported GLSL version so
	//  the shader will work on ES, Legacy, and OpenGL 3.2 Core Profile contexts
	sprintf(sourceString, "#version %d\n%s", version, vertexSource->string);
			
	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);	
	glShaderSource(vertexShader, 1, (const GLchar **)&(sourceString), NULL);
	glCompileShader(vertexShader);
	glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);
	
	if (logLength > 0) 
	{
		GLchar *log = (GLchar*) malloc(logLength);
		glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
		NSLog(@"Vtx Shader compile log:%s\n", log);
		free(log);
	}
	
	glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to compile vtx shader:\n%s\n", sourceString);
		return 0;
	}
	
	free(sourceString);
	sourceString = NULL;
	
	// Attach the vertex shader to our program
	glAttachShader(prgName, vertexShader);
	
	// Delete the vertex shader since it is now attached
	// to the program, which will retain a reference to it
	glDeleteShader(vertexShader);
	
	/////////////////////////////////////////
	// Specify and compile Fragment Shader //
	/////////////////////////////////////////
	
	// Allocate memory for the source string including the version preprocessor	 information
	sourceString = malloc(fragmentSource->byteSize + versionStringSize);
	
	// Prepend our fragment shader source string with the supported GLSL version so
	//  the shader will work on ES, Legacy, and OpenGL 3.2 Core Profile contexts
	sprintf(sourceString, "#version %d\n%s", version, fragmentSource->string);
	
	GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);	
	glShaderSource(fragShader, 1, (const GLchar **)&(sourceString), NULL);
	glCompileShader(fragShader);
	glGetShaderiv(fragShader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) 
	{
		GLchar *log = (GLchar*)malloc(logLength);
		glGetShaderInfoLog(fragShader, logLength, &logLength, log);
		NSLog(@"Frag Shader compile log:\n%s\n", log);
		free(log);
	}
	
	glGetShaderiv(fragShader, GL_COMPILE_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to compile frag shader:\n%s\n", sourceString);
		return 0;
	}
	
	free(sourceString);
	sourceString = NULL;
	
	// Attach the fragment shader to our program
	glAttachShader(prgName, fragShader);
	
	// Delete the fragment shader since it is now attached
	// to the program, which will retain a reference to it
	glDeleteShader(fragShader);
	
	//////////////////////
	// Link the program //
	//////////////////////
	
	glLinkProgram(prgName);
	glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar*)malloc(logLength);
		glGetProgramInfoLog(prgName, logLength, &logLength, log);
		NSLog(@"Program link log:\n%s\n", log);
		free(log);
	}
	
	glGetProgramiv(prgName, GL_LINK_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to link program");
		return 0;
	}
	
	glValidateProgram(prgName);
	glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar*)malloc(logLength);
		glGetProgramInfoLog(prgName, logLength, &logLength, log);
		NSLog(@"Program validate log:\n%s\n", log);
		free(log);
	}
	
	glGetProgramiv(prgName, GL_VALIDATE_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to validate program");
		return 0;
	}
	
	
	glUseProgram(prgName);
	
	///////////////////////////////////////
	// Setup common program input points //
	///////////////////////////////////////

	
	GLint samplerLoc = glGetUniformLocation(prgName, "diffuseTexture");
	
	// Indicate that the diffuse texture will be bound to texture unit 0
	GLint unit = 0;
	glUniform1i(samplerLoc, unit);
	
	GetGLError();
	
	return prgName;
	
}

- (id) initWithDefaultFBO: (GLuint) defaultFBOName
{
	if((self = [super init]))
	{
		NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));
		
		////////////////////////////////////////////////////
		// Build all of our and setup initial state here  //
		// Don't wait until our real time run loop begins //
		////////////////////////////////////////////////////
		
		m_defaultFBOName = defaultFBOName;
		
		m_viewWidth = 100;
		m_viewHeight = 100;
		
		
		m_characterAngle = 0;
		
		m_useVBOs = USE_VERTEX_BUFFER_OBJECTS;
		
		NSString* filePathName = nil;

		//////////////////////////////
		// Load our character model //
		//////////////////////////////
		
		filePathName = [[NSBundle mainBundle] pathForResource:@"demon" ofType:@"model"];
		m_characterModel = mdlLoadModel([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
		
		// Build Vertex Buffer Objects (VBOs) and Vertex Array Object (VAOs) with our model data
		m_characterVAOName = [self buildVAO:m_characterModel];
		
		// Cache the number of element and primType to use later in our glDrawElements calls
		m_characterNumElements = m_characterModel->numElements;
		m_characterPrimType = m_characterModel->primType;
		m_characterElementType = m_characterModel->elementType;

		if(m_useVBOs)
		{
			//If we're using VBOs we can destroy all this memory since buffers are
			// loaded into GL and we've saved anything else we need
			mdlDestroyModel(m_characterModel);
			m_characterModel = NULL;
		}
	
		
		////////////////////////////////////
		// Load texture for our character //
		////////////////////////////////////
		
		filePathName = [[NSBundle mainBundle] pathForResource:@"demon" ofType:@"png"];
		demoImage *image = imgLoadImage([filePathName cStringUsingEncoding:NSASCIIStringEncoding], false);
		
		// Build a texture object with our image data
		m_characterTexName = [self buildTexture:image];
		
		// We can destroy the image once it's loaded into GL
		imgDestroyImage(image);
	
		
		////////////////////////////////////////////////////
		// Load and Setup shaders for character rendering //
		////////////////////////////////////////////////////
		
		demoSource *vtxSource = NULL;
		demoSource *frgSource = NULL;
		
		filePathName = [[NSBundle mainBundle] pathForResource:@"character" ofType:@"vsh"];
		vtxSource = srcLoadSource([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
		
		filePathName = [[NSBundle mainBundle] pathForResource:@"character" ofType:@"fsh"];
		frgSource = srcLoadSource([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
		
		// Build Program
		m_characterPrgName = [self buildProgramWithVertexSource:vtxSource
											 withFragmentSource:frgSource
													 withNormal:NO
												   withTexcoord:YES];
		
		srcDestroySource(vtxSource);
		srcDestroySource(frgSource);
		
		m_characterMvpUniformIdx = glGetUniformLocation(m_characterPrgName, "modelViewProjectionMatrix");
		
		if(m_characterMvpUniformIdx < 0)
		{
			NSLog(@"No modelViewProjectionMatrix in character shader");
		}
		
		
#if RENDER_REFLECTION
		
		m_reflectWidth = 512;
		m_reflectHeight = 512;
		
		////////////////////////////////////////////////
		// Load a model for a quad for the reflection //
		////////////////////////////////////////////////
		
		m_quadModel = mdlLoadQuadModel();
		// Build Vertex Buffer Objects (VBOs) and Vertex Array Object (VAOs) with our model data
		m_reflectVAOName = [self buildVAO:m_quadModel];
		
		// Cache the number of element and primType to use later in our glDrawElements calls
		m_quadNumElements = m_quadModel->numElements;
		m_quadPrimType    = m_quadModel->primType;
		m_quadElementType = m_quadModel->elementType;
		
		if(m_useVBOs)
		{
			//If we're using VBOs we can destroy all this memory since buffers are
			// loaded into GL and we've saved anything else we need 
			mdlDestroyModel(m_quadModel);
			m_quadModel = NULL;
		}
		
		/////////////////////////////////////////////////////
		// Create texture and FBO for reflection rendering //
		/////////////////////////////////////////////////////
		
		m_reflectFBOName = [self buildFBOWithWidth:m_reflectWidth andHeight:m_reflectHeight];
		
		// Get the texture we created in buildReflectFBO by binding the 
		// reflection FBO and getting the buffer attached to color 0
		glBindFramebuffer(GL_FRAMEBUFFER, m_reflectFBOName);
		
		GLint iReflectTexName;
		
		glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                                              GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
                                              &iReflectTexName);
		
		m_reflectTexName = ((GLuint*)(&iReflectTexName))[0];
		
		/////////////////////////////////////////////////////
		// Load and setup shaders for reflection rendering //
		/////////////////////////////////////////////////////
		
		filePathName = [[NSBundle mainBundle] pathForResource:@"reflect" ofType:@"vsh"];
		vtxSource = srcLoadSource([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
		
		filePathName = [[NSBundle mainBundle] pathForResource:@"reflect" ofType:@"fsh"];
		frgSource = srcLoadSource([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
		
		// Build Program
		m_reflectPrgName = [self buildProgramWithVertexSource:vtxSource
										   withFragmentSource:frgSource
												   withNormal:YES
												 withTexcoord:NO];
		
		srcDestroySource(vtxSource);
		srcDestroySource(frgSource);
		
		m_reflectModelViewUniformIdx = glGetUniformLocation(m_reflectPrgName, "modelViewMatrix");
		
		if(m_reflectModelViewUniformIdx < 0)
		{
			NSLog(@"No modelViewMatrix in reflection shader");
		}
		
		m_reflectProjectionUniformIdx = glGetUniformLocation(m_reflectPrgName, "modelViewProjectionMatrix");
		
		if(m_reflectProjectionUniformIdx < 0)
		{
			NSLog(@"No modelViewProjectionMatrix in reflection shader");
		}
		
		m_reflectNormalMatrixUniformIdx = glGetUniformLocation(m_reflectPrgName, "normalMatrix");
		
		if(m_reflectNormalMatrixUniformIdx < 0)
		{
			NSLog(@"No normalMatrix in reflection shader");
		}
#endif // RENDER_REFLECTION
		
		////////////////////////////////////////////////
		// Set up OpenGL state that will never change //
		////////////////////////////////////////////////
		
		// Depth test will always be enabled
		glEnable(GL_DEPTH_TEST);
	
		// We will always cull back faces for better performance
		glEnable(GL_CULL_FACE);
		
		// Always use this clear color
		glClearColor(0.5f, 0.4f, 0.5f, 1.0f);
		
		// Draw our scene once without presenting the rendered image.
		//   This is done in order to pre-warm OpenGL
		// We don't need to present the buffer since we don't actually want the 
		//   user to see this, we're only drawing as a pre-warm stage
		[self render];
		
		// Reset the m_characterAngle which is incremented in render
		m_characterAngle = 0;
		
		// Check for errors to make sure all of our setup went ok
		GetGLError();
	}
	
	return self;
}


- (void) dealloc
{
	
	// Cleanup all OpenGL objects and 
	glDeleteTextures(1, &m_characterTexName);
		
	[self destroyVAO:m_characterVAOName];

	glDeleteProgram(m_characterPrgName);

	mdlDestroyModel(m_characterModel);

#if RENDER_REFLECTION
	[self destroyFBO:m_reflectFBOName];
	
	[self destroyVAO:m_reflectVAOName];

	glDeleteProgram(m_reflectPrgName);
	
	mdlDestroyModel(m_quadModel);
#endif // RENDER_REFLECTION
	
	[super dealloc];	
}

@end
