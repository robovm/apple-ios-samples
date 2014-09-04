/*
     File: MyViewController.m
 Abstract: Main view controller for displaying the image, reflection and slider table.
  Version: 1.8
 
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

#import "MyViewController.h"
#import "SliderCell.h"

@interface MyViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIImageView *reflectionView;
@property (nonatomic, strong) IBOutlet UITableView *slidersTableView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *reflectionViewHeightConstraint;

@end


#pragma mark -

@implementation MyViewController

// image reflection
static const CGFloat kDefaultReflectionFraction = 0.65;
static const CGFloat kDefaultReflectionOpacity = 0.40;

static NSString *kCellID = @"CellID";

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    [self.slidersTableView registerClass:[SliderCell class] forCellReuseIdentifier:kCellID];
    
    self.slidersTableView.backgroundColor = [UIColor whiteColor];
    
	self.view.autoresizesSubviews = YES;
	self.view.userInteractionEnabled = YES;
	
	// determine the size of the reflection to create
	int reflectionHeight = self.imageView.bounds.size.height * kDefaultReflectionFraction;
	
	// create the reflection image and assign it to the UIImageView
	self.reflectionView.image = [self reflectedImage:self.imageView withHeight:reflectionHeight];
	self.reflectionView.alpha = kDefaultReflectionOpacity;
}


#pragma mark - slider action methods

- (IBAction)sizeSlideAction:(id)sender
{
    UISlider *slider = (UISlider *)sender;
	CGFloat val = [slider value];
	
	// change the height constraint of our reflected image view
    NSInteger reflectionHeight = 180 * val;    // 180 is the original maximum height of the reflected image
    self.reflectionViewHeightConstraint.constant = reflectionHeight;
    
    // create the reflection image, assign it to the UIImageView and add the image view to the containerView
	self.reflectionView.image = [self reflectedImage:self.imageView withHeight:reflectionHeight];
	
	// get the alpha slider value, keep it set on the reflection
	UISlider *alphaSlider = (UISlider *)[[self.slidersTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]].contentView viewWithTag:kSliderTag];
	self.reflectionView.alpha = alphaSlider.value;
	
	UITableViewCell *sliderCell = [self.slidersTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    sliderCell.detailTextLabel.text = [NSString stringWithFormat:@"%0.2f", val];
}

- (IBAction)alphaSlideAction:(id)sender
{
	UISlider *slider = (UISlider *)sender;
	CGFloat val = [slider value];
	self.reflectionView.alpha = val;
	
	[self.slidersTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]].detailTextLabel.text = [NSString stringWithFormat:@"%0.2f", val];
}


#pragma mark - Image Reflection

CGImageRef CreateGradientImage(NSInteger pixelsWide, NSInteger pixelsHigh)
{
	CGImageRef theCGImage = NULL;
    
	// gradient is always black-white and the mask must be in the gray colorspace
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	
	// create the bitmap context
	CGContextRef gradientBitmapContext = CGBitmapContextCreate(NULL, pixelsWide, pixelsHigh,
															   8, 0, colorSpace, kCGImageAlphaNone);
	
	// define the start and end grayscale values (with the alpha, even though
	// our bitmap context doesn't support alpha the gradient requires it)
	CGFloat colors[] = {0.0, 1.0, 1.0, 1.0};
	
	// create the CGGradient and then release the gray color space
	CGGradientRef grayScaleGradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
	CGColorSpaceRelease(colorSpace);
	
	// create the start and end points for the gradient vector (straight down)
	CGPoint gradientStartPoint = CGPointZero;
	CGPoint gradientEndPoint = CGPointMake(0, pixelsHigh);
	
	// draw the gradient into the gray bitmap context
	CGContextDrawLinearGradient(gradientBitmapContext, grayScaleGradient, gradientStartPoint,
								gradientEndPoint, kCGGradientDrawsAfterEndLocation);
	CGGradientRelease(grayScaleGradient);
	
	// convert the context into a CGImageRef and release the context
	theCGImage = CGBitmapContextCreateImage(gradientBitmapContext);
	CGContextRelease(gradientBitmapContext);
	
	// return the imageref containing the gradient
    return theCGImage;
}

CGContextRef MyCreateBitmapContext(NSInteger pixelsWide, NSInteger pixelsHigh)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	// create the bitmap context
	CGContextRef bitmapContext = CGBitmapContextCreate (NULL, pixelsWide, pixelsHigh, 8,
														0, colorSpace,
														// this will give us an optimal BGRA format for the device:
														(kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
	CGColorSpaceRelease(colorSpace);
    
    return bitmapContext;
}

- (UIImage *)reflectedImage:(UIImageView *)fromImage withHeight:(NSInteger)height
{
    if (height == 0)
		return nil;
    
	// create a bitmap graphics context the size of the image
	CGContextRef mainViewContentContext = MyCreateBitmapContext(fromImage.bounds.size.width, height);
	
	// create a 2 bit CGImage containing a gradient that will be used for masking the
	// main view content to create the 'fade' of the reflection.  The CGImageCreateWithMask
	// function will stretch the bitmap image as required, so we can create a 1 pixel wide gradient
	CGImageRef gradientMaskImage = CreateGradientImage(1, height);
	
	// create an image by masking the bitmap of the mainView content with the gradient view
	// then release the  pre-masked content bitmap and the gradient bitmap
	CGContextClipToMask(mainViewContentContext, CGRectMake(0.0, 0.0, fromImage.bounds.size.width, height), gradientMaskImage);
	CGImageRelease(gradientMaskImage);
	
	// In order to grab the part of the image that we want to render, we move the context origin to the
	// height of the image that we want to capture, then we flip the context so that the image draws upside down.
	CGContextTranslateCTM(mainViewContentContext, 0.0, height);
	CGContextScaleCTM(mainViewContentContext, 1.0, -1.0);
	
	// draw the image into the bitmap context
	CGContextDrawImage(mainViewContentContext, fromImage.bounds, fromImage.image.CGImage);
	
	// create CGImageRef of the main view bitmap content, and then release that bitmap context
	CGImageRef reflectionImage = CGBitmapContextCreateImage(mainViewContentContext);
	CGContextRelease(mainViewContentContext);
	
	// convert the finished reflection image to a UIImage
	UIImage *theImage = [UIImage imageWithCGImage:reflectionImage];
	
	// image is retained by the property setting above, so we can release the original
	CGImageRelease(reflectionImage);
	
	return theImage;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 40.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	SliderCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    UISlider *slider = (UISlider *)[cell.contentView viewWithTag:kSliderTag];
	if (indexPath.row == 0)
	{
		cell.textLabel.text = @"Size";
		slider.value = kDefaultReflectionFraction;
		[slider addTarget:self action:@selector(sizeSlideAction:) forControlEvents:UIControlEventValueChanged];
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%0.2f", slider.value];
	}
	else
	{
		cell.textLabel.text = @"Alpha";
		slider.value = kDefaultReflectionOpacity;
		[slider addTarget:self action:@selector(alphaSlideAction:) forControlEvents:UIControlEventValueChanged];
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%0.2f", slider.value];
	}
    
	return cell;
}

@end
