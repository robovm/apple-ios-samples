/*
	    File: HistogramOperationPlugIn.h
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

#import <Quartz/Quartz.h>
#import <Accelerate/Accelerate.h>

/* Set this to 1 to use a custom <QCPlugInOutputImageProvider> class instead of the convenience method -outputImageProviderFromBufferWithPixelFormat */
#define __USE_PROVIDER__ 1

#if __USE_PROVIDER__
@class Histogram;
#endif

@interface HistogramOperationPlugIn : QCPlugIn
{
#if __USE_PROVIDER__
	Histogram*						_cachedHistogram;
#endif
}

/* Declare a property input port of type "Image" and with the key "inputSourceImage" */
@property(assign) id<QCPlugInInputImageSource> inputSourceImage;

/* Declare a property input port of type "Image" and with the key "inputHistogramImage" */
@property(assign) id<QCPlugInInputImageSource> inputHistogramImage;

/* Declare a property output port of type "Image" and with the key "outputResultImage" */
@property(assign) id<QCPlugInOutputImageProvider> outputResultImage;

@end

#if __USE_PROVIDER__

/* This internal class computes lazily an RGBA histogram from an image */
@interface Histogram : NSObject
{
	id<QCPlugInInputImageSource>	_image;
	CGColorSpaceRef					_colorSpace;
	vImagePixelCount				_histogramA[256];
	vImagePixelCount				_histogramR[256];
	vImagePixelCount				_histogramG[256];
	vImagePixelCount				_histogramB[256];
}
- (id) initWithImageSource:(id<QCPlugInInputImageSource>)image colorSpace:(CGColorSpaceRef)colorSpace;
- (BOOL) getRGBAHistograms:(vImagePixelCount**)histograms;
@end

/* This internal class represents the images this plug-in produces */
@interface HistogramImageProvider : NSObject <QCPlugInOutputImageProvider>
{
	id<QCPlugInInputImageSource>	_image;
	Histogram*						_histogram;
}
- (id) initWithImageSource:(id<QCPlugInInputImageSource>)image histogram:(Histogram*)histogram;
@end

#endif
