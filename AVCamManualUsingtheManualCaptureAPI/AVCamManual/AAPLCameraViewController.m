/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  Control of camera functions.
  
 */

#import "AAPLCameraViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "AAPLPreviewView.h"

static void *CapturingStillImageContext = &CapturingStillImageContext;
static void *RecordingContext = &RecordingContext;
static void *SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

static void *FocusModeContext = &FocusModeContext;
static void *ExposureModeContext = &ExposureModeContext;
static void *WhiteBalanceModeContext = &WhiteBalanceModeContext;
static void *LensPositionContext = &LensPositionContext;
static void *ExposureDurationContext = &ExposureDurationContext;
static void *ISOContext = &ISOContext;
static void *ExposureTargetOffsetContext = &ExposureTargetOffsetContext;
static void *DeviceWhiteBalanceGainsContext = &DeviceWhiteBalanceGainsContext;

@interface AAPLCameraViewController () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, weak) IBOutlet AAPLPreviewView *previewView;
@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, weak) IBOutlet UIButton *cameraButton;
@property (nonatomic, weak) IBOutlet UIButton *stillButton;

@property (nonatomic, strong) NSArray *focusModes;
@property (nonatomic, weak) IBOutlet UIView *manualHUDFocusView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *focusModeControl;
@property (nonatomic, weak) IBOutlet UISlider *lensPositionSlider;
@property (nonatomic, weak) IBOutlet UILabel *lensPositionNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *lensPositionValueLabel;

@property (nonatomic, strong) NSArray *exposureModes;
@property (nonatomic, weak) IBOutlet UIView *manualHUDExposureView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *exposureModeControl;
@property (nonatomic, weak) IBOutlet UISlider *exposureDurationSlider;
@property (nonatomic, weak) IBOutlet UILabel *exposureDurationNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *exposureDurationValueLabel;
@property (nonatomic, weak) IBOutlet UISlider *ISOSlider;
@property (nonatomic, weak) IBOutlet UILabel *ISONameLabel;
@property (nonatomic, weak) IBOutlet UILabel *ISOValueLabel;
@property (nonatomic, weak) IBOutlet UISlider *exposureTargetBiasSlider;
@property (nonatomic, weak) IBOutlet UILabel *exposureTargetBiasNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *exposureTargetBiasValueLabel;
@property (nonatomic, weak) IBOutlet UISlider *exposureTargetOffsetSlider;
@property (nonatomic, weak) IBOutlet UILabel *exposureTargetOffsetNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *exposureTargetOffsetValueLabel;

@property (nonatomic, strong) NSArray *whiteBalanceModes;
@property (nonatomic, weak) IBOutlet UIView *manualHUDWhiteBalanceView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *whiteBalanceModeControl;
@property (nonatomic, weak) IBOutlet UISlider *temperatureSlider;
@property (nonatomic, weak) IBOutlet UILabel *temperatureNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *temperatureValueLabel;
@property (nonatomic, weak) IBOutlet UISlider *tintSlider;
@property (nonatomic, weak) IBOutlet UILabel *tintNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *tintValueLabel;

@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureDevice *videoDevice;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;

@end

@implementation AAPLCameraViewController

static UIColor* CONTROL_NORMAL_COLOR = nil;
static UIColor* CONTROL_HIGHLIGHT_COLOR = nil;
static float EXPOSURE_DURATION_POWER = 5; // Higher numbers will give the slider more sensitivity at shorter durations
static float EXPOSURE_MINIMUM_DURATION = 1.0/1000; // Limit exposure duration to a useful range

+ (void)initialize
{
	CONTROL_NORMAL_COLOR = [UIColor yellowColor];
	CONTROL_HIGHLIGHT_COLOR = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]; // A nice blue
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized
{
	return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}

- (BOOL)isSessionRunningAndDeviceAuthorized
{
	return [[self session] isRunning] && [self isDeviceAuthorized];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	self.recordButton.layer.cornerRadius = self.stillButton.layer.cornerRadius = self.cameraButton.layer.cornerRadius = 4;
	self.recordButton.clipsToBounds = self.stillButton.clipsToBounds = self.cameraButton.clipsToBounds = YES;
	
	// Create the AVCaptureSession
	AVCaptureSession *session = [[AVCaptureSession alloc] init];
	[self setSession:session];
	
	// Set up preview
	[[self previewView] setSession:session];
	
	// Check for device authorization
	[self checkDeviceAuthorizationStatus];
	
	// In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
	// Why not do all of this on the main queue?
	// -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
	
	dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	[self setSessionQueue:sessionQueue];
	
	dispatch_async(sessionQueue, ^{
		[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
		
		NSError *error = nil;
		
		AVCaptureDevice *videoDevice = [AAPLCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		
		if (error)
		{
			NSLog(@"%@", error);
		}
		
		[[self session] beginConfiguration];
		
		if ([session canAddInput:videoDeviceInput])
		{
			[session addInput:videoDeviceInput];
			[self setVideoDeviceInput:videoDeviceInput];
			[self setVideoDevice:videoDeviceInput.device];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				// Why are we dispatching this to the main queue?
				// Because AVCaptureVideoPreviewLayer is the backing layer for our preview view and UIView can only be manipulated on main thread.
				// Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
  
				[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
			});
		}
		
		AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
		AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
		
		if (error)
		{
			NSLog(@"%@", error);
		}
		
		if ([session canAddInput:audioDeviceInput])
		{
			[session addInput:audioDeviceInput];
		}
		
		AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
		if ([session canAddOutput:movieFileOutput])
		{
			[session addOutput:movieFileOutput];
			AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
			if ([connection isVideoStabilizationSupported])
			{
				[connection setEnablesVideoStabilizationWhenAvailable:YES];
			}
			[self setMovieFileOutput:movieFileOutput];
		}
		
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([session canAddOutput:stillImageOutput])
		{
			[stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
			[session addOutput:stillImageOutput];
			[self setStillImageOutput:stillImageOutput];
		}
		
		[[self session] commitConfiguration];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self configureManualHUD];
		});
	});
	
	self.manualHUDFocusView.hidden = YES;
	self.manualHUDExposureView.hidden = YES;
	self.manualHUDWhiteBalanceView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	dispatch_async([self sessionQueue], ^{
		[self addObservers];
		
		[[self session] startRunning];
	});
}

- (void)viewDidDisappear:(BOOL)animated
{
	dispatch_async([self sessionQueue], ^{
		[[self session] stopRunning];
		
		[self removeObservers];
	});
	
	[super viewDidDisappear:animated];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (BOOL)shouldAutorotate
{
	// Disable autorotation of the interface when recording is in progress.
	return ![self lockInterfaceRotation];
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self positionManualHUD];
}

#pragma mark Actions

- (IBAction)toggleMovieRecording:(id)sender
{
	[[self recordButton] setEnabled:NO];
	
	dispatch_async([self sessionQueue], ^{
		if (![[self movieFileOutput] isRecording])
		{
			[self setLockInterfaceRotation:YES];
			
			if ([[UIDevice currentDevice] isMultitaskingSupported])
			{
				// Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until the app returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when the app is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
				[self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
			}
			
			// Update the orientation on the movie file output video connection before starting recording.
			[[[self movieFileOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] videoOrientation]];
			
			// Turn OFF flash for video recording
			[AAPLCameraViewController setFlashMode:AVCaptureFlashModeOff forDevice:[self videoDevice]];
			
			// Start recording to a temporary file.
			NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[@"movie" stringByAppendingPathExtension:@"mov"]];
			[[self movieFileOutput] startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
		}
		else
		{
			[[self movieFileOutput] stopRecording];
		}
	});
}

- (IBAction)changeCamera:(id)sender
{
	[[self cameraButton] setEnabled:NO];
	[[self recordButton] setEnabled:NO];
	[[self stillButton] setEnabled:NO];
	
	dispatch_async([self sessionQueue], ^{
		AVCaptureDevice *currentVideoDevice = [self videoDevice];
		AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
		AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
		
		switch (currentPosition)
		{
			case AVCaptureDevicePositionUnspecified:
				preferredPosition = AVCaptureDevicePositionBack;
				break;
			case AVCaptureDevicePositionBack:
				preferredPosition = AVCaptureDevicePositionFront;
				break;
			case AVCaptureDevicePositionFront:
				preferredPosition = AVCaptureDevicePositionBack;
				break;
		}
		
		AVCaptureDevice *newVideoDevice = [AAPLCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
		AVCaptureDeviceInput *newVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:nil];
		
		[[self session] beginConfiguration];
		
		[[self session] removeInput:[self videoDeviceInput]];
		if ([[self session] canAddInput:newVideoDeviceInput])
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
			
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:newVideoDevice];
			
			[[self session] addInput:newVideoDeviceInput];
			[self setVideoDeviceInput:newVideoDeviceInput];
			[self setVideoDevice:newVideoDeviceInput.device];
		}
		else
		{
			[[self session] addInput:[self videoDeviceInput]];
		}
		
		[[self session] commitConfiguration];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[[self cameraButton] setEnabled:YES];
			[[self recordButton] setEnabled:YES];
			[[self stillButton] setEnabled:YES];
			
			[self configureManualHUD];
		});
	});
}

- (IBAction)snapStillImage:(id)sender
{
	dispatch_async([self sessionQueue], ^{
		// Update the orientation on the still image output video connection before capturing.
		[[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] videoOrientation]];
		
		// Flash set to Auto for Still Capture
		if (self.videoDevice.exposureMode == AVCaptureExposureModeCustom)
		{
			[AAPLCameraViewController setFlashMode:AVCaptureFlashModeOff forDevice:[self videoDevice]];
		}
		else
		{
			[AAPLCameraViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[self videoDevice]];
		}
		
		// Capture a still image
		[[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
			
			if (imageDataSampleBuffer)
			{
				NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
				UIImage *image = [[UIImage alloc] initWithData:imageData];
				[[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];
			}
		}];
	});
}

- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
	if (self.videoDevice.focusMode != AVCaptureFocusModeLocked && self.videoDevice.exposureMode != AVCaptureExposureModeCustom)
	{
		CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)[[self previewView] layer] captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
		[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
	}
}

- (IBAction)changeManualHUD:(id)sender
{
	UISegmentedControl *control = sender;
	
	[self positionManualHUD];
	
	self.manualHUDFocusView.hidden = (control.selectedSegmentIndex == 1) ? NO : YES;
	self.manualHUDExposureView.hidden = (control.selectedSegmentIndex == 2) ? NO : YES;
	self.manualHUDWhiteBalanceView.hidden = (control.selectedSegmentIndex == 3) ? NO : YES;
}

- (IBAction)changeFocusMode:(id)sender
{
	UISegmentedControl *control = sender;
	AVCaptureFocusMode mode = (AVCaptureFocusMode)[self.focusModes[control.selectedSegmentIndex] intValue];
	NSError *error = nil;
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		if ([self.videoDevice isFocusModeSupported:mode])
		{
			self.videoDevice.focusMode = mode;
		}
		else
		{
			NSLog(@"Focus mode %@ is not supported. Focus mode is %@.", [self stringFromFocusMode:mode], [self stringFromFocusMode:self.videoDevice.focusMode]);
			self.focusModeControl.selectedSegmentIndex = [self.focusModes indexOfObject:@(self.videoDevice.focusMode)];
		}
		[self.videoDevice unlockForConfiguration];
	}
	else
	{
		NSLog(@"%@", error);
	}
}
- (IBAction)changeExposureMode:(id)sender
{
	UISegmentedControl *control = sender;
	NSError *error = nil;
	AVCaptureExposureMode mode = (AVCaptureExposureMode)[self.exposureModes[control.selectedSegmentIndex] intValue];
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		if ([self.videoDevice isExposureModeSupported:mode])
		{
			self.videoDevice.exposureMode = mode;
		}
		else
		{
			NSLog(@"Exposure mode %@ is not supported. Exposure mode is %@.", [self stringFromExposureMode:mode], [self stringFromExposureMode:self.videoDevice.exposureMode]);
		}
		[self.videoDevice unlockForConfiguration];
	}
	else
	{
		NSLog(@"%@", error);
	}
}

- (IBAction)changeWhiteBalanceMode:(id)sender
{
	UISegmentedControl *control = sender;
	AVCaptureWhiteBalanceMode mode = (AVCaptureWhiteBalanceMode)[self.whiteBalanceModes[control.selectedSegmentIndex] intValue];
	NSError *error = nil;
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		if ([self.videoDevice isWhiteBalanceModeSupported:mode])
		{
			self.videoDevice.whiteBalanceMode = mode;
		}
		else
		{
			NSLog(@"White balance mode %@ is not supported. White balance mode is %@.", [self stringFromWhiteBalanceMode:mode], [self stringFromWhiteBalanceMode:self.videoDevice.whiteBalanceMode]);
		}
		[self.videoDevice unlockForConfiguration];
	}
	else
	{
		NSLog(@"%@", error);
	}
}

- (IBAction)changeLensPosition:(id)sender
{
	UISlider *control = sender;
	NSError *error = nil;
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		[self.videoDevice setFocusModeLockedWithLensPosition:control.value completionHandler:nil];
	    [self.videoDevice unlockForConfiguration];
	}
	else
	{
		NSLog(@"%@", error);
	}
}

- (IBAction)changeExposureDuration:(id)sender
{
	UISlider *control = sender;
	NSError *error = nil;
	
	double p = pow( control.value, EXPOSURE_DURATION_POWER ); // Apply power function to expand slider's low-end range
	double minDurationSeconds = MAX(CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION);
	double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
	double newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
	
	if (self.videoDevice.exposureMode == AVCaptureExposureModeCustom)
	{
		if ( newDurationSeconds < 1 )
		{
			int digits = MAX( 0, 2 + floor( log10( newDurationSeconds ) ) );
			self.exposureDurationValueLabel.text = [NSString stringWithFormat:@"1/%.*f", digits, 1/newDurationSeconds];
		}
		else
		{
			self.exposureDurationValueLabel.text = [NSString stringWithFormat:@"%.2f", newDurationSeconds];
		}
	}

	if ([self.videoDevice lockForConfiguration:&error])
	{
		[self.videoDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds(newDurationSeconds, 1000*1000*1000)  ISO:AVCaptureISOCurrent completionHandler:nil];
        [self.videoDevice unlockForConfiguration];
	}
	else
	{
		NSLog(@"%@", error);
	}
}

- (IBAction)changeISO:(id)sender
{
	UISlider *control = sender;
	NSError *error = nil;
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		[self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:control.value completionHandler:nil];
        [self.videoDevice unlockForConfiguration];
	}
	else
	{
		NSLog(@"%@", error);
	}
}

- (IBAction)changeExposureTargetBias:(id)sender
{
	UISlider *control = sender;
	NSError *error = nil;
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		[self.videoDevice setExposureTargetBias:control.value completionHandler:nil];
        [self.videoDevice unlockForConfiguration];
		self.exposureTargetBiasValueLabel.text = [NSString stringWithFormat:@"%.1f", control.value];
	}
	else
	{
		NSLog(@"%@", error);
	}
}

- (IBAction)changeTemperature:(id)sender
{
	AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTint = {
		.temperature = self.temperatureSlider.value,
		.tint = self.tintSlider.value,
	};
	
	[self setWhiteBalanceGains:[self.videoDevice deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTint]];
}

- (IBAction)changeTint:(id)sender
{
	AVCaptureWhiteBalanceTemperatureAndTintValues temperatureAndTint = {
		.temperature = self.temperatureSlider.value,
		.tint = self.tintSlider.value,
	};
	
	[self setWhiteBalanceGains:[self.videoDevice deviceWhiteBalanceGainsForTemperatureAndTintValues:temperatureAndTint]];
}

- (IBAction)lockWithGrayWorld:(id)sender
{
	[self setWhiteBalanceGains:self.videoDevice.grayWorldDeviceWhiteBalanceGains];
}

- (IBAction)sliderTouchBegan:(id)sender
{
	UISlider *slider = (UISlider*)sender;
	[self setSlider:slider highlightColor:CONTROL_HIGHLIGHT_COLOR];
}

- (IBAction)sliderTouchEnded:(id)sender
{
	UISlider *slider = (UISlider*)sender;
	[self setSlider:slider highlightColor:CONTROL_NORMAL_COLOR];
}

#pragma mark UI

- (void)runStillImageCaptureAnimation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[[self previewView] layer] setOpacity:0.0];
		[UIView animateWithDuration:.25 animations:^{
			[[[self previewView] layer] setOpacity:1.0];
		}];
	});
}

- (void)configureManualHUD
{
	// Manual focus controls
	self.focusModes = @[@(AVCaptureFocusModeContinuousAutoFocus), @(AVCaptureFocusModeLocked)];
	
	self.focusModeControl.selectedSegmentIndex = [self.focusModes indexOfObject:@(self.videoDevice.focusMode)];
	for (NSNumber *mode in self.focusModes) {
		[self.focusModeControl setEnabled:([self.videoDevice isFocusModeSupported:[mode intValue]]) forSegmentAtIndex:[self.focusModes indexOfObject:mode]];
	}
	
	self.lensPositionSlider.minimumValue = 0.0;
	self.lensPositionSlider.maximumValue = 1.0;
	self.lensPositionSlider.enabled = (self.videoDevice.focusMode == AVCaptureFocusModeLocked);
	
	// Manual exposure controls
	self.exposureModes = @[@(AVCaptureExposureModeContinuousAutoExposure), @(AVCaptureExposureModeLocked), @(AVCaptureExposureModeCustom)];
	
	self.exposureModeControl.selectedSegmentIndex = [self.exposureModes indexOfObject:@(self.videoDevice.exposureMode)];
	for (NSNumber *mode in self.exposureModes) {
		[self.exposureModeControl setEnabled:([self.videoDevice isExposureModeSupported:[mode intValue]]) forSegmentAtIndex:[self.exposureModes indexOfObject:mode]];
	}
	
	// Use 0-1 as the slider range and do a non-linear mapping from the slider value to the actual device exposure duration
	self.exposureDurationSlider.minimumValue = 0;
	self.exposureDurationSlider.maximumValue = 1;
	self.exposureDurationSlider.enabled = (self.videoDevice.exposureMode == AVCaptureExposureModeCustom);
	
	self.ISOSlider.minimumValue = self.videoDevice.activeFormat.minISO;
	self.ISOSlider.maximumValue = self.videoDevice.activeFormat.maxISO;
	self.ISOSlider.enabled = (self.videoDevice.exposureMode == AVCaptureExposureModeCustom);
	
	self.exposureTargetBiasSlider.minimumValue = self.videoDevice.minExposureTargetBias;
	self.exposureTargetBiasSlider.maximumValue = self.videoDevice.maxExposureTargetBias;
	self.exposureTargetBiasSlider.enabled = YES;
	
	self.exposureTargetOffsetSlider.minimumValue = self.videoDevice.minExposureTargetBias;
	self.exposureTargetOffsetSlider.maximumValue = self.videoDevice.maxExposureTargetBias;
	self.exposureTargetOffsetSlider.enabled = NO;
	
	// Manual white balance controls
	self.whiteBalanceModes = @[@(AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance), @(AVCaptureWhiteBalanceModeLocked)];
	
	self.whiteBalanceModeControl.selectedSegmentIndex = [self.whiteBalanceModes indexOfObject:@(self.videoDevice.whiteBalanceMode)];
	for (NSNumber *mode in self.whiteBalanceModes) {
		[self.whiteBalanceModeControl setEnabled:([self.videoDevice isWhiteBalanceModeSupported:[mode intValue]]) forSegmentAtIndex:[self.whiteBalanceModes indexOfObject:mode]];
	}
	
	self.temperatureSlider.minimumValue = 3000;
	self.temperatureSlider.maximumValue = 8000;
	self.temperatureSlider.enabled = (self.videoDevice.whiteBalanceMode == AVCaptureWhiteBalanceModeLocked);
	
	self.tintSlider.minimumValue = -150;
	self.tintSlider.maximumValue = 150;
	self.tintSlider.enabled = (self.videoDevice.whiteBalanceMode == AVCaptureWhiteBalanceModeLocked);
}

- (void)positionManualHUD
{
	// Since we only show one manual view at a time, put them all in the same place (at the top)
	self.manualHUDExposureView.frame = CGRectMake(self.manualHUDFocusView.frame.origin.x, self.manualHUDFocusView.frame.origin.y, self.manualHUDExposureView.frame.size.width, self.manualHUDExposureView.frame.size.height);
	self.manualHUDWhiteBalanceView.frame = CGRectMake(self.manualHUDFocusView.frame.origin.x, self.manualHUDFocusView.frame.origin.y, self.manualHUDWhiteBalanceView.frame.size.width, self.manualHUDWhiteBalanceView.frame.size.height);
}

- (void)setSlider:(UISlider*)slider highlightColor:(UIColor*)color
{
	slider.tintColor = color;
	
	if (slider == self.lensPositionSlider)
	{
		self.lensPositionNameLabel.textColor = self.lensPositionValueLabel.textColor = slider.tintColor;
	}
	else if (slider == self.exposureDurationSlider)
	{
		self.exposureDurationNameLabel.textColor = self.exposureDurationValueLabel.textColor = slider.tintColor;
	}
	else if (slider == self.ISOSlider)
	{
		self.ISONameLabel.textColor = self.ISOValueLabel.textColor = slider.tintColor;
	}
	else if (slider == self.exposureTargetBiasSlider)
	{
		self.exposureTargetBiasNameLabel.textColor = self.exposureTargetBiasValueLabel.textColor = slider.tintColor;
	}
	else if (slider == self.temperatureSlider)
	{
		self.temperatureNameLabel.textColor = self.temperatureValueLabel.textColor = slider.tintColor;
	}
	else if (slider == self.tintSlider)
	{
		self.tintNameLabel.textColor = self.tintValueLabel.textColor = slider.tintColor;
	}
}

#pragma mark File Output Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
	if (error)
	{
		NSLog(@"%@", error);
	}
	
	[self setLockInterfaceRotation:NO];
	
	// Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
	UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
	[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
	
	[[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
		if (error)
		{
			NSLog(@"%@", error);
		}
		
		[[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
		
		if (backgroundRecordingID != UIBackgroundTaskInvalid)
		{
			[[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
		}
	}];
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
	dispatch_async([self sessionQueue], ^{
		AVCaptureDevice *device = [self videoDevice];
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
			{
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
			{
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	});
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
	if ([device hasFlash] && [device isFlashModeSupported:flashMode])
	{
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		}
		else
		{
			NSLog(@"%@", error);
		}
	}
}

- (void)setWhiteBalanceGains:(AVCaptureWhiteBalanceGains)gains
{
	NSError *error = nil;
	
	if ([self.videoDevice lockForConfiguration:&error])
	{
		AVCaptureWhiteBalanceGains normalizedGains = [self normalizedGains:gains]; // Conversion can yield out-of-bound values, cap to limits
		[self.videoDevice setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:normalizedGains completionHandler:nil];
        [self.videoDevice unlockForConfiguration];
	}
	else
	{
		NSLog(@"%@", error);
	}
}

#pragma mark KVO

- (void)addObservers
{
	[self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
	[self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
	[self addObserver:self forKeyPath:@"movieFileOutput.recording" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:RecordingContext];
	
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.focusMode" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:FocusModeContext];
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.lensPosition" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:LensPositionContext];
	
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.exposureMode" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ExposureModeContext];
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.exposureDuration" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ExposureDurationContext];
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.ISO" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ISOContext];
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.exposureTargetOffset" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ExposureTargetOffsetContext];
	
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.whiteBalanceMode" options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:WhiteBalanceModeContext];
	[self addObserver:self forKeyPath:@"videoDeviceInput.device.deviceWhiteBalanceGains" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:DeviceWhiteBalanceGainsContext];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[self videoDevice]];
	
	__weak AAPLCameraViewController *weakSelf = self;
	[self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self session] queue:nil usingBlock:^(NSNotification *note) {
		AAPLCameraViewController *strongSelf = weakSelf;
		dispatch_async([strongSelf sessionQueue], ^{
			// Manually restart the session since it must have been stopped due to an error
			[[strongSelf session] startRunning];
			[[strongSelf recordButton] setTitle:NSLocalizedString(@"Record", @"Recording button record title") forState:UIControlStateNormal];
		});
	}]];
}

- (void)removeObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[self videoDevice]];
	[[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
	
	[self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
	[self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
	[self removeObserver:self forKeyPath:@"movieFileOutput.recording" context:RecordingContext];
	
	[self removeObserver:self forKeyPath:@"videoDevice.focusMode" context:FocusModeContext];
	[self removeObserver:self forKeyPath:@"videoDevice.lensPosition" context:LensPositionContext];
	
	[self removeObserver:self forKeyPath:@"videoDevice.exposureMode" context:ExposureModeContext];
	[self removeObserver:self forKeyPath:@"videoDevice.exposureDuration" context:ExposureDurationContext];
	[self removeObserver:self forKeyPath:@"videoDevice.ISO" context:ISOContext];
	[self removeObserver:self forKeyPath:@"videoDevice.exposureTargetOffset" context:ExposureTargetOffsetContext];
	
	[self removeObserver:self forKeyPath:@"videoDevice.whiteBalanceMode" context:WhiteBalanceModeContext];
	[self removeObserver:self forKeyPath:@"videoDevice.deviceWhiteBalanceGains" context:DeviceWhiteBalanceGainsContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == FocusModeContext)
	{
		AVCaptureFocusMode oldMode = [change[NSKeyValueChangeOldKey] intValue];
		AVCaptureFocusMode newMode = [change[NSKeyValueChangeNewKey] intValue];
		NSLog(@"focus mode: %@ -> %@", [self stringFromFocusMode:oldMode], [self stringFromFocusMode:newMode]);
		
		self.focusModeControl.selectedSegmentIndex = [self.focusModes indexOfObject:@(newMode)];
		self.lensPositionSlider.enabled = (newMode == AVCaptureFocusModeLocked);
	}
	else if (context == LensPositionContext)
	{
		float newLensPosition = [change[NSKeyValueChangeNewKey] floatValue];
		
		if (self.videoDevice.focusMode != AVCaptureFocusModeLocked)
		{
			self.lensPositionSlider.value = newLensPosition;
		}
		self.lensPositionValueLabel.text = [NSString stringWithFormat:@"%.1f", newLensPosition];
	}
	else if (context == ExposureModeContext)
	{
		AVCaptureExposureMode oldMode = [change[NSKeyValueChangeOldKey] intValue];
		AVCaptureExposureMode newMode = [change[NSKeyValueChangeNewKey] intValue];
		NSLog(@"exposure mode: %@ -> %@", [self stringFromExposureMode:oldMode], [self stringFromExposureMode:newMode]);
		
		self.exposureModeControl.selectedSegmentIndex = [self.exposureModes indexOfObject:@(newMode)];
		self.exposureDurationSlider.enabled = (newMode == AVCaptureExposureModeCustom);
		self.ISOSlider.enabled = (newMode == AVCaptureExposureModeCustom);
		
		/*
		 It’s important to understand the relationship between exposureDuration and the minimum frame rate as represented by activeVideoMaxFrameDuration.
		 In manual mode, if exposureDuration is set to a value that's greater than activeVideoMaxFrameDuration, then activeVideoMaxFrameDuration will
		 increase to match it, thus lowering the minimum frame rate. If exposureMode is then changed to automatic mode, the minimum frame rate will
		 remain lower than its default. If this is not the desired behavior, the min and max frameRates can be reset to their default values for the
		 current activeFormat by setting activeVideoMaxFrameDuration and activeVideoMinFrameDuration to kCMTimeInvalid.
		 */
		if (oldMode == AVCaptureExposureModeCustom)
		{
			NSError *error = nil;
			if ([self.videoDevice lockForConfiguration:&error])
			{
				[self.videoDevice setActiveVideoMaxFrameDuration:kCMTimeInvalid];
				[self.videoDevice setActiveVideoMinFrameDuration:kCMTimeInvalid];
				[self.videoDevice unlockForConfiguration];
			}
		}
	}
	else if (context == ExposureDurationContext)
	{
		double newDurationSeconds = CMTimeGetSeconds([change[NSKeyValueChangeNewKey] CMTimeValue]);
		if (self.videoDevice.exposureMode != AVCaptureExposureModeCustom)
		{
			double minDurationSeconds = MAX(CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION);
			double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
			// Map from duration to non-linear UI range 0-1
			double p = ( newDurationSeconds - minDurationSeconds ) / ( maxDurationSeconds - minDurationSeconds ); // Scale to 0-1
			self.exposureDurationSlider.value = pow( p, 1 / EXPOSURE_DURATION_POWER ); // Apply inverse power
			
			if ( newDurationSeconds < 1 )
			{
				int digits = MAX( 0, 2 + floor( log10( newDurationSeconds ) ) );
				self.exposureDurationValueLabel.text = [NSString stringWithFormat:@"1/%.*f", digits, 1/newDurationSeconds];
			}
			else
			{
				self.exposureDurationValueLabel.text = [NSString stringWithFormat:@"%.2f", newDurationSeconds];
			}
		}
	}
	else if (context == ISOContext)
	{
		float newISO = [change[NSKeyValueChangeNewKey] floatValue];
		
		if (self.videoDevice.exposureMode != AVCaptureExposureModeCustom)
		{
			self.ISOSlider.value = newISO;
		}
		self.ISOValueLabel.text = [NSString stringWithFormat:@"%i", (int)newISO];
	}
	else if (context == ExposureTargetOffsetContext)
	{
		float newExposureTargetOffset = [change[NSKeyValueChangeNewKey] floatValue];
		
		self.exposureTargetOffsetSlider.value = newExposureTargetOffset;
		self.exposureTargetOffsetValueLabel.text = [NSString stringWithFormat:@"%.1f", newExposureTargetOffset];
	}
	else if (context == WhiteBalanceModeContext)
	{
		AVCaptureWhiteBalanceMode oldMode = [change[NSKeyValueChangeOldKey] intValue];
		AVCaptureWhiteBalanceMode newMode = [change[NSKeyValueChangeNewKey] intValue];
		NSLog(@"white balance mode: %@ -> %@", [self stringFromWhiteBalanceMode:oldMode], [self stringFromWhiteBalanceMode:newMode]);
		
		self.whiteBalanceModeControl.selectedSegmentIndex = [self.whiteBalanceModes indexOfObject:@(newMode)];
		self.temperatureSlider.enabled = (newMode == AVCaptureWhiteBalanceModeLocked);
		self.tintSlider.enabled = (newMode == AVCaptureWhiteBalanceModeLocked);
	}
	else if (context == DeviceWhiteBalanceGainsContext)
	{
		AVCaptureWhiteBalanceGains newGains;
		[change[NSKeyValueChangeNewKey] getValue:&newGains];
		AVCaptureWhiteBalanceTemperatureAndTintValues newTemperatureAndTint = [self.videoDevice temperatureAndTintValuesForDeviceWhiteBalanceGains:newGains];
		
		if (self.videoDevice.whiteBalanceMode != AVCaptureExposureModeLocked)
		{
			self.temperatureSlider.value = newTemperatureAndTint.temperature;
			self.tintSlider.value = newTemperatureAndTint.tint;
		}
		self.temperatureValueLabel.text = [NSString stringWithFormat:@"%i", (int)newTemperatureAndTint.temperature];
		self.tintValueLabel.text = [NSString stringWithFormat:@"%i", (int)newTemperatureAndTint.tint];
	}
	else if (context == CapturingStillImageContext)
	{
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		
		if (isCapturingStillImage)
		{
			[self runStillImageCaptureAnimation];
		}
	}
	else if (context == RecordingContext)
	{
		BOOL isRecording = [change[NSKeyValueChangeNewKey] boolValue];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (isRecording)
			{
				[[self cameraButton] setEnabled:NO];
				[[self recordButton] setTitle:NSLocalizedString(@"Stop", @"Recording button stop title") forState:UIControlStateNormal];
				[[self recordButton] setEnabled:YES];
			}
			else
			{
				[[self cameraButton] setEnabled:YES];
				[[self recordButton] setTitle:NSLocalizedString(@"Record", @"Recording button record title") forState:UIControlStateNormal];
				[[self recordButton] setEnabled:YES];
			}
		});
	}
	else if (context == SessionRunningAndDeviceAuthorizedContext)
	{
		BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (isRunning)
			{
				[[self cameraButton] setEnabled:YES];
				[[self recordButton] setEnabled:YES];
				[[self stillButton] setEnabled:YES];
			}
			else
			{
				[[self cameraButton] setEnabled:NO];
				[[self recordButton] setEnabled:NO];
				[[self stillButton] setEnabled:NO];
			}
		});
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
	CGPoint devicePoint = CGPointMake(.5, .5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

#pragma mark Utilities

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == position)
		{
			captureDevice = device;
			break;
		}
	}
	
	return captureDevice;
}

- (void)checkDeviceAuthorizationStatus
{
	NSString *mediaType = AVMediaTypeVideo;
	
	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
		if (granted)
		{
			[self setDeviceAuthorized:YES];
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:@"AVCamManual"
											message:@"AVCamManual doesn't have permission to use the Camera"
										   delegate:self
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
				[self setDeviceAuthorized:NO];
			});
		}
	}];
}

- (NSString *)stringFromFocusMode:(AVCaptureFocusMode) focusMode
{
	NSString *string = @"INVALID FOCUS MODE";
	
	if (focusMode == AVCaptureFocusModeLocked)
	{
		string = @"Locked";
	}
	else if (focusMode == AVCaptureFocusModeAutoFocus)
	{
		string = @"Auto";
	}
	else if (focusMode == AVCaptureFocusModeContinuousAutoFocus)
	{
		string = @"ContinuousAuto";
	}
	
	return string;
}

- (NSString *)stringFromExposureMode:(AVCaptureExposureMode) exposureMode
{
	NSString *string = @"INVALID EXPOSURE MODE";
	
	if (exposureMode == AVCaptureExposureModeLocked)
	{
		string = @"Locked";
	}
	else if (exposureMode == AVCaptureExposureModeAutoExpose)
	{
		string = @"Auto";
	}
	else if (exposureMode == AVCaptureExposureModeContinuousAutoExposure)
	{
		string = @"ContinuousAuto";
	}
	else if (exposureMode == AVCaptureExposureModeCustom)
	{
		string = @"Custom";
	}
	
	return string;
}

- (NSString *)stringFromWhiteBalanceMode:(AVCaptureWhiteBalanceMode) whiteBalanceMode
{
	NSString *string = @"INVALID WHITE BALANCE MODE";
	
	if (whiteBalanceMode == AVCaptureWhiteBalanceModeLocked)
	{
		string = @"Locked";
	}
	else if (whiteBalanceMode == AVCaptureWhiteBalanceModeAutoWhiteBalance)
	{
		string = @"Auto";
	}
	else if (whiteBalanceMode == AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance)
	{
		string = @"ContinuousAuto";
	}
	
	return string;
}

- (AVCaptureWhiteBalanceGains)normalizedGains:(AVCaptureWhiteBalanceGains) gains
{
	AVCaptureWhiteBalanceGains g = gains;
	
	g.redGain = MAX(1.0, g.redGain);
	g.greenGain = MAX(1.0, g.greenGain);
	g.blueGain = MAX(1.0, g.blueGain);
	
	g.redGain = MIN(self.videoDevice.maxWhiteBalanceGain, g.redGain);
	g.greenGain = MIN(self.videoDevice.maxWhiteBalanceGain, g.greenGain);
	g.blueGain = MIN(self.videoDevice.maxWhiteBalanceGain, g.blueGain);
	
	return g;
}

@end
