/*
 File: PrintPhotoPageRenderer.m
 Abstract: UIPrintPageRenderer subclass for drawing an image for print.
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
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
*/

#import "PrintPhotoPageRenderer.h"

@implementation PrintPhotoPageRenderer

@synthesize imageToPrint;

// This code always draws one image at print time.
-(NSInteger)numberOfPages
{
  return 1;
}

/*  When using this UIPrintPageRenderer subclass to draw a photo at print
    time, the app explicitly draws all the content and need only override
    the drawPageAtIndex:inRect: to accomplish that.
 
    The following scaling algorithm is implemented here:
    1) On borderless paper, users expect to see their content scaled so that there is
	no whitespace at the edge of the paper. So this code scales the content to
	fill the paper at the expense of clipping any content that lies off the paper.
    2) On paper which is not borderless, this code scales the content so that it fills
	the paper. This reduces the size of the photo but does not clip any content.
*/
- (void)drawPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)printableRect
{
  if(self.imageToPrint){
    CGRect destRect;
    // When drawPageAtIndex:inRect: paperRect reflects the size of
    // the paper we are printing on and printableRect reflects the rectangle
    // describing the imageable area of the page, that is the portion of the page
    // that the printer can mark without clipping.
    CGSize paperSize = self.paperRect.size;
    CGSize imageableAreaSize = self.printableRect.size;
    // If the paperRect and printableRect have the same size, the sheet is borderless and we will use
    // the fill algorithm. Otherwise we will uniformly scale the image to fit the imageable area as close
    // as is possible without clipping.
    BOOL fillSheet = paperSize.width == imageableAreaSize.width && paperSize.height == imageableAreaSize.height;
    CGSize imageSize = [self.imageToPrint size];
    if(fillSheet){
      destRect = CGRectMake(0, 0, paperSize.width, paperSize.height);
    }
    else
      destRect = self.printableRect;
    
    // Calculate the ratios of the destination rectangle width and height to the image width and height.
    CGFloat width_scale = (CGFloat)destRect.size.width/imageSize.width, height_scale = (CGFloat)destRect.size.height/imageSize.height;
    CGFloat scale;
    if(fillSheet)
      scale = width_scale > height_scale ? width_scale : height_scale;	  // This produces a fill to the entire sheet and clips content.
    else
      scale = width_scale < height_scale ? width_scale : height_scale;	  // This shows all the content at the expense of additional white space.

    // Locate destRect so that the scaled image is centered on the sheet. 
    destRect = CGRectMake((paperSize.width - imageSize.width*scale)/2,
			  (paperSize.height - imageSize.height*scale)/2, 
			  imageSize.width*scale, imageSize.height*scale);
    // Use UIKit to draw the image to destRect.
    [self.imageToPrint drawInRect:destRect];
  }else {
    NSLog(@"%s No image to draw!", __func__);
  }
}

@end
