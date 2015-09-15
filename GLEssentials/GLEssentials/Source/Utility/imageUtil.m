/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Functions for loading an image files for textures.
 */

#include "imageUtil.h"

#if TARGET_IOS
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

demoImage* imgLoadImage(const char* filepathname, int flipVertical)
{
	NSString *filepathString = [[NSString alloc] initWithUTF8String:filepathname];
	
#if TARGET_IOS
	UIImage* imageClass = [[UIImage alloc] initWithContentsOfFile:filepathString];
#else   
    NSImage *nsimage = [[NSImage alloc] initWithContentsOfFile: filepathString];
	
	NSBitmapImageRep *imageClass = [[NSBitmapImageRep alloc] initWithData:[nsimage TIFFRepresentation]];
    nsimage = nil;
#endif
	
	CGImageRef cgImage = imageClass.CGImage;
	if (!cgImage)
	{
		return NULL;
	}
	
	demoImage* image = malloc(sizeof(demoImage));
	image->width = (GLuint)CGImageGetWidth(cgImage);
	image->height = (GLuint)CGImageGetHeight(cgImage);
	image->rowByteSize = image->width * 4;
	image->data = malloc(image->height * image->rowByteSize);
	image->format = GL_RGBA;
	image->type = GL_UNSIGNED_BYTE;
	
	CGContextRef context = CGBitmapContextCreate(image->data, image->width, image->height, 8, image->rowByteSize, CGImageGetColorSpace(cgImage), kCGBitmapAlphaInfoMask & kCGImageAlphaNoneSkipLast);
	CGContextSetBlendMode(context, kCGBlendModeCopy);
	if(flipVertical)
	{
		CGContextTranslateCTM(context, 0.0, image->height);
		CGContextScaleCTM(context, 1.0, -1.0);
	}
	CGContextDrawImage(context, CGRectMake(0.0, 0.0, image->width, image->height), cgImage);
	CGContextRelease(context);
	
	if(NULL == image->data)
	{
		imgDestroyImage(image);
		return NULL;
	}

	return image;
}

void imgDestroyImage(demoImage* image)
{
	free(image->data);
	free(image);
}