/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Functions for loading a model file for vertex arrays.  The model file
  format used is a simple "binary blob" invented for the purpose of this sample code.
 */

#include "modelUtil.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct modelHeaderRec
{
	char fileIdentifier[30];
	unsigned int majorVersion;
	unsigned int minorVersion;
} modelHeader;

typedef struct modelTOCRec
{
	unsigned int attribHeaderSize;
	unsigned int byteElementOffset;
	unsigned int bytePositionOffset;
	unsigned int byteTexcoordOffset;
	unsigned int byteNormalOffset;
} modelTOC;

typedef struct modelAttribRec
{
	unsigned int byteSize;
	GLenum datatype;
	GLenum primType; //If index data
	unsigned int sizePerElement;
	unsigned int numElements;
} modelAttrib;

demoModel* mdlLoadModel(const char* filepathname)
{
	if(NULL == filepathname)
	{
		return NULL;
	}
	
	demoModel* model = (demoModel*) calloc(sizeof(demoModel), 1);
	
	if(NULL == model)
	{
		return NULL;
	}
						
	
	size_t sizeRead;
	int error;
	FILE* curFile = fopen(filepathname, "r");
	
	if(!curFile)
	{	
		mdlDestroyModel(model);	
		return NULL;
	}
	
	modelHeader header;
	
	sizeRead = fread(&header, 1, sizeof(modelHeader), curFile);
	
	if(sizeRead != sizeof(modelHeader))
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	if(strncmp(header.fileIdentifier, "AppleOpenGLDemoModelWWDC2010", sizeof(header.fileIdentifier)))
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	if(header.majorVersion != 0 && header.minorVersion != 1)
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	modelTOC toc;
	
	sizeRead = fread(&toc, 1, sizeof(modelTOC), curFile);
	
	if(sizeRead != sizeof(modelTOC))
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	if(toc.attribHeaderSize > sizeof(modelAttrib))
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	modelAttrib attrib;
	
	error = fseek(curFile, toc.byteElementOffset, SEEK_SET);
	
	if(error < 0)
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	sizeRead = fread(&attrib, 1, toc.attribHeaderSize, curFile);
	
	if(sizeRead != toc.attribHeaderSize)
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	model->elementArraySize = attrib.byteSize;
	model->elementType = attrib.datatype;
	model->numElements = attrib.numElements;
	
	// OpenGL ES cannot use UNSIGNED_INT elements
	// So if the model has UI element...
	if(GL_UNSIGNED_INT == model->elementType)
	{
		//...Load the UI elements and convert to UNSIGNED_SHORT
		
		GLubyte* uiElements = (GLubyte*) malloc(model->elementArraySize);
		size_t ushortElementArraySize = model->numElements * sizeof(GLushort);
		model->elements = (GLubyte*)malloc(ushortElementArraySize); 
		
		sizeRead = fread(uiElements, 1, model->elementArraySize, curFile);
		
		if(sizeRead != model->elementArraySize)
		{
			fclose(curFile);
			mdlDestroyModel(model);		
			return NULL;
		}
		
		GLuint elemNum = 0;
		for(elemNum = 0; elemNum < model->numElements; elemNum++)
		{
			//We can't handle this model if an element is out of the UNSIGNED_INT range
			if(((GLuint*)uiElements)[elemNum] >= 0xFFFF)
			{
				fclose(curFile);
				mdlDestroyModel(model);		
				return NULL;
			}
			
			((GLushort*)model->elements)[elemNum] = ((GLuint*)uiElements)[elemNum];
		}
		
		free(uiElements);
	
		
		model->elementType = GL_UNSIGNED_SHORT;
		model->elementArraySize = model->numElements * sizeof(GLushort);
	}
	else 
	{	
		model->elements = (GLubyte*)malloc(model->elementArraySize);
		
		sizeRead = fread(model->elements, 1, model->elementArraySize, curFile);
		
		if(sizeRead != model->elementArraySize)
		{
			fclose(curFile);
			mdlDestroyModel(model);		
			return NULL;
		}
	}

	fseek(curFile, toc.bytePositionOffset, SEEK_SET);
	
	sizeRead = fread(&attrib, 1, toc.attribHeaderSize, curFile);
	
	if(sizeRead != toc.attribHeaderSize)
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	model->positionArraySize = attrib.byteSize;
	model->positionType = attrib.datatype;
	model->positionSize = attrib.sizePerElement;
	model->numVertcies = attrib.numElements;
	model->positions = (GLubyte*) malloc(model->positionArraySize);
	
	sizeRead = fread(model->positions, 1, model->positionArraySize, curFile);
	
	if(sizeRead != model->positionArraySize)
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	error = fseek(curFile, toc.byteTexcoordOffset, SEEK_SET);
	
	if(error < 0)
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	sizeRead = fread(&attrib, 1, toc.attribHeaderSize, curFile);
	
	if(sizeRead != toc.attribHeaderSize)
	{	
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	model->texcoordArraySize = attrib.byteSize;
	model->texcoordType = attrib.datatype;
	model->texcoordSize = attrib.sizePerElement;
	
	//Must have the same number of texcoords as positions
	if(model->numVertcies != attrib.numElements)
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	model->texcoords = (GLubyte*) malloc(model->texcoordArraySize);
	
	sizeRead = fread(model->texcoords, 1, model->texcoordArraySize, curFile);
	
	if(sizeRead != model->texcoordArraySize)
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	error = fseek(curFile, toc.byteNormalOffset, SEEK_SET);
	
	if(error < 0)
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	sizeRead = fread(&attrib, 1, toc.attribHeaderSize, curFile);
	
	if(sizeRead !=  toc.attribHeaderSize)
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	model->normalArraySize = attrib.byteSize;
	model->normalType = attrib.datatype;
	model->normalSize = attrib.sizePerElement;

	//Must have the same number of normals as positions
	if(model->numVertcies != attrib.numElements)
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
		
	model->normals = (GLubyte*) malloc(model->normalArraySize );
	
	sizeRead =  fread(model->normals, 1, model->normalArraySize , curFile);
	
	if(sizeRead != model->normalArraySize)
	{
		fclose(curFile);
		mdlDestroyModel(model);		
		return NULL;
	}
	
	
	fclose(curFile);
	
	return model;
	
}

demoModel* mdlLoadQuadModel()
{
	GLfloat posArray[] = {
		-200.0f, 0.0f, -200.0f,
		 200.0f, 0.0f, -200.0f,
		 200.0f, 0.0f,  200.0f,
		-200.0f, 0.0f,  200.0f
	};
		
	GLfloat texcoordArray[] = { 
		0.0f,  1.0f,
		1.0f,  1.0f,
		1.0f,  0.0f,
		0.0f,  0.0f
	};
	
	GLfloat normalArray[] = {
		0.0f, 0.0f, 1.0,
		0.0f, 0.0f, 1.0f,
		0.0f, 0.0f, 1.0f,
		0.0f, 0.0f, 1.0f,
	};
	
	GLushort elementArray[] =
	{
		0, 2, 1,
		0, 3, 2
	};
	
	demoModel* model = (demoModel*) calloc(sizeof(demoModel), 1);
	
	if(NULL == model)
	{
		return NULL;
	}
	
	model->positionType = GL_FLOAT;
	model->positionSize = 3;
	model->positionArraySize = sizeof(posArray);
	model->positions = (GLubyte*)malloc(model->positionArraySize);
	memcpy(model->positions, posArray, model->positionArraySize);
	
	model->texcoordType = GL_FLOAT;
	model->texcoordSize = 2;
	model->texcoordArraySize = sizeof(texcoordArray);
	model->texcoords = (GLubyte*)malloc(model->texcoordArraySize);
	memcpy(model->texcoords, texcoordArray, model->texcoordArraySize );

	model->normalType = GL_FLOAT;
	model->normalSize = 3;
	model->normalArraySize = sizeof(normalArray);
	model->normals = (GLubyte*)malloc(model->normalArraySize);
	memcpy(model->normals, normalArray, model->normalArraySize);
	
	model->elementArraySize = sizeof(elementArray);
	model->elements	= (GLubyte*)malloc(model->elementArraySize);
	memcpy(model->elements, elementArray, model->elementArraySize);
	
	model->primType = GL_TRIANGLES;
	
	
	model->numElements = sizeof(elementArray) / sizeof(GLushort);
	model->elementType = GL_UNSIGNED_SHORT;
	model->numVertcies = model->positionArraySize / (model->positionSize * sizeof(GLfloat));
	
	return model;
}

void mdlDestroyModel(demoModel* model)
{
	if(NULL == model)
	{
		return;
	}
	
	free(model->elements);
	free(model->positions);
	free(model->normals);
	free(model->texcoords);
	
	free(model);
}

