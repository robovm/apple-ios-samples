/*
     File: MYVolumeUnitMeterView.m
 Abstract: Volume unit meter view
  Version: 1.0.1
 
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

#import "MYVolumeUnitMeterView.h"

#import <QuartzCore/QuartzCore.h>

// This is an arbitrary calibration to define 0 db in the VU meter.
#define MYVolumeUnitMeterView_CALIBRATION 12.0f

#define DEGREE_TO_RADIAN M_PI / 180.0f

static CGFloat convertValueToNeedleAngle(CGFloat value);

@interface MYVolumeUnitMeterView ()
@property (readonly, strong, nonatomic) CALayer *needleLayer;
@end

@implementation MYVolumeUnitMeterView

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self)
	{
		[self setupLayerTree];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	if (self)
	{
		[self setupLayerTree];
	}
	
	return self;
}

#pragma mark -

- (void)setupLayerTree
{
	CGRect viewLayerBounds = self.layer.bounds;
	
	// Set layer background image.
	self.layer.contents = (id)[[UIImage imageNamed:@"VUMeterBackground"] CGImage];
	
	// Add shadow layer for needle.
	CALayer *shadowLayer = [CALayer layer];
	shadowLayer.shadowColor = [[UIColor blackColor] CGColor];
	shadowLayer.shadowOffset = CGSizeMake(0.0f, 6.0f);
	shadowLayer.shadowOpacity = 0.5f;
	shadowLayer.shadowRadius = 2.0f;
	[self.layer addSublayer:shadowLayer];
	
	// Add needle layer.
	UIImage *needleImage = [UIImage imageNamed:@"VUMeterNeedle"];
	CGSize needleImageSize = [needleImage size];
	_needleLayer = [CALayer layer];
	_needleLayer.affineTransform = CGAffineTransformMakeRotation(convertValueToNeedleAngle(-INFINITY));
	_needleLayer.anchorPoint = CGPointMake(0.5f, 1.0f);
	_needleLayer.bounds = CGRectMake(0.0f, 0.0f, needleImageSize.width, needleImageSize.height);
	_needleLayer.contents = (id)[needleImage CGImage];
	_needleLayer.position = CGPointMake(0.5f * CGRectGetWidth(viewLayerBounds), needleImageSize.height);
	[shadowLayer addSublayer:_needleLayer];
	
	// Add foreground layer.
	CALayer *foregroundLayer = [CALayer layer];
	foregroundLayer.anchorPoint = CGPointZero;
	foregroundLayer.bounds = viewLayerBounds;
	foregroundLayer.contents = (id)[[UIImage imageNamed:@"VUMeterForeground"] CGImage];
	foregroundLayer.position = CGPointZero;
	[self.layer addSublayer:foregroundLayer];
}

#pragma mark -

- (void)setValue:(float)value
{
	if (_value != value)
	{
		_value = value;
		
		// Convert RMS amplitude into dB (using some arbitrary calibration values).
		float valueDB = (20.0f * log10(value) + MYVolumeUnitMeterView_CALIBRATION);
		
		// Update needle layer.
		_needleLayer.affineTransform = CGAffineTransformMakeRotation(convertValueToNeedleAngle(valueDB));
	}
}

@end

#pragma mark Functions

// Note: This calculation is just an approximation to map the artwork.
static CGFloat convertValueToNeedleAngle(CGFloat value)
{
	float degree = (value * 5.0f + 20.0f);
	
	// The mapping from dB amplitude to angle is not linear on our VU meter.
	if (value < -7.0f && value >= -10.0f)
		degree = (-15.0f + (10.0f / 3.0f) * (value + 7.0f));
	else if (value < -10.0f)
		degree = (-25.0f + (13.0f / 10.0f) * (value + 10.0f));
	
	// Limit to visible angle.
	degree = MAX(-38.0f, MIN(degree, 43.0f));
	
	return (DEGREE_TO_RADIAN * degree);
}
