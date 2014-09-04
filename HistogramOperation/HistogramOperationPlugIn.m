/*
     File: HistogramOperationPlugIn.m
 Abstract: HistogramOperationPlugin, Histogram and HistogramImageProvider classes.
  Version: 1.0
 
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
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
*/

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "HistogramOperationPlugIn.h"

#define	kQCPlugIn_Name				@"Histogram Operation"
#define	kQCPlugIn_Description		@"Alters a source image according to the histogram of another image."

#if !__USE_PROVIDER__

static void _BufferReleaseCallback(const void* address, void* info)
{
	free((void*)address);
}

#endif

@implementation HistogramOperationPlugIn

/* We need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation */
@dynamic inputSourceImage, inputHistogramImage, outputResultImage;

+ (NSDictionary*) attributes
{
	/* Return the attributes of this plug-in */
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/* Return the attributes for the plug-in property ports */
	if([key isEqualToString:@"inputSourceImage"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Source Image", QCPortAttributeNameKey, nil];
	if([key isEqualToString:@"inputHistogramImage"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Histogram Image", QCPortAttributeNameKey, nil];
	if([key isEqualToString:@"outputResultImage"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Result Image", QCPortAttributeNameKey, nil];
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/* This plug-in is a processor */
	return kQCPlugInExecutionModeProcessor;
}

+ (QCPlugInTimeMode) timeMode
{
	/* This plug-in does not depend on the time (time parameter is completely ignored in the -execute:atTime:withArguments: method) */
	return kQCPlugInTimeModeNone;
}

@end

@implementation HistogramOperationPlugIn (Execution)

#if __USE_PROVIDER__

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	id<QCPlugInInputImageSource>	image;
	HistogramImageProvider*			provider;
	CGColorSpaceRef					colorSpace;
	
	/* Update our cached histogram if the histogram image and changed */
	if([self didValueForInputKeyChange:@"inputHistogramImage"]) {
		[_cachedHistogram release];
		if(image = self.inputHistogramImage) {
			colorSpace = (CGColorSpaceGetModel([image imageColorSpace]) == kCGColorSpaceModelRGB ? [image imageColorSpace] : [context colorSpace]);
			_cachedHistogram = [[Histogram alloc] initWithImageSource:self.inputHistogramImage colorSpace:colorSpace];
		}
		else
		_cachedHistogram = nil;
	}
	
	/* If we have both a histogram and a source image, create a result image object */
	if(_cachedHistogram && (image = self.inputSourceImage)) {
		provider = [[HistogramImageProvider alloc] initWithImageSource:image histogram:_cachedHistogram];
		if(provider == nil)
		return NO;
		self.outputResultImage = provider;
		[provider release];
	}
	/* otherwise, don't produce any result image object */
	else
	self.outputResultImage = nil;
	
	return YES;
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	/* Clear our cached histogram */
	[_cachedHistogram release];
	_cachedHistogram = nil;
}

#else

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
#if __BIG_ENDIAN__
	NSString*						format = QCPlugInPixelFormatARGB8;
#else
	NSString*						format = QCPlugInPixelFormatBGRA8;
#endif
	id								provider = nil;
	id<QCPlugInInputImageSource>	sourceImage = self.inputSourceImage;
	id<QCPlugInInputImageSource>	histogramImage = self.inputHistogramImage;
	vImagePixelCount				histogramA[256];
	vImagePixelCount				histogramR[256];
	vImagePixelCount				histogramG[256];
	vImagePixelCount				histogramB[256];
	vImagePixelCount*				histograms[4];
	vImagePixelCount*				temp;
	vImage_Buffer					buffer,
									inBuffer,
									outBuffer;
	vImage_Error					error;
	NSUInteger						pixelsWide,
									pixelsHigh;
	void*							pixelBuffer;
	NSUInteger						rowBytes;
	CGColorSpaceRef					colorSpace;
	
	/* Process the source image if possible - FIXME: We should cache the histogram data and recompute only when the histogram image has changed */
	if(sourceImage && histogramImage) {
		/* Get a buffer representation from the histogram image */
		colorSpace = (CGColorSpaceGetModel([histogramImage imageColorSpace]) == kCGColorSpaceModelRGB ? [histogramImage imageColorSpace] : [context colorSpace]);
		if(![histogramImage lockBufferRepresentationWithPixelFormat:QCPlugInPixelFormatARGB8 colorSpace:colorSpace forBounds:[histogramImage imageBounds]])
		return NO;
		
		/* Compute the histograms for the buffer */
		buffer.data = (void*)[histogramImage bufferBaseAddress];
		buffer.rowBytes = [histogramImage bufferBytesPerRow];
		buffer.width = [histogramImage bufferPixelsWide];
		buffer.height = [histogramImage bufferPixelsHigh];
		histograms[0] = histogramA;
		histograms[1] = histogramR;
		histograms[2] = histogramG;
		histograms[3] = histogramB;
		error = vImageHistogramCalculation_ARGB8888(&buffer, histograms, 0);
		
		/* Release the buffer representation and handle errors */
		[histogramImage unlockBufferRepresentation];
		if(error != kvImageNoError)
		return NO;
		
		/* Get a buffer representation from the source image */
		colorSpace = (CGColorSpaceGetModel([sourceImage imageColorSpace]) == kCGColorSpaceModelRGB ? [sourceImage imageColorSpace] : [context colorSpace]);
		if(![sourceImage lockBufferRepresentationWithPixelFormat:format colorSpace:colorSpace forBounds:[sourceImage imageBounds]])
		return NO;
		
		/* Create memory buffer */
		pixelsWide = [sourceImage bufferPixelsWide];
		pixelsHigh = [sourceImage bufferPixelsHigh];
		rowBytes = pixelsWide * ([format isEqualToString:QCPlugInPixelFormatRGBAf] ? 16 : 4);
		if(rowBytes % 16)
		rowBytes = (rowBytes / 16 + 1) * 16;
		pixelBuffer = valloc(pixelsHigh * rowBytes);
		if(pixelBuffer == NULL)
		return NO;
		
		/* Apply the previously computed histogram on the source image and render the result to the output buffer */
		inBuffer.data = (void*)[sourceImage bufferBaseAddress];
		inBuffer.rowBytes = [sourceImage bufferBytesPerRow];
		inBuffer.width = pixelsWide;
		inBuffer.height = pixelsHigh;
		outBuffer.data = pixelBuffer;
		outBuffer.rowBytes = rowBytes;
		outBuffer.width = pixelsWide;
		outBuffer.height = pixelsHigh;
		if([format isEqualToString:QCPlugInPixelFormatRGBAf])
		error = vImageHistogramSpecification_ARGBFFFF(&inBuffer, &outBuffer, NULL, (const vImagePixelCount**)histograms, 256, 0.0, 1.0, 0);
		else if([format isEqualToString:QCPlugInPixelFormatARGB8])
		error = vImageHistogramSpecification_ARGB8888(&inBuffer, &outBuffer, (const vImagePixelCount**)histograms, 0);
		else if([format isEqualToString:QCPlugInPixelFormatBGRA8]) { //We need to convert the histogram from ARGB to BGRA
			temp = histograms[0];
			histograms[0] = histograms[3];
			histograms[3] = temp;
			temp = histograms[1];
			histograms[1] = histograms[2];
			histograms[2] = temp;
			error = vImageHistogramSpecification_ARGB8888(&inBuffer, &outBuffer, (const vImagePixelCount**)histograms, 0);
		}
		else
		error = -1; //This has no reason to ever happen
		
		/* Release the buffer representation and handle errors */
		[sourceImage unlockBufferRepresentation];
		if(error != kvImageNoError) {
			free(pixelBuffer);
			return NO;
		}
		
		/* Create simple provider from memory buffer */
		provider = [context outputImageProviderFromBufferWithPixelFormat:format pixelsWide:pixelsWide pixelsHigh:pixelsHigh baseAddress:pixelBuffer bytesPerRow:rowBytes releaseCallback:_BufferReleaseCallback releaseContext:NULL colorSpace:colorSpace shouldColorMatch:YES];
		if(provider == nil) {
			free(pixelBuffer);
			return NO;
		}
	}
	else
	provider = nil;
	
	/* Update the result image */
	self.outputResultImage = provider;
	
	return YES;
}

#endif

@end

#if __USE_PROVIDER__

@implementation Histogram

- (id) initWithImageSource:(id<QCPlugInInputImageSource>)image colorSpace:(CGColorSpaceRef)colorSpace
{
	/* Make sure we have an image */
	if(!image) {
		[self release];
		return nil;
	}
	
	/* Keep the image around and the processing colorspace */
	if(self = [super init]) {
		_image = [(id)image retain];
		_colorSpace = CGColorSpaceRetain(colorSpace);
	}
	
	return self;
}

- (void) dealloc
{
	/* Release the image and processing colorspace */
	[(id)_image release];
	CGColorSpaceRelease(_colorSpace);
	
	[super dealloc];
}

- (BOOL) getRGBAHistograms:(vImagePixelCount**)histograms
{
	vImage_Buffer					buffer;
	vImage_Error					error;
	
	if(_image) {
		/* Get a buffer representation from the image */
		if(![_image lockBufferRepresentationWithPixelFormat:QCPlugInPixelFormatARGB8 colorSpace:_colorSpace forBounds:[_image imageBounds]])
		return NO;
		
		/* Compute the histograms for the buffer */
		buffer.data = (void*)[_image bufferBaseAddress];
		buffer.rowBytes = [_image bufferBytesPerRow];
		buffer.width = [_image bufferPixelsWide];
		buffer.height = [_image bufferPixelsHigh];
		histograms[0] = _histogramA;
		histograms[1] = _histogramR;
		histograms[2] = _histogramG;
		histograms[3] = _histogramB;
		error = vImageHistogramCalculation_ARGB8888(&buffer, histograms, 0);
		
		/* Release the buffer representation and handle errors */
		[_image unlockBufferRepresentation];
		if(error != kvImageNoError)
		return NO;
		
		/* We don't need the image anymore */
		[(id)_image release];
		_image = nil;
	}
	
	histograms[0] = _histogramR;
	histograms[1] = _histogramG;
	histograms[2] = _histogramB;
	histograms[3] = _histogramA;
	
	return YES;
}

@end

@implementation HistogramImageProvider

- (id) initWithImageSource:(id<QCPlugInInputImageSource>)image histogram:(Histogram*)histogram
{
	/* Make sure we have an image and an histogram */
	if(!image || !histogram) {
		[self release];
		return nil;
	}
	
	/* Keep the image and histogram around */
	if(self = [super init]) {
		_image = [(id)image retain];
		_histogram = [histogram retain];
	}
	
	return self;
}

- (void) dealloc
{
	/* Release the image and histogram */
	[(id)_image release];
	[_histogram release];
	
	[super dealloc];
}

- (NSRect) imageBounds
{
	/* This image has the same bounds as the source image */
	return [_image imageBounds];
}

- (CGColorSpaceRef) imageColorSpace
{
	/* Preserve the original image colorspace */
	return [_image imageColorSpace];
}

- (NSArray*) supportedBufferPixelFormats
{
	/* We only support ARGB8, BGRA8 and RGBAf */
	return [NSArray arrayWithObjects:QCPlugInPixelFormatARGB8, QCPlugInPixelFormatBGRA8, QCPlugInPixelFormatRGBAf, nil];
}

- (BOOL) renderToBuffer:(void*)baseAddress withBytesPerRow:(NSUInteger)rowBytes pixelFormat:(NSString*)format forBounds:(NSRect)bounds
{
	vImage_Buffer					inBuffer,
									outBuffer;
	vImage_Error					error;
	const vImagePixelCount*			histograms[4];
	const vImagePixelCount*			temp;
	
	/* Retrieve histogram data (this will trigger computation if necessary) */
	if(![_histogram getRGBAHistograms:(vImagePixelCount**)histograms])
	return NO;
	
	/* Get a buffer representation from the source image */
	if(![_image lockBufferRepresentationWithPixelFormat:format colorSpace:[_image imageColorSpace] forBounds:bounds])
	return NO;
	
	/* Apply the previously computed histogram on the source image and render the result to the output buffer */
	inBuffer.data = (void*)[_image bufferBaseAddress];
	inBuffer.rowBytes = [_image bufferBytesPerRow];
	inBuffer.width = [_image bufferPixelsWide];
	inBuffer.height = [_image bufferPixelsHigh];
	outBuffer.data = baseAddress;
	outBuffer.rowBytes = rowBytes;
	outBuffer.width = [_image bufferPixelsWide];
	outBuffer.height = [_image bufferPixelsHigh];
	if([format isEqualToString:QCPlugInPixelFormatRGBAf])
	error = vImageHistogramSpecification_ARGBFFFF(&inBuffer, &outBuffer, NULL, histograms, 256, 0.0, 1.0, 0);
	else if([format isEqualToString:QCPlugInPixelFormatARGB8]) { //We need to convert the histogram from RGBA to ARGB
		temp = histograms[3];
		histograms[3] = histograms[2];
		histograms[2] = histograms[1];
		histograms[1] = histograms[0];
		histograms[0] = temp;
		error = vImageHistogramSpecification_ARGB8888(&inBuffer, &outBuffer, histograms, 0);
	}
	else if([format isEqualToString:QCPlugInPixelFormatBGRA8]) { //We need to convert the histogram from RGBA to BGRA
		temp = histograms[0];
		histograms[0] = histograms[2];
		histograms[2] = temp;
		error = vImageHistogramSpecification_ARGB8888(&inBuffer, &outBuffer, histograms, 0);
	}
	else
	error = -1; //This has no reason to ever happen
	
	/* Release the buffer representation and handle errors */
	[_image unlockBufferRepresentation];
	if(error != kvImageNoError)
	return NO;
	
	return YES;
}

@end

#endif
