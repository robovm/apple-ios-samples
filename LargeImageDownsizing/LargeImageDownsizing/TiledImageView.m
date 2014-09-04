/*
     File: TiledImageView.m 
 Abstract: View backed by CATiledLayer which is good for particularly large views. 
  Version: 1.1 
  
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

#import "TiledImageView.h"
#import <QuartzCore/QuartzCore.h>

@implementation TiledImageView

@synthesize image;

// Set the layer's class to be CATiledLayer.
+ (Class)layerClass {
	return [CATiledLayer class];
}

- (void)dealloc {
    [image release];
    //--
    [super dealloc];
}

// Create a new TiledImageView with the desired frame and scale.
-(id)initWithFrame:(CGRect)_frame image:(UIImage*)img scale:(CGFloat)scale {
    if ((self = [super initWithFrame:_frame])) {
		self.image = img;
        imageRect = CGRectMake(0.0f, 0.0f, CGImageGetWidth(image.CGImage), CGImageGetHeight(image.CGImage));
		imageScale = scale;
 		CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
		// levelsOfDetail and levelsOfDetailBias determine how
		// the layer is rendered at different zoom levels.  This
		// only matters while the view is zooming, since once the 
		// the view is done zooming a new TiledImageView is created
		// at the correct size and scale.
        tiledLayer.levelsOfDetail = 4;
		tiledLayer.levelsOfDetailBias = 4;
		tiledLayer.tileSize = CGSizeMake(512.0, 512.0);	
    }
    return self;
}

-(void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();    
	CGContextSaveGState(context);
	// Scale the context so that the image is rendered 
	// at the correct size for the zoom level.
	CGContextScaleCTM(context, imageScale,imageScale);	
	CGContextDrawImage(context, imageRect, image.CGImage);
	CGContextRestoreGState(context);	
}

@end
