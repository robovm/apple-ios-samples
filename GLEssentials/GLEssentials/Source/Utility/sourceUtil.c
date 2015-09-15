/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Functions for loading source files for shaders.
 */

#include "sourceUtil.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

demoSource* srcLoadSource(const char* filepathname)
{
	demoSource* source = (demoSource*) calloc(sizeof(demoSource), 1);
	
	// Check the file name suffix to determine what type of shader this is
	const char* suffixBegin = filepathname + strlen(filepathname) - 4;
	
	if(0 == strncmp(suffixBegin, ".fsh", 4))
	{
		source->shaderType = GL_FRAGMENT_SHADER;
	}
	else if(0 == strncmp(suffixBegin, ".vsh", 4))
	{
		source->shaderType = GL_VERTEX_SHADER;
	}
	else
	{
		// Unknown suffix
		source->shaderType = 0;
	}
	
	FILE* curFile = fopen(filepathname, "r");
	
	// Get the size of the source
	fseek(curFile, 0, SEEK_END);
	long fileSize = ftell (curFile);
	
	// Add 1 to the file size to include the null terminator for the string
	source->byteSize =  (GLsizei)fileSize + 1;
	
	// Alloc memory for the string
	source->string = malloc(source->byteSize);
	
	// Read entire file into the string from beginning of the file
	fseek(curFile, 0, SEEK_SET);
	fread(source->string, 1, fileSize, curFile);
	
	fclose(curFile);
	
	// Insert null terminator
	source->string[fileSize] = 0;
	
	return source;
}

void srcDestroySource(demoSource* source)
{
	free(source->string);
	free(source);
}