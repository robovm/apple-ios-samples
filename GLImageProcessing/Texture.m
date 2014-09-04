/*
     File: Texture.m
 Abstract: n/a
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

#import <UIKit/UIKit.h>
#import "Texture.h"


static unsigned int nextPOT(unsigned int x)
{
	x = x - 1;
	x = x | (x >> 1);
	x = x | (x >> 2);
	x = x | (x >> 4);
	x = x | (x >> 8);
	x = x | (x >>16);
	return x + 1;
}


// This is not a fully generalized image loader. It is an example of how to use
// CGImage to directly access decompressed image data. Only the most commonly
// used image formats are supported. It will be necessary to expand this code
// to account for other uses, for example cubemaps or compressed textures.
//
// If the image format is supported, this loader will Gen a OpenGL 2D texture object
// and upload texels from it, padding to POT if needed. For image processing purposes,
// border pixels are also replicated here to ensure proper filtering during e.g. blur.
//
// The caller of this function is responsible for deleting the GL texture object.
void loadTexture(const char *name, Image *img, RendererInfo *renderer)
{
	GLuint texID = 0, components, x, y;
	GLuint imgWide, imgHigh;      // Real image size
	GLuint rowBytes, rowPixels;   // Image size padded by CGImage
	GLuint POTWide, POTHigh;      // Image size padded to next power of two
	CGBitmapInfo info;            // CGImage component layout info
	CGColorSpaceModel colormodel; // CGImage colormodel (RGB, CMYK, paletted, etc)
	GLenum internal, format;
	GLubyte *pixels, *temp = NULL;
	
	CGImageRef CGImage = [UIImage imageNamed:[NSString stringWithUTF8String:name]].CGImage;
	rt_assert(CGImage);
	if (!CGImage)
		return;
	
	// Parse CGImage info
	info       = CGImageGetBitmapInfo(CGImage);		// CGImage may return pixels in RGBA, BGRA, or ARGB order
	colormodel = CGColorSpaceGetModel(CGImageGetColorSpace(CGImage));
	size_t bpp = CGImageGetBitsPerPixel(CGImage);
	if (bpp < 8 || bpp > 32 || (colormodel != kCGColorSpaceModelMonochrome && colormodel != kCGColorSpaceModelRGB))
	{
		// This loader does not support all possible CGImage types, such as paletted images
		return;
	}
	components = (int)(bpp>>3);
	rowBytes   = (int)CGImageGetBytesPerRow(CGImage);	// CGImage may pad rows
	rowPixels  = (int)(rowBytes / components);
	imgWide    = (int)CGImageGetWidth(CGImage);
	imgHigh    = (int)CGImageGetHeight(CGImage);
	img->wide  = rowPixels;
	img->high  = imgHigh;
	img->s     = (float)imgWide / rowPixels;
	img->t     = 1.0;

	// Choose OpenGL format
	switch(bpp)
	{
		default:
			rt_assert(0 && "Unknown CGImage bpp");
		case 32:
		{
			internal = GL_RGBA;
			switch(info & kCGBitmapAlphaInfoMask)
			{
				case kCGImageAlphaPremultipliedFirst:
				case kCGImageAlphaFirst:
				case kCGImageAlphaNoneSkipFirst:
					format = GL_BGRA;
					break;
				default:
					format = GL_RGBA;
			}
			break;
		}
		case 24:
			internal = format = GL_RGB;
			break;
		case 16:
			internal = format = GL_LUMINANCE_ALPHA;
			break;
		case 8:
			internal = format = GL_LUMINANCE;
			break;
	}

	// Get a pointer to the uncompressed image data.
	//
	// This allows access to the original (possibly unpremultiplied) data, but any manipulation
	// (such as scaling) has to be done manually. Contrast this with drawing the image
	// into a CGBitmapContext, which allows scaling, but always forces premultiplication.
	CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(CGImage));
	rt_assert(data);
	pixels = (GLubyte *)CFDataGetBytePtr(data);
	rt_assert(pixels);

	// If the CGImage component layout isn't compatible with OpenGL, fix it.
	// On the device, CGImage will generally return BGRA or RGBA.
	// On the simulator, CGImage may return ARGB, depending on the file format.
	if (format == GL_BGRA)
	{
		uint32_t *p = (uint32_t *)pixels;
		int i, num = img->wide * img->high;
		
		if ((info & kCGBitmapByteOrderMask) != kCGBitmapByteOrder32Host)
		{
			// Convert from ARGB to BGRA
			for (i = 0; i < num; i++)
				p[i] = (p[i] << 24) | ((p[i] & 0xFF00) << 8) | ((p[i] >> 8) & 0xFF00) | (p[i] >> 24);
		}
		
		// All current iPhoneOS devices support BGRA via an extension.
		if (!renderer->extension[IMG_texture_format_BGRA8888])
		{
			format = GL_RGBA;
		
			// Convert from BGRA to RGBA
			for (i = 0; i < num; i++)
				#if __LITTLE_ENDIAN__
				p[i] = ((p[i] >> 16) & 0xFF) | (p[i] & 0xFF00FF00) | ((p[i] & 0xFF) << 16);
				#else
				p[i] = ((p[i] & 0xFF00) << 16) | (p[i] & 0xFF00FF) | ((p[i] >> 16) & 0xFF00);
				#endif
		}
	}

	// Determine if we need to pad this image to a power of two.
	// There are multiple ways to deal with NPOT images on renderers that only support POT:
	// 1) scale down the image to POT size. Loses quality.
	// 2) pad up the image to POT size. Wastes memory.
	// 3) slice the image into multiple POT textures. Requires more rendering logic.
	//
	// We are only dealing with a single image here, and pick 2) for simplicity.
	//
	// If you prefer 1), you can use CoreGraphics to scale the image into a CGBitmapContext.
	POTWide = nextPOT(img->wide);
	POTHigh = nextPOT(img->high);

	if (!renderer->extension[APPLE_texture_2D_limited_npot] && (img->wide != POTWide || img->high != POTHigh))
	{
		GLuint dstBytes = POTWide * components;
		GLubyte *temp = (GLubyte *)malloc(dstBytes * POTHigh);
		
		for (y = 0; y < img->high; y++)
			memcpy(&temp[y*dstBytes], &pixels[y*rowBytes], rowBytes);
		
		img->s *= (float)img->wide/POTWide;
		img->t *= (float)img->high/POTHigh;
		img->wide = POTWide;
		img->high = POTHigh;
		pixels = temp;
		rowBytes = dstBytes;
	}

	// For filters that sample texel neighborhoods (like blur), we must replicate
	// the edge texels of the original input, to simulate CLAMP_TO_EDGE.
	{
		GLuint replicatew = MIN(MAX_FILTER_RADIUS, img->wide-imgWide);
		GLuint replicateh = MIN(MAX_FILTER_RADIUS, img->high-imgHigh);
		GLuint imgRow = imgWide * components;

		for (y = 0; y < imgHigh; y++)
			for (x = 0; x < replicatew; x++)
				memcpy(&pixels[y*rowBytes+imgRow+x*components], &pixels[y*rowBytes+imgRow-components], components);
		for (y = imgHigh; y < imgHigh+replicateh; y++)
			memcpy(&pixels[y*rowBytes], &pixels[(imgHigh-1)*rowBytes], imgRow+replicatew*components);
	}
	
	if (img->wide <= renderer->maxTextureSize && img->high <= renderer->maxTextureSize)
	{
		glGenTextures(1, &texID);
		glBindTexture(GL_TEXTURE_2D, texID);
		// Set filtering parameters appropriate for this application (image processing on screen-aligned quads.)
		// Depending on your needs, you may prefer linear filtering, or mipmap generation.
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexImage2D(GL_TEXTURE_2D, 0, internal, img->wide, img->high, 0, format, GL_UNSIGNED_BYTE, pixels);
	}
	
	if (temp) free(temp);
	CFRelease(data);
	img->texID = texID;
}
