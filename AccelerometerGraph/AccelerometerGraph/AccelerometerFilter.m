/*
     File: AccelerometerFilter.m
 Abstract: Implements a low and high pass filter with optional adaptive filtering.
  Version: 2.6
 
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

#import "AccelerometerFilter.h"

// Implementation of the basic filter. All it does is mirror input to output.

@implementation AccelerometerFilter

@synthesize x, y, z, adaptive;

- (void)addAcceleration:(UIAcceleration *)accel
{
	x = accel.x;
	y = accel.y;
	z = accel.z;
}

- (NSString *)name
{
	return @"You should not see this";
}

@end


#pragma mark -

#define kAccelerometerMinStep				0.02
#define kAccelerometerNoiseAttenuation		3.0

double Norm(double x, double y, double z)
{
	return sqrt(x * x + y * y + z * z);
}

double Clamp(double v, double min, double max)
{
	if(v > max)
		return max;
	else if(v < min)
		return min;
	else
		return v;
}


#pragma mark -

// See http://en.wikipedia.org/wiki/Low-pass_filter for details low pass filtering
@implementation LowpassFilter

- (id)initWithSampleRate:(double)rate cutoffFrequency:(double)freq
{
	self = [super init];
	if(self != nil)
	{
		double dt = 1.0 / rate;
		double RC = 1.0 / freq;
		filterConstant = dt / (dt + RC);
	}
	return self;
}

- (void)addAcceleration:(UIAcceleration *)accel
{
	double alpha = filterConstant;
	
	if(adaptive)
	{
		double d = Clamp(fabs(Norm(x, y, z) - Norm(accel.x, accel.y, accel.z)) / kAccelerometerMinStep - 1.0, 0.0, 1.0);
		alpha = (1.0 - d) * filterConstant / kAccelerometerNoiseAttenuation + d * filterConstant;
	}
	
	x = accel.x * alpha + x * (1.0 - alpha);
	y = accel.y * alpha + y * (1.0 - alpha);
	z = accel.z * alpha + z * (1.0 - alpha);
}

- (NSString *)name
{
	return adaptive ? @"Adaptive Lowpass Filter" : @"Lowpass Filter";
}

@end


#pragma mark -

// See http://en.wikipedia.org/wiki/High-pass_filter for details on high pass filtering
@implementation HighpassFilter

- (id)initWithSampleRate:(double)rate cutoffFrequency:(double)freq
{
	self = [super init];
	if (self != nil)
	{
		double dt = 1.0 / rate;
		double RC = 1.0 / freq;
		filterConstant = RC / (dt + RC);
	}
	return self;
}

- (void)addAcceleration:(UIAcceleration *)accel
{
	double alpha = filterConstant;
	
	if (adaptive)
	{
		double d = Clamp(fabs(Norm(x, y, z) - Norm(accel.x, accel.y, accel.z)) / kAccelerometerMinStep - 1.0, 0.0, 1.0);
		alpha = d * filterConstant / kAccelerometerNoiseAttenuation + (1.0 - d) * filterConstant;
	}
	
	x = alpha * (x + accel.x - lastX);
	y = alpha * (y + accel.y - lastY);
	z = alpha * (z + accel.z - lastZ);
	
	lastX = accel.x;
	lastY = accel.y;
	lastZ = accel.z;
}

- (NSString *)name
{
	return adaptive ? @"Adaptive Highpass Filter" : @"Highpass Filter";
}

@end