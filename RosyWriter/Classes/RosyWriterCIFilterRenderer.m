/*
	    File: RosyWriterCIFilterRenderer.m
	Abstract: The RosyWriter CoreImage CIFilter-based effect renderer
	 Version: 2.1
	
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

#import "RosyWriterCIFilterRenderer.h"

@interface RosyWriterCIFilterRenderer ()
{
	CIContext *_ciContext;
	CIFilter *_rosyFilter;
	CGColorSpaceRef _rgbColorSpace;
	CVPixelBufferPoolRef _bufferPool;
	CFDictionaryRef _bufferPoolAuxAttributes;
	CMFormatDescriptionRef _outputFormatDescription;
}

@end

@implementation RosyWriterCIFilterRenderer

#pragma mark API

- (void)dealloc
{
	[self deleteBuffers];
	[super dealloc];
}

#pragma mark RosyWriterRenderer

- (BOOL)operatesInPlace
{
	return NO;
}

- (FourCharCode)inputPixelFormat
{
	return kCVPixelFormatType_32BGRA;
}

- (void)prepareForInputWithFormatDescription:(CMFormatDescriptionRef)inputFormatDescription outputRetainedBufferCountHint:(size_t)outputRetainedBufferCountHint
{
	// The input and output dimensions are the same. This renderer doesn't do any scaling.
	CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions( inputFormatDescription );
	
	[self deleteBuffers];
	if ( ! [self initializeBuffersWithOutputDimensions:dimensions retainedBufferCountHint:outputRetainedBufferCountHint] ) {
		@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem preparing renderer." userInfo:nil];
	}
	
	_rgbColorSpace = CGColorSpaceCreateDeviceRGB();
	EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	_ciContext = [[CIContext contextWithEAGLContext:eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ] retain];
	[eaglContext release];
	
	_rosyFilter = [[CIFilter filterWithName:@"CIColorMatrix"] retain];
	CGFloat greenCoefficients[4] = { 0, 0, 0, 0 };
	[_rosyFilter setValue:[CIVector vectorWithValues:greenCoefficients count:4] forKey:@"inputGVector"];
}

- (void)reset
{
	[self deleteBuffers];
}

- (CVPixelBufferRef)copyRenderedPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
	OSStatus err = noErr;
	CVPixelBufferRef renderedOutputPixelBuffer = NULL;

	CIImage *sourceImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:nil];
	
	[_rosyFilter setValue:sourceImage forKey:kCIInputImageKey];
	CIImage *filteredImage = [_rosyFilter valueForKey:kCIOutputImageKey];
	
	err = CVPixelBufferPoolCreatePixelBuffer( kCFAllocatorDefault, _bufferPool, &renderedOutputPixelBuffer );
	if ( err ) {
		NSLog(@"Cannot obtain a pixel buffer from the buffer pool (%d)", (int)err );
		goto bail;
	}
	
	// render the filtered image out to a pixel buffer (no locking needed as CIContext's render method will do that)
	[_ciContext render:filteredImage toCVPixelBuffer:renderedOutputPixelBuffer bounds:[filteredImage extent] colorSpace:_rgbColorSpace];

bail:
	[sourceImage release];
	return renderedOutputPixelBuffer;
}

- (CMFormatDescriptionRef)outputFormatDescription
{
	return _outputFormatDescription;
}

#pragma mark Internal

- (BOOL)initializeBuffersWithOutputDimensions:(CMVideoDimensions)outputDimensions retainedBufferCountHint:(size_t)clientRetainedBufferCountHint
{
	BOOL success = YES;
	
	size_t maxRetainedBufferCount = clientRetainedBufferCountHint;
	_bufferPool = createPixelBufferPool( outputDimensions.width, outputDimensions.height, kCVPixelFormatType_32BGRA, (int32_t)maxRetainedBufferCount );
	if ( ! _bufferPool ) {
		NSLog( @"Problem initializing a buffer pool." );
		success = NO;
		goto bail;
	}
	
	_bufferPoolAuxAttributes = createPixelBufferPoolAuxAttributes( (int32_t)maxRetainedBufferCount );
	preallocatePixelBuffersInPool( _bufferPool, _bufferPoolAuxAttributes );
	
	CMFormatDescriptionRef outputFormatDescription = NULL;
	CVPixelBufferRef testPixelBuffer = NULL;
	CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, _bufferPool, _bufferPoolAuxAttributes, &testPixelBuffer );
	if ( ! testPixelBuffer ) {
		NSLog( @"Problem creating a pixel buffer." );
		success = NO;
		goto bail;
	}
	CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, testPixelBuffer, &outputFormatDescription );
	_outputFormatDescription = outputFormatDescription;
	CFRelease( testPixelBuffer );
	
bail:
	if ( ! success ) {
		[self deleteBuffers];
	}
	return success;
}

- (void)deleteBuffers
{
	if ( _bufferPool ) {
		CFRelease( _bufferPool );
		_bufferPool = NULL;
	}
	if ( _bufferPoolAuxAttributes ) {
		CFRelease( _bufferPoolAuxAttributes );
		_bufferPoolAuxAttributes = NULL;
	}
	if ( _outputFormatDescription ) {
		CFRelease( _outputFormatDescription );
		_outputFormatDescription = NULL;
	}
	if ( _ciContext ) {
		[_ciContext release];
		_ciContext = nil;
	}
	if ( _rosyFilter ) {
		[_rosyFilter release];
		_rosyFilter = nil;
	}
	if ( _rgbColorSpace ) {
		CFRelease( _rgbColorSpace );
		_rgbColorSpace = NULL;
	}
}

static CVPixelBufferPoolRef createPixelBufferPool( int32_t width, int32_t height, OSType pixelFormat, int32_t maxBufferCount )
{
	CVPixelBufferPoolRef outputPool = NULL;
	
	NSDictionary *sourcePixelBufferOptions = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(pixelFormat),
												(id)kCVPixelBufferWidthKey : @(width),
												(id)kCVPixelBufferHeightKey : @(height),
												(id)kCVPixelFormatOpenGLESCompatibility : @(YES),
												(id)kCVPixelBufferIOSurfacePropertiesKey : @{} };
	
	NSDictionary *pixelBufferPoolOptions = @{ (id)kCVPixelBufferPoolMinimumBufferCountKey : @(maxBufferCount) };

	CVPixelBufferPoolCreate( kCFAllocatorDefault, (CFDictionaryRef)pixelBufferPoolOptions, (CFDictionaryRef)sourcePixelBufferOptions, &outputPool );

	return outputPool;
}

static CFDictionaryRef createPixelBufferPoolAuxAttributes( int32_t maxBufferCount )
{
	// CVPixelBufferPoolCreatePixelBufferWithAuxAttributes() will return kCVReturnWouldExceedAllocationThreshold if we have already vended the max number of buffers
	NSDictionary *auxAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:@(maxBufferCount), (id)kCVPixelBufferPoolAllocationThresholdKey, nil];
	return (CFDictionaryRef)auxAttributes;
}

static void preallocatePixelBuffersInPool( CVPixelBufferPoolRef pool, CFDictionaryRef auxAttributes )
{
	// Preallocate buffers in the pool, since this is for real-time display/capture
	NSMutableArray *pixelBuffers = [[NSMutableArray alloc] init];
	while ( 1 )
	{
		CVPixelBufferRef pixelBuffer = NULL;
		OSStatus err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer );
		
		if ( err == kCVReturnWouldExceedAllocationThreshold ) {
			break;
		}
		assert( err == noErr );
		
		[pixelBuffers addObject:(id)pixelBuffer];
		CFRelease( pixelBuffer );
	}
	[pixelBuffers release];
}

@end
