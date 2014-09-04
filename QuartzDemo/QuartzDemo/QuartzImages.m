/*
     File: QuartzImages.m
 Abstract: Demonstrates using Quartz for drawing images (QuartzImageView), PDF files (QuartzPDFView), and text (QuartzTextView).
  Version: 3.0
 
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

#import "QuartzImages.h"


@implementation QuartzImageView
{
    CGImageRef _image;
}

-(void)drawInContext:(CGContextRef)context
{
	CGRect imageRect;
	imageRect.origin = CGPointMake(8.0, 8.0);
	imageRect.size = CGSizeMake(64.0, 64.0);
	
	// Note: The images are actually drawn upside down because Quartz image drawing expects
	// the coordinate system to have the origin in the lower-left corner, but a UIView
	// puts the origin in the upper-left corner. For the sake of brevity (and because
	// it likely would go unnoticed for the image used) this is not addressed here.
	// For the demonstration of PDF drawing however, it is addressed, as it would definately
	// be noticed, and one method of addressing it is shown there.

	// Draw the image in the upper left corner (0,0) with size 64x64
	CGContextDrawImage(context, imageRect, self.image);
	
	// Tile the same image across the bottom of the view
	// CGContextDrawTiledImage() will fill the entire clipping area with the image, so to avoid
	// filling the entire view, we'll clip the view to the rect below. This rect extends
	// past the region of the view, but since the view's rectangle has already been applied as a clip
	// to our drawing area, it will be intersected with this rect to form the final clipping area
	CGContextClipToRect(context, CGRectMake(0.0, 80.0, self.bounds.size.width, self.bounds.size.height));
	
	// The origin of the image rect works similarly to the phase parameter for SetLineDash and
	// SetPatternPhase and specifies where in the coordinate system the "first" image is drawn.
	// The size (previously set to 64x64) specifies the size the image is scaled to before being tiled.
	imageRect.origin = CGPointMake(32.0, 112.0);
	CGContextDrawTiledImage(context, imageRect, self.image);
	
	// Highlight the "first" image from the DrawTiledImage call.
	CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 0.5);
	CGContextFillRect(context, imageRect);
	// And stroke the clipped area
	CGContextSetLineWidth(context, 3.0);
	CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
	CGContextStrokeRect(context, CGContextGetClipBoundingBox(context));
}


- (CGImageRef)image
{
	if (_image == NULL)
	{
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"Demo" ofType:@"png"];
		UIImage *img = [UIImage imageWithContentsOfFile:imagePath];
		_image = CGImageRetain(img.CGImage);
	}
	return _image;

}


-(void)dealloc
{
	CGImageRelease(_image);
}


@end





#pragma mark -

@implementation QuartzPDFView
{
	CGPDFDocumentRef _pdfDocument;
}


-(void)drawInContext:(CGContextRef)context
{
	// PDF page drawing expects a Lower-Left coordinate system, so we flip the coordinate system
	// before we start drawing.
	CGContextTranslateCTM(context, 0.0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	// Grab the first PDF page
	CGPDFPageRef page = CGPDFDocumentGetPage(self.pdfDocument, 1);
	// We're about to modify the context CTM to draw the PDF page where we want it, so save the graphics state in case we want to do more drawing
	CGContextSaveGState(context);
	// CGPDFPageGetDrawingTransform provides an easy way to get the transform for a PDF page. It will scale down to fit, including any
	// base rotations necessary to display the PDF page correctly. 
	CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, self.bounds, 0, true);
	// And apply the transform.
	CGContextConcatCTM(context, pdfTransform);
	// Finally, we draw the page and restore the graphics state for further manipulations!
	CGContextDrawPDFPage(context, page);
	CGContextRestoreGState(context);
}


-(CGPDFDocumentRef)pdfDocument
{
	if (_pdfDocument == NULL)
	{
		CFURLRef pdfURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("Quartz.pdf"), NULL, NULL);
		_pdfDocument = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
		CFRelease(pdfURL);
	}
	return _pdfDocument;
}


-(void)dealloc
{
	CGPDFDocumentRelease(_pdfDocument);
}

@end



#pragma mark -

@implementation QuartzTextView

#define kTextString "Hello From Quartz"
#define kTextStringLength strlen(kTextString)

-(void)drawInContext:(CGContextRef)context
{
	CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
	CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);

	// Some initial setup for our text drawing needs.
	// First, we will be doing our drawing in Helvetica-36pt with the MacRoman encoding.
	// This is an 8-bit encoding that can reference standard ASCII characters
	// and many common characters used in the Americas and Western Europe.
	CGContextSelectFont(context, "Helvetica", 36.0, kCGEncodingMacRoman);
	// Next we set the text matrix to flip our text upside down. We do this because the context itself
	// is flipped upside down relative to the expected orientation for drawing text (much like the case for drawing Images & PDF).
	CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1.0, -1.0));
	// And now we actually draw some text. This screen will demonstrate the typical drawing modes used.
	CGContextSetTextDrawingMode(context, kCGTextFill);
	CGContextShowTextAtPoint(context, 10.0, 30.0, kTextString, kTextStringLength);
	CGContextSetTextDrawingMode(context, kCGTextStroke);
	CGContextShowTextAtPoint(context, 10.0, 70.0, kTextString, kTextStringLength);
	CGContextSetTextDrawingMode(context, kCGTextFillStroke);
	CGContextShowTextAtPoint(context, 10.0, 110.0, kTextString, kTextStringLength);
	
	// Now lets try the more complex Glyph functions. These functions allow you to draw any glyph available in a font,
	// but provide no assistance with converting characters to glyphs or layout, and as such require considerably more knowledge
	// of text to use correctly. Specifically, you need to understand Unicode encoding and how to interpret the information
	// present in the font itself, such as the cmap table.
	// To get you started, we are going to do the minimum necessary to draw a glyphs into the current context.
	CGFontRef helvetica = CGFontCreateWithFontName((CFStringRef)@"Helvetica");
	CGContextSetFont(context, helvetica);
	CGContextSetFontSize(context, 12.0);
	CGContextSetTextDrawingMode(context, kCGTextFill);
	// Next we'll display lots of glyphs from the font. 
	CGGlyph start = 0;
	for(int y = 0; y < 20; ++y)
	{
		CGGlyph glyphs[32];
		for(int i = 0; i < 32; ++i)
		{
			glyphs[i] = start + i;
		}
		start += 32;
		CGContextShowGlyphsAtPoint(context, 10.0, 150.0 + 12 * y, glyphs, 32);
	}
	CGFontRelease(helvetica);
}

@end