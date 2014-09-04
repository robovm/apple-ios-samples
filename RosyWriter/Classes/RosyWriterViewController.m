/*
     File: RosyWriterViewController.m
 Abstract: View controller for camera interface
  Version: 1.2
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <QuartzCore/QuartzCore.h>
#import "RosyWriterViewController.h"

static inline double radians (double degrees) { return degrees * (M_PI / 180); }

@implementation RosyWriterViewController

@synthesize previewView;
@synthesize recordButton;

- (void)updateLabels
{
	if (shouldShowStats) {
		NSString *frameRateString = [NSString stringWithFormat:@"%.2f FPS ", [videoProcessor videoFrameRate]];
 		frameRateLabel.text = frameRateString;
 		[frameRateLabel setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25]];
 		
 		NSString *dimensionsString = [NSString stringWithFormat:@"%d x %d ", [videoProcessor videoDimensions].width, [videoProcessor videoDimensions].height];
 		dimensionsLabel.text = dimensionsString;
 		[dimensionsLabel setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25]];
 		
 		CMVideoCodecType type = [videoProcessor videoType];
 		type = OSSwapHostToBigInt32( type );
 		NSString *typeString = [NSString stringWithFormat:@"%.4s ", (char*)&type];
 		typeLabel.text = typeString;
 		[typeLabel setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25]];
 	}
 	else {
 		frameRateLabel.text = @"";
 		[frameRateLabel setBackgroundColor:[UIColor clearColor]];
 		
 		dimensionsLabel.text = @"";
 		[dimensionsLabel setBackgroundColor:[UIColor clearColor]];
 		
 		typeLabel.text = @"";
 		[typeLabel setBackgroundColor:[UIColor clearColor]];
 	}
}

- (UILabel *)labelWithText:(NSString *)text yPosition:(CGFloat)yPosition
{
	CGFloat labelWidth = 200.0;
	CGFloat labelHeight = 40.0;
	CGFloat xPosition = previewView.bounds.size.width - labelWidth - 10;
	CGRect labelFrame = CGRectMake(xPosition, yPosition, labelWidth, labelHeight);
	UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
	[label setFont:[UIFont systemFontOfSize:36]];
	[label setLineBreakMode:UILineBreakModeWordWrap];
	[label setTextAlignment:UITextAlignmentRight];
	[label setTextColor:[UIColor whiteColor]];
	[label setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25]];
	[[label layer] setCornerRadius: 4];
	[label setText:text];
	
	return [label autorelease];
}

- (void)applicationDidBecomeActive:(NSNotification*)notifcation
{
	// For performance reasons, we manually pause/resume the session when saving a recording.
	// If we try to resume the session in the background it will fail. Resume the session here as well to ensure we will succeed.
	[videoProcessor resumeCaptureSession];
}

// UIDeviceOrientationDidChangeNotification selector
- (void)deviceOrientationDidChange
{
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	// Don't update the reference orientation when the device orientation is face up/down or unknown.
	if ( UIDeviceOrientationIsPortrait(orientation) || UIDeviceOrientationIsLandscape(orientation) )
		[videoProcessor setReferenceOrientation:orientation];
}

- (void)viewDidLoad 
{
	[super viewDidLoad];

    // Initialize the class responsible for managing AV capture session and asset writer
    videoProcessor = [[RosyWriterVideoProcessor alloc] init];
	videoProcessor.delegate = self;

	// Keep track of changes to the device orientation so we can update the video processor
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		
    // Setup and start the capture session
    [videoProcessor setupAndStartCaptureSession];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
    
	oglView = [[RosyWriterPreviewView alloc] initWithFrame:CGRectZero];
	// Our interface is always in portrait.
	oglView.transform = [videoProcessor transformFromCurrentVideoOrientationToOrientation:UIInterfaceOrientationPortrait];
    [previewView addSubview:oglView];
 	CGRect bounds = CGRectZero;
 	bounds.size = [self.previewView convertRect:self.previewView.bounds toView:oglView].size;
 	oglView.bounds = bounds;
    oglView.center = CGPointMake(previewView.bounds.size.width/2.0, previewView.bounds.size.height/2.0);
 	
 	// Set up labels
 	shouldShowStats = YES;
	
	frameRateLabel = [self labelWithText:@"" yPosition: (CGFloat) 10.0];
	[previewView addSubview:frameRateLabel];
	
	dimensionsLabel = [self labelWithText:@"" yPosition: (CGFloat) 54.0];
	[previewView addSubview:dimensionsLabel];
	
	typeLabel = [self labelWithText:@"" yPosition: (CGFloat) 98.0];
	[previewView addSubview:typeLabel];
}

- (void)cleanup
{
	[oglView release];
	oglView = nil;
    
    frameRateLabel = nil;
    dimensionsLabel = nil;
    typeLabel = nil;
	
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

	[notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];

    // Stop and tear down the capture session
	[videoProcessor stopAndTearDownCaptureSession];
	videoProcessor.delegate = nil;
    [videoProcessor release];
}

- (void)viewDidUnload 
{
	[super viewDidUnload];

	[self cleanup];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	timer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(updateLabels) userInfo:nil repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{	
	[super viewDidDisappear:animated];

	[timer invalidate];
	timer = nil;
}

- (void)dealloc 
{
	[self cleanup];

	[super dealloc];
}

- (IBAction)toggleRecording:(id)sender 
{
	// Wait for the recording to start/stop before re-enabling the record button.
	[[self recordButton] setEnabled:NO];
	
	if ( [videoProcessor isRecording] ) {
		// The recordingWill/DidStop delegate methods will fire asynchronously in response to this call
		[videoProcessor stopRecording];
	}
	else {
		// The recordingWill/DidStart delegate methods will fire asynchronously in response to this call
        [videoProcessor startRecording];
	}
}

#pragma mark RosyWriterVideoProcessorDelegate

- (void)recordingWillStart
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self recordButton] setEnabled:NO];	
		[[self recordButton] setTitle:@"Stop"];

		// Disable the idle timer while we are recording
		[UIApplication sharedApplication].idleTimerDisabled = YES;

		// Make sure we have time to finish saving the movie if the app is backgrounded during recording
		if ([[UIDevice currentDevice] isMultitaskingSupported])
			backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
	});
}

- (void)recordingDidStart
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self recordButton] setEnabled:YES];
	});
}

- (void)recordingWillStop
{
	dispatch_async(dispatch_get_main_queue(), ^{
		// Disable until saving to the camera roll is complete
		[[self recordButton] setTitle:@"Record"];
		[[self recordButton] setEnabled:NO];
		
		// Pause the capture session so that saving will be as fast as possible.
		// We resume the sesssion in recordingDidStop:
		[videoProcessor pauseCaptureSession];
	});
}

- (void)recordingDidStop
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self recordButton] setEnabled:YES];
		
		[UIApplication sharedApplication].idleTimerDisabled = NO;

		[videoProcessor resumeCaptureSession];

		if ([[UIDevice currentDevice] isMultitaskingSupported]) {
			[[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
			backgroundRecordingID = UIBackgroundTaskInvalid;
		}
	});
}

- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer
{
	// Don't make OpenGLES calls while in the background.
	if ( [UIApplication sharedApplication].applicationState != UIApplicationStateBackground )
		[oglView displayPixelBuffer:pixelBuffer];
}

@end
