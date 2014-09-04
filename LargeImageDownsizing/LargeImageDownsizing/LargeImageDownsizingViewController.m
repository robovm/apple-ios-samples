/*
     File: LargeImageDownsizingViewController.m 
 Abstract: The primary view controller for this project. 
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

#import "LargeImageDownsizingViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ImageScrollView.h"

/* Image Constants: for images, we define the resulting image 
 size and tile size in megabytes. This translates to an amount 
 of pixels. Keep in mind this is almost always significantly different
 from the size of a file on disk for compressed formats such as png, or jpeg.

 For an image to be displayed in iOS, it must first be uncompressed (decoded) from 
 disk. The approximate region of pixel data that is decoded from disk is defined by both, 
 the clipping rect set onto the current graphics context, and the content/image 
 offset relative to the current context.

 To get the uncompressed file size of an image, use: Width x Height / pixelsPerMB, where 
 pixelsPerMB = 262144 pixels in a 32bit colospace (which iOS is optimized for).
 
 Supported formats are: PNG, TIFF, JPEG. Unsupported formats: GIF, BMP, interlaced images.
*/
#define kImageFilename @"large_leaves_70mp.jpg" // 7033x10110 image, 271 MB uncompressed

/* The arguments to the downsizing routine are the resulting image size, and 
 "tile" size. And they are defined in terms of megabytes to simplify the correlation
 between images and memory footprint available to your application.
 
 The "tile" is the maximum amount of pixel data to load from the input image into
 memory at one time. The size of the tile defines the number of iterations 
 required to piece together the resulting image.
 
 Choose a resulting size for your image given both: the hardware profile of your 
 target devices, and the amount of memory taken by the rest of your application. 
 
 Maximizing the source image tile size will minimize the time required to complete 
 the downsize routine. Thus, performance must be balanced with resulting image quality.
 
 Choosing appropriate resulting image size and tile size can be done, but is left as 
 an exercise to the developer. Note that the device type/version string 
 (e.g. "iPhone2,1" can be determined at runtime through use of the sysctlbyname function:

 size_t size;
 sysctlbyname("hw.machine", NULL, &size, NULL, 0);
 char *machine = malloc(size);
 sysctlbyname("hw.machine", machine, &size, NULL, 0);
 NSString* _platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
 free(machine);

 These constants are suggested initial values for iPad1, and iPhone 3GS */
#define IPAD1_IPHONE3GS
#ifdef IPAD1_IPHONE3GS
#   define kDestImageSizeMB 60.0f // The resulting image will be (x)MB of uncompressed image data. 
#   define kSourceImageTileSizeMB 20.0f // The tile size will be (x)MB of uncompressed image data. 
#endif

/* These constants are suggested initial values for iPad2, and iPhone 4 */
//#define IPAD2_IPHONE4
#ifdef IPAD2_IPHONE4
#   define kDestImageSizeMB 120.0f // The resulting image will be (x)MB of uncompressed image data. 
#   define kSourceImageTileSizeMB 40.0f // The tile size will be (x)MB of uncompressed image data. 
#endif

/* These constants are suggested initial values for iPhone3G, iPod2 and earlier devices */
//#define IPHONE3G_IPOD2_AND_EARLIER
#ifdef IPHONE3G_IPOD2_AND_EARLIER
#   define kDestImageSizeMB 30.0f // The resulting image will be (x)MB of uncompressed image data. 
#   define kSourceImageTileSizeMB 10.0f // The tile size will be (x)MB of uncompressed image data. 
#endif

/* Constants for all other iOS devices are left to be defined by the developer. 
 The purpose of this sample is to illustrate that device specific constants can 
 and should be created by you the developer, versus iterating a complete list. */

#define bytesPerMB 1048576.0f 
#define bytesPerPixel 4.0f
#define pixelsPerMB ( bytesPerMB / bytesPerPixel ) // 262144 pixels, for 4 bytes per pixel.
#define destTotalPixels kDestImageSizeMB * pixelsPerMB
#define tileTotalPixels kSourceImageTileSizeMB * pixelsPerMB
#define destSeemOverlap 2.0f // the numbers of pixels to overlap the seems where tiles meet.

@implementation LargeImageDownsizingViewController

@synthesize destImage;

// release ownership
- (void)dealloc {
    [destImage release];
    [scrollView release];
    //--
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
/*
 -(void)loadView {
 
 }*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    //--
    progressView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:progressView];
    [progressView release];
    [NSThread detachNewThreadSelector:@selector(downsize:) toTarget:self withObject:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)downsize:(id)arg {
    // create an autorelease pool to catch calls to -autorelease.
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    // create an image from the image filename constant. Note this
    // doesn't actually read any pixel information from disk, as that
    // is actually done at draw time.
    sourceImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:kImageFilename ofType:nil]];
    if( sourceImage == nil ) NSLog(@"input image not found!");
    // get the width and height of the input image using 
    // core graphics image helper functions.
    sourceResolution.width = CGImageGetWidth(sourceImage.CGImage);
    sourceResolution.height = CGImageGetHeight(sourceImage.CGImage);
    // use the width and height to calculate the total number of pixels
    // in the input image.
    sourceTotalPixels = sourceResolution.width * sourceResolution.height;
    // calculate the number of MB that would be required to store 
    // this image uncompressed in memory.
    sourceTotalMB = sourceTotalPixels / pixelsPerMB;
    // determine the scale ratio to apply to the input image
    // that results in an output image of the defined size.
    // see kDestImageSizeMB, and how it relates to destTotalPixels.
    imageScale = destTotalPixels / sourceTotalPixels;
    // use the image scale to calcualte the output image width, height
    destResolution.width = (int)( sourceResolution.width * imageScale );
    destResolution.height = (int)( sourceResolution.height * imageScale );
    // create an offscreen bitmap context that will hold the output image
    // pixel data, as it becomes available by the downscaling routine.
    // use the RGB colorspace as this is the colorspace iOS GPU is optimized for.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bytesPerRow = bytesPerPixel * destResolution.width;
    // allocate enough pixel data to hold the output image.
    void* destBitmapData = malloc( bytesPerRow * destResolution.height );
    if( destBitmapData == NULL ) NSLog(@"failed to allocate space for the output image!");
    // create the output bitmap context
    destContext = CGBitmapContextCreate( destBitmapData, destResolution.width, destResolution.height, 8, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast );
    // remember CFTypes assign/check for NULL. NSObjects assign/check for nil.
    if( destContext == NULL ) {
        free( destBitmapData ); 
        NSLog(@"failed to create the output bitmap context!");
    }        
    // release the color space object as its job is done
    CGColorSpaceRelease( colorSpace );
    // flip the output graphics context so that it aligns with the 
    // cocoa style orientation of the input document. this is needed
    // because we used cocoa's UIImage -imageNamed to open the input file.
	CGContextTranslateCTM( destContext, 0.0f, destResolution.height );
	CGContextScaleCTM( destContext, 1.0f, -1.0f );
    // now define the size of the rectangle to be used for the 
    // incremental blits from the input image to the output image.
    // we use a source tile width equal to the width of the source
    // image due to the way that iOS retrieves image data from disk.
    // iOS must decode an image from disk in full width 'bands', even
    // if current graphics context is clipped to a subrect within that
    // band. Therefore we fully utilize all of the pixel data that results
    // from a decoding opertion by achnoring our tile size to the full
    // width of the input image. 
    sourceTile.size.width = sourceResolution.width;
    // the source tile height is dynamic. Since we specified the size
    // of the source tile in MB, see how many rows of pixels high it
    // can be given the input image width.
    sourceTile.size.height = (int)( tileTotalPixels / sourceTile.size.width );     
    NSLog(@"source tile size: %f x %f",sourceTile.size.width, sourceTile.size.height);
    sourceTile.origin.x = 0.0f;
    // the output tile is the same proportions as the input tile, but
    // scaled to image scale.
    destTile.size.width = destResolution.width;
    destTile.size.height = sourceTile.size.height * imageScale;        
    destTile.origin.x = 0.0f;
    NSLog(@"dest tile size: %f x %f",destTile.size.width, destTile.size.height);
    // the source seem overlap is proportionate to the destination seem overlap. 
    // this is the amount of pixels to overlap each tile as we assemble the ouput image.
    sourceSeemOverlap = (int)( ( destSeemOverlap / destResolution.height ) * sourceResolution.height );
    NSLog(@"dest seem overlap: %f, source seem overlap: %f",destSeemOverlap, sourceSeemOverlap);    
    CGImageRef sourceTileImageRef;
    // calculate the number of read/write opertions required to assemble the 
    // output image.
    int iterations = (int)( sourceResolution.height / sourceTile.size.height );
    // if tile height doesn't divide the image height evenly, add another iteration
    // to account for the remaining pixels.
    int remainder = (int)sourceResolution.height % (int)sourceTile.size.height;
    if( remainder ) iterations++;
    // add seem overlaps to the tiles, but save the original tile height for y coordinate calculations.
    float sourceTileHeightMinusOverlap = sourceTile.size.height;
    sourceTile.size.height += sourceSeemOverlap;
    destTile.size.height += destSeemOverlap;    
    NSLog(@"beginning downsize. iterations: %d, tile height: %f, remainder height: %d", iterations, sourceTile.size.height,remainder );
    for( int y = 0; y < iterations; ++y ) {
        // create an autorelease pool to catch calls to -autorelease made within the downsize loop.
        NSAutoreleasePool* pool2 = [[NSAutoreleasePool alloc] init];
        NSLog(@"iteration %d of %d",y+1,iterations);
        sourceTile.origin.y = y * sourceTileHeightMinusOverlap + sourceSeemOverlap; 
        destTile.origin.y = ( destResolution.height ) - ( ( y + 1 ) * sourceTileHeightMinusOverlap * imageScale + destSeemOverlap ); 
        // create a reference to the source image with its context clipped to the argument rect.
        sourceTileImageRef = CGImageCreateWithImageInRect( sourceImage.CGImage, sourceTile );
        // if this is the last tile, it's size may be smaller than the source tile height.
        // adjust the dest tile size to account for that difference.
        if( y == iterations - 1 && remainder ) {
            float dify = destTile.size.height;
            destTile.size.height = CGImageGetHeight( sourceTileImageRef ) * imageScale;
            dify -= destTile.size.height;
            destTile.origin.y += dify;
        }
        // read and write a tile sized portion of pixels from the input image to the output image. 
        CGContextDrawImage( destContext, destTile, sourceTileImageRef );
        /* release the source tile portion pixel data. note,
         releasing the sourceTileImageRef doesn't actually release the tile portion pixel
         data that we just drew, but the call afterward does. */
        CGImageRelease( sourceTileImageRef ); 
        /* while CGImageCreateWithImageInRect lazily loads just the image data defined by the argument rect, 
         that data is finally decoded from disk to mem when CGContextDrawImage is called. sourceTileImageRef 
         maintains internally a reference to the original image, and that original image both, houses and 
         caches that portion of decoded mem. Thus the following call to release the source image. */
        [sourceImage release];
        // free all objects that were sent -autorelease within the scope of this loop.
        [pool2 drain];     
        // we reallocate the source image after the pool is drained since UIImage -imageNamed
        // returns us an autoreleased object.         
        if( y < iterations - 1 ) {            
            sourceImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:kImageFilename ofType:nil]];
            [self performSelectorOnMainThread:@selector(updateScrollView:) withObject:nil waitUntilDone:YES];
        }
    }
    NSLog(@"downsize complete.");
    [self performSelectorOnMainThread:@selector(initializeScrollView:) withObject:nil waitUntilDone:YES];
    // free the context since its job is done. destImageRef retains the pixel data now.
	CGContextRelease( destContext );
    [pool drain];
}

-(void)createImageFromContext {
    // create a CGImage from the offscreen image context
    CGImageRef destImageRef = CGBitmapContextCreateImage( destContext );
    if( destImageRef == NULL ) NSLog(@"destImageRef is null.");
    // wrap a UIImage around the CGImage
    self.destImage = [UIImage imageWithCGImage:destImageRef scale:1.0f orientation:UIImageOrientationDownMirrored];
    // release ownership of the CGImage, since destImage retains ownership of the object now.
    CGImageRelease( destImageRef );
    if( destImage == nil ) NSLog(@"destImage is nil.");
}

-(void)updateScrollView:(id)arg {
    [self createImageFromContext];
    // display the output image on the screen.
    progressView.image = destImage;
}

-(void)initializeScrollView:(id)arg {
    [progressView removeFromSuperview];
    [self createImageFromContext];
    // create a scroll view to display the resulting image.
    scrollView = [[ImageScrollView alloc] initWithFrame:self.view.bounds image:self.destImage];
    [self.view addSubview:scrollView];
}

@end
