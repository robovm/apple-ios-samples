/*
     File: LargeImageDownsizingViewController.h 
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

#import <UIKit/UIKit.h>

@class ImageScrollView;

@interface LargeImageDownsizingViewController : UIViewController {
    // The input image file
    UIImage* sourceImage;
    // output image file
    UIImage* destImage;
    // sub rect of the input image bounds that represents the 
    // maximum amount of pixel data to load into mem at one time.
    CGRect sourceTile;
    // sub rect of the output image that is proportionate to the
    // size of the sourceTile. 
    CGRect destTile;
    // the ratio of the size of the input image to the output image.
    float imageScale;
    // source image width and height
    CGSize sourceResolution;
    // total number of pixels in the source image
    float sourceTotalPixels;
    // total number of megabytes of uncompressed pixel data in the source image.
    float sourceTotalMB;
    // output image width and height
    CGSize destResolution;
    // the temporary container used to hold the resulting output image pixel 
    // data, as it is being assembled.
    CGContextRef destContext;
    // the number of pixels to overlap tiles as they are assembled.
    float sourceSeemOverlap;
    // an image view to visualize the image as it is being pieced together
    UIImageView* progressView;
    // a scroll view to display the resulting downsized image
    ImageScrollView* scrollView;
}
// destImage property is specifically thread safe (i.e. no 'nonatomic' attribute) 
// because it is accessed off the main thread.
@property (retain) UIImage* destImage; 

-(void)downsize:(id)arg;
-(void)updateScrollView:(id)arg;
-(void)initializeScrollView:(id)arg;
-(void)createImageFromContext;

@end
