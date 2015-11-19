/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
View controller for camera interface.
*/

@import AVFoundation;
@import Photos;

#import "AAPLCameraViewController.h"
#import "AAPLPreviewView.h"

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningContext = &SessionRunningContext;

static void * FocusModeContext = &FocusModeContext;
static void * ExposureModeContext = &ExposureModeContext;
static void * WhiteBalanceModeContext = &WhiteBalanceModeContext;
static void * LensPositionContext = &LensPositionContext;
static void * ExposureDurationContext = &ExposureDurationContext;
static void * ISOContext = &ISOContext;
static void * ExposureTargetOffsetContext = &ExposureTargetOffsetContext;
static void * DeviceWhiteBalanceGainsContext = &DeviceWhiteBalanceGainsContext;
static void * LensStabilizationContext = &LensStabilizationContext;

typedef NS_ENUM( NSInteger, AVCamManualSetupResult ) {
	AVCamManualSetupResultSuccess,
	AVCamManualSetupResultCameraNotAuthorized,
	AVCamManualSetupResultSessionConfigurationFailed
};

@interface AAPLCameraViewController () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, weak) IBOutlet AAPLPreviewView *previewView;
@property (nonatomic, weak) IBOutlet UILabel *cameraUnavailableLabel;
@property (nonatomic, weak) IBOutlet UIButton *resumeButton;
@property (nonatomic, weak) IBOutlet UIButton *recordButton;
@property (nonatomic, weak) IBOutlet UIButton *cameraButton;
@property (nonatomic, weak) IBOutlet UIButton *stillButton;

@property (nonatomic) NSArray *focusModes;
@property (nonatomic, weak) IBOutlet UIView *manualHUDFocusView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *focusModeControl;
@property (nonatomic, weak) IBOutlet UISlider *lensPositionSlider;
@property (nonatomic, weak) IBOutlet UILabel *lensPositionNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *lensPositionValueLabel;

@property (nonatomic) NSArray *exposureModes;
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

@property (nonatomic) NSArray *whiteBalanceModes;
@property (nonatomic, weak) IBOutlet UIView *manualHUDWhiteBalanceView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *whiteBalanceModeControl;
@property (nonatomic, weak) IBOutlet UISlider *temperatureSlider;
@property (nonatomic, weak) IBOutlet UILabel *temperatureNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *temperatureValueLabel;
@property (nonatomic, weak) IBOutlet UISlider *tintSlider;
@property (nonatomic, weak) IBOutlet UILabel *tintNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *tintValueLabel;

@property (nonatomic, weak) IBOutlet UIView *manualHUDLensStabilizationView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *lensStabilizationControl;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureDevice *videoDevice;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

// Utilities.
@property (nonatomic) AVCamManualSetupResult setupResult;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;

@end

@implementation AAPLCameraViewController

static const float kExposureDurationPower = 5; // Higher numbers will give the slider more sensitivity at shorter durations
static const float kExposureMinimumDuration = 1.0/1000; // Limit exposure duration to a useful range

- (void)viewDidLoad
{
	[super viewDidLoad];

	// Disable UI. The UI is enabled if and only if the session starts running.
	self.cameraButton.enabled = NO;
	self.recordButton.enabled = NO;
	self.stillButton.enabled = NO;

	self.manualHUDFocusView.hidden = YES;
	self.manualHUDExposureView.hidden = YES;
	self.manualHUDWhiteBalanceView.hidden = YES;
	self.manualHUDLensStabilizationView.hidden = YES;

	// Create the AVCaptureSession.
	self.session = [[AVCaptureSession alloc] init];

	// Setup the preview view.
	self.previewView.session = self.session;

	// Communicate with the session and other session objects on this queue.
	self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );

	self.setupResult = AVCamManualSetupResultSuccess;

	// Check video authorization status. Video access is required and audio access is optional.
	// If audio access is denied, audio is not recorded during movie recording.
	switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
	{
		case AVAuthorizationStatusAuthorized:
		{
			// The user has previously granted access to the camera.
			break;
		}
		case AVAuthorizationStatusNotDetermined:
		{
			// The user has not yet been presented with the option to grant video access.
			// We suspend the session queue to delay session setup until the access request has completed to avoid
			// asking the user for audio access if video access is denied.
			// Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
			dispatch_suspend( self.sessionQueue );
			[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
				if ( ! granted ) {
					self.setupResult = AVCamManualSetupResultCameraNotAuthorized;
				}
				dispatch_resume( self.sessionQueue );
			}];
			break;
		}
		default:
		{
			// The user has previously denied access.
			self.setupResult = AVCamManualSetupResultCameraNotAuthorized;
			break;
		}
	}

	// Setup the capture session.
	// In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
	// Why not do all of this on the main queue?
	// Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
	// so that the main queue isn't blocked, which keeps the UI responsive.
	dispatch_async( self.sessionQueue, ^{
		if ( self.setupResult != AVCamManualSetupResultSuccess ) {
			return;
		}

		self.backgroundRecordingID = UIBackgroundTaskInvalid;
		NSError *error = nil;

		AVCaptureDevice *videoDevice = [AAPLCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

		if ( ! videoDeviceInput ) {
			NSLog( @"Could not create video device input: %@", error );
		}

		[self.session beginConfiguration];

		if ( [self.session canAddInput:videoDeviceInput] ) {
			[self.session addInput:videoDeviceInput];
			self.videoDeviceInput = videoDeviceInput;
			self.videoDevice = videoDevice;

			dispatch_async( dispatch_get_main_queue(), ^{
				// Why are we dispatching this to the main queue?
				// Because AVCaptureVideoPreviewLayer is the backing layer for AAPLPreviewView and UIView
				// can only be manipulated on the main thread.
				// Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
				// on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.

				// Use the status bar orientation as the initial video orientation. Subsequent orientation changes are handled by
				// -[viewWillTransitionToSize:withTransitionCoordinator:].
				UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
				AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
				if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
					initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
				}

				AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
				previewLayer.connection.videoOrientation = initialVideoOrientation;
			} );
		}
		else {
			NSLog( @"Could not add video device input to the session" );
			self.setupResult = AVCamManualSetupResultSessionConfigurationFailed;
		}

		AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
		AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];

		if ( ! audioDeviceInput ) {
			NSLog( @"Could not create audio device input: %@", error );
		}

		if ( [self.session canAddInput:audioDeviceInput] ) {
			[self.session addInput:audioDeviceInput];
		}
		else {
			NSLog( @"Could not add audio device input to the session" );
		}

		AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
		if ( [self.session canAddOutput:movieFileOutput] ) {
			[self.session addOutput:movieFileOutput];
			AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
			if ( connection.isVideoStabilizationSupported ) {
				connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
			}
			self.movieFileOutput = movieFileOutput;
		}
		else {
			NSLog( @"Could not add movie file output to the session" );
			self.setupResult = AVCamManualSetupResultSessionConfigurationFailed;
		}

		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ( [self.session canAddOutput:stillImageOutput] ) {
			[self.session addOutput:stillImageOutput];
			self.stillImageOutput = stillImageOutput;
			self.stillImageOutput.outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG };
			self.stillImageOutput.highResolutionStillImageOutputEnabled = YES;
		}
		else {
			NSLog( @"Could not add still image output to the session" );
			self.setupResult = AVCamManualSetupResultSessionConfigurationFailed;
		}

		[self.session commitConfiguration];
		
		dispatch_async( dispatch_get_main_queue(), ^{
			[self configureManualHUD];
		} );
	} );
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	dispatch_async( self.sessionQueue, ^{
		switch ( self.setupResult )
		{
			case AVCamManualSetupResultSuccess:
			{
				// Only setup observers and start the session running if setup succeeded.
				[self addObservers];
				[self.session startRunning];
				self.sessionRunning = self.session.isRunning;
				break;
			}
			case AVCamManualSetupResultCameraNotAuthorized:
			{
				dispatch_async( dispatch_get_main_queue(), ^{
					NSString *message = NSLocalizedString( @"AVCamManual doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
					UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCamManual" message:message preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
					[alertController addAction:cancelAction];
					// Provide quick access to Settings.
					UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
						[[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
					}];
					[alertController addAction:settingsAction];
					[self presentViewController:alertController animated:YES completion:nil];
				} );
				break;
			}
			case AVCamManualSetupResultSessionConfigurationFailed:
			{
				dispatch_async( dispatch_get_main_queue(), ^{
					NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
					UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCamManual" message:message preferredStyle:UIAlertControllerStyleAlert];
					UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
					[alertController addAction:cancelAction];
					[self presentViewController:alertController animated:YES completion:nil];
				} );
				break;
			}
		}
	} );
}

- (void)viewDidDisappear:(BOOL)animated
{
	dispatch_async( self.sessionQueue, ^{
		if ( self.setupResult == AVCamManualSetupResultSuccess ) {
			[self.session stopRunning];
			[self removeObservers];
		}
	} );

	[super viewDidDisappear:animated];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

#pragma mark Orientation

- (BOOL)shouldAutorotate
{
	// Disable autorotation of the interface when recording is in progress.
	return ! self.movieFileOutput.isRecording;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

	// Note that the app delegate controls the device orientation notifications required to use the device orientation.
	UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
	if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
		AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
		previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
	}
}

#pragma mark KVO and Notifications

- (void)addObservers
{
	[self addObserver:self forKeyPath:@"session.running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
	[self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:NSKeyValueObservingOptionNew context:CapturingStillImageContext];

	[self addObserver:self forKeyPath:@"videoDevice.focusMode" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:FocusModeContext];
	[self addObserver:self forKeyPath:@"videoDevice.lensPosition" options:NSKeyValueObservingOptionNew context:LensPositionContext];
	[self addObserver:self forKeyPath:@"videoDevice.exposureMode" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ExposureModeContext];
	[self addObserver:self forKeyPath:@"videoDevice.exposureDuration" options:NSKeyValueObservingOptionNew context:ExposureDurationContext];
	[self addObserver:self forKeyPath:@"videoDevice.ISO" options:NSKeyValueObservingOptionNew context:ISOContext];
	[self addObserver:self forKeyPath:@"videoDevice.exposureTargetOffset" options:NSKeyValueObservingOptionNew context:ExposureTargetOffsetContext];
	[self addObserver:self forKeyPath:@"videoDevice.whiteBalanceMode" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:WhiteBalanceModeContext];
	[self addObserver:self forKeyPath:@"videoDevice.deviceWhiteBalanceGains" options:NSKeyValueObservingOptionNew context:DeviceWhiteBalanceGainsContext];

	[self addObserver:self forKeyPath:@"stillImageOutput.lensStabilizationDuringBracketedCaptureEnabled" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:LensStabilizationContext];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDevice];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
	// A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9,
	// see also the documentation of AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions
	// and show a preview is paused message. See the documentation of AVCaptureSessionWasInterruptedNotification for other
	// interruption reasons.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
}

- (void)removeObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[self removeObserver:self forKeyPath:@"session.running" context:SessionRunningContext];
	[self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];

	[self removeObserver:self forKeyPath:@"videoDevice.focusMode" context:FocusModeContext];
	[self removeObserver:self forKeyPath:@"videoDevice.lensPosition" context:LensPositionContext];
	[self removeObserver:self forKeyPath:@"videoDevice.exposureMode" context:ExposureModeContext];
	[self removeObserver:self forKeyPath:@"videoDevice.exposureDuration" context:ExposureDurationContext];
	[self removeObserver:self forKeyPath:@"videoDevice.ISO" context:ISOContext];
	[self removeObserver:self forKeyPath:@"videoDevice.exposureTargetOffset" context:ExposureTargetOffsetContext];
	[self removeObserver:self forKeyPath:@"videoDevice.whiteBalanceMode" context:WhiteBalanceModeContext];
	[self removeObserver:self forKeyPath:@"videoDevice.deviceWhiteBalanceGains" context:DeviceWhiteBalanceGainsContext];

	[self removeObserver:self forKeyPath:@"stillImageOutput.lensStabilizationDuringBracketedCaptureEnabled" context:LensStabilizationContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	id oldValue = change[NSKeyValueChangeOldKey];
	id newValue = change[NSKeyValueChangeNewKey];

	if ( context == FocusModeContext ) {
		if ( newValue && newValue != [NSNull null] ) {
			AVCaptureFocusMode newMode = [newValue intValue];
			self.focusModeControl.selectedSegmentIndex = [self.focusModes indexOfObject:@(newMode)];
			self.lensPositionSlider.enabled = ( newMode == AVCaptureFocusModeLocked );
			
			if ( oldValue && oldValue != [NSNull null] ) {
				NSLog( @"focus mode: %@ -> %@", [self stringFromFocusMode:[oldValue intValue]], [self stringFromFocusMode:newMode] );
			}
			else {
				NSLog( @"focus mode: %@", [self stringFromFocusMode:newMode] );
			}
		}
	}
	else if ( context == LensPositionContext ) {
		if ( newValue && newValue != [NSNull null] ) {
			float newLensPosition = [newValue floatValue];
			
			if ( self.videoDevice.focusMode != AVCaptureFocusModeLocked ) {
				self.lensPositionSlider.value = newLensPosition;
			}
			self.lensPositionValueLabel.text = [NSString stringWithFormat:@"%.1f", newLensPosition];
		}
	}
	else if ( context == ExposureModeContext ) {
		if ( newValue && newValue != [NSNull null] ) {
			AVCaptureExposureMode newMode = [newValue intValue];
			
			self.exposureModeControl.selectedSegmentIndex = [self.exposureModes indexOfObject:@(newMode)];
			self.exposureDurationSlider.enabled = ( newMode == AVCaptureExposureModeCustom );
			self.ISOSlider.enabled = ( newMode == AVCaptureExposureModeCustom );
			
			if ( oldValue && oldValue != [NSNull null] ) {
				AVCaptureExposureMode oldMode = [oldValue intValue];
				/*
				 It’s important to understand the relationship between exposureDuration and the minimum frame rate as represented by activeVideoMaxFrameDuration.
				 In manual mode, if exposureDuration is set to a value that's greater than activeVideoMaxFrameDuration, then activeVideoMaxFrameDuration will
				 increase to match it, thus lowering the minimum frame rate. If exposureMode is then changed to automatic mode, the minimum frame rate will
				 remain lower than its default. If this is not the desired behavior, the min and max frameRates can be reset to their default values for the
				 current activeFormat by setting activeVideoMaxFrameDuration and activeVideoMinFrameDuration to kCMTimeInvalid.
				 */
				if ( oldMode != newMode && oldMode == AVCaptureExposureModeCustom ) {
					NSError *error = nil;
					if ( [self.videoDevice lockForConfiguration:&error] ) {
						self.videoDevice.activeVideoMaxFrameDuration = kCMTimeInvalid;
						self.videoDevice.activeVideoMinFrameDuration = kCMTimeInvalid;
						[self.videoDevice unlockForConfiguration];
					}
					else {
						NSLog( @"Could not lock device for configuration: %@", error );
					}
				}
				NSLog( @"exposure mode: %@ -> %@", [self stringFromExposureMode:oldMode], [self stringFromExposureMode:newMode] );
			}
		}
	}
	else if ( context == ExposureDurationContext ) {
		if ( newValue && newValue != [NSNull null] ) {
			double newDurationSeconds = CMTimeGetSeconds( [newValue CMTimeValue] );
			if ( self.videoDevice.exposureMode != AVCaptureExposureModeCustom ) {
				double minDurationSeconds = MAX( CMTimeGetSeconds( self.videoDevice.activeFormat.minExposureDuration ), kExposureMinimumDuration );
				double maxDurationSeconds = CMTimeGetSeconds( self.videoDevice.activeFormat.maxExposureDuration );
				// Map from duration to non-linear UI range 0-1
				double p = ( newDurationSeconds - minDurationSeconds ) / ( maxDurationSeconds - minDurationSeconds ); // Scale to 0-1
				self.exposureDurationSlider.value = pow( p, 1 / kExposureDurationPower ); // Apply inverse power
				
				if ( newDurationSeconds < 1 ) {
					int digits = MAX( 0, 2 + floor( log10( newDurationSeconds ) ) );
					self.exposureDurationValueLabel.text = [NSString stringWithFormat:@"1/%.*f", digits, 1/newDurationSeconds];
				}
				else {
					self.exposureDurationValueLabel.text = [NSString stringWithFormat:@"%.2f", newDurationSeconds];
				}
			}
		}
	}
	else if ( context == ISOContext ) {
		if ( newValue && newValue != [NSNull null] ) {
			float newISO = [newValue floatValue];
			
			if ( self.videoDevice.exposureMode != AVCaptureExposureModeCustom ) {
				self.ISOSlider.value = newISO;
			}
			self.ISOValueLabel.text = [NSString stringWithFormat:@"%i", (int)newISO];
		}
	}
	else if ( context == ExposureTargetOffsetContext ) {
		if ( newValue && newValue != [NSNull null] ) {
			float newExposureTargetOffset = [newValue floatValue];
			
			self.exposureTargetOffsetSlider.value = newExposureTargetOffset;
			self.exposureTargetOffsetValueLabel.text = [NSString stringWithFormat:@"%.1f", newExposureTargetOffset];
		}
	}
	else if ( context == WhiteBalanceModeContext ) {
		if ( newValue && newValue != [NSNull null] ) {
			AVCaptureWhiteBalanceMode newMode = [newValue intValue];
			
			self.whiteBalanceModeControl.selectedSegmentIndex = [self.whiteBalanceModes indexOfObject:@(newMode)];
			self.temperatureSlider.enabled = ( newMode == AVCaptureWhiteBalanceModeLocked );
			self.tintSlider.enabled = ( newMode == AVCaptureWhiteBalanceModeLocked );
			
			if ( oldValue && oldValue != [NSNull null] ) {
				AVCaptureWhiteBalanceMode oldMode = [oldValue intValue];
				NSLog( @"white balance mode: %@ -> %@", [self stringFromWhiteBalanceMode:oldMode], [self stringFromWhiteBalanceMode:newMode] );
			}
		}
	}
	else if ( context == DeviceWhiteBalanceGainsContext ) {
		if ( newValue && newValue != [NSNull null] ) {
			AVCaptureWhiteBalanceGains newGains;
			[newValue getValue:&newGains];
			AVCaptureWhiteBalanceTemperatureAndTintValues newTemperatureAndTint = [self.videoDevice temperatureAndTintValuesForDeviceWhiteBalanceGains:newGains];
			
			if ( self.videoDevice.whiteBalanceMode != AVCaptureExposureModeLocked ) {
				self.temperatureSlider.value = newTemperatureAndTint.temperature;
				self.tintSlider.value = newTemperatureAndTint.tint;
			}
			self.temperatureValueLabel.text = [NSString stringWithFormat:@"%i", (int)newTemperatureAndTint.temperature];
			self.tintValueLabel.text = [NSString stringWithFormat:@"%i", (int)newTemperatureAndTint.tint];
		}
	}
	else if ( context == CapturingStillImageContext ) {
		BOOL isCapturingStillImage = NO;
		if ( newValue && newValue != [NSNull null] ) {
			isCapturingStillImage = [newValue boolValue];
		}
		
		if ( isCapturingStillImage ) {
			dispatch_async( dispatch_get_main_queue(), ^{
				self.previewView.layer.opacity = 0.0;
				[UIView animateWithDuration:0.25 animations:^{
					self.previewView.layer.opacity = 1.0;
				}];
			} );
		}
	}
	else if ( context == SessionRunningContext ) {
		BOOL isRunning = NO;
		if ( newValue && newValue != [NSNull null] ) {
			isRunning = [newValue boolValue];
		}

		dispatch_async( dispatch_get_main_queue(), ^{
			self.cameraButton.enabled = ( isRunning && [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1 );
			self.recordButton.enabled = isRunning;
			self.stillButton.enabled = isRunning;
		} );
	}
	else if ( context == LensStabilizationContext ) {
		if ( newValue && newValue != [NSNull null] ) {
			BOOL newMode = [newValue boolValue];
			self.lensStabilizationControl.selectedSegmentIndex = ( newMode ? 1 : 0 );
			if ( oldValue && oldValue != [NSNull null] ) {
				BOOL oldMode = [oldValue boolValue];
				NSLog( @"Lens stabilization: %s -> %s", ( oldMode ? "YES" : "NO" ), ( newMode ? "YES" : "NO" ) );
			}
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
	CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
	NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
	NSLog( @"Capture session runtime error: %@", error );

	if ( error.code == AVErrorMediaServicesWereReset ) {
		dispatch_async( self.sessionQueue, ^{
			// If we aren't trying to resume the session running, then try to restart it since it must have been stopped due to an error. See also -[resumeInterruptedSession:].
			if ( self.isSessionRunning ) {
				[self.session startRunning];
				self.sessionRunning = self.session.isRunning;
			}
			else {
				dispatch_async( dispatch_get_main_queue(), ^{
					self.resumeButton.hidden = NO;
				} );
			}
		} );
	}
	else {
		self.resumeButton.hidden = NO;
	}
}

- (void)sessionWasInterrupted:(NSNotification *)notification
{
	// In some scenarios we want to enable the user to resume the session running.
	// For example, if music playback is initiated via control center while using AVCamManual,
	// then the user can let AVCamManual resume the session running, which will stop music playback.
	// Note that stopping music playback in control center will not automatically resume the session running.
	// Also note that it is not always possible to resume, see -[resumeInterruptedSession:].

	// In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
	AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
	NSLog( @"Capture session was interrupted with reason %ld", (long)reason );

	if ( reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
		 reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient ) {
		// Simply fade-in a button to enable the user to try to resume the session running.
		self.resumeButton.hidden = NO;
		self.resumeButton.alpha = 0.0;
		[UIView animateWithDuration:0.25 animations:^{
			self.resumeButton.alpha = 1.0;
		}];
	}
	else if ( reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps ) {
		// Simply fade-in a label to inform the user that the camera is unavailable.
		self.cameraUnavailableLabel.hidden = NO;
		self.cameraUnavailableLabel.alpha = 0.0;
		[UIView animateWithDuration:0.25 animations:^{
			self.cameraUnavailableLabel.alpha = 1.0;
		}];
	}
}

- (void)sessionInterruptionEnded:(NSNotification *)notification
{
	NSLog( @"Capture session interruption ended" );

	if ( ! self.resumeButton.hidden ) {
		[UIView animateWithDuration:0.25 animations:^{
			self.resumeButton.alpha = 0.0;
		} completion:^( BOOL finished ) {
			self.resumeButton.hidden = YES;
		}];
	}
	if ( ! self.cameraUnavailableLabel.hidden ) {
		[UIView animateWithDuration:0.25 animations:^{
			self.cameraUnavailableLabel.alpha = 0.0;
		} completion:^( BOOL finished ) {
			self.cameraUnavailableLabel.hidden = YES;
		}];
	}
}

#pragma mark Actions

- (IBAction)resumeInterruptedSession:(id)sender
{
	dispatch_async( self.sessionQueue, ^{
		// The session might fail to start running, e.g., if a phone or FaceTime call is still using audio or video.
		// A failure to start the session running will be communicated via a session runtime error notification.
		// To avoid repeatedly failing to start the session running, we only try to restart the session running in the
		// session runtime error handler if we aren't trying to resume the session running.
		[self.session startRunning];
		self.sessionRunning = self.session.isRunning;
		if ( ! self.session.isRunning ) {
			dispatch_async( dispatch_get_main_queue(), ^{
				NSString *message = NSLocalizedString( @"Unable to resume", @"Alert message when unable to resume the session running" );
				UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCamManual" message:message preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
				[alertController addAction:cancelAction];
				[self presentViewController:alertController animated:YES completion:nil];
			} );
		}
		else {
			dispatch_async( dispatch_get_main_queue(), ^{
				self.resumeButton.hidden = YES;
			} );
		}
	} );
}

- (IBAction)toggleMovieRecording:(id)sender
{
	// Disable the Camera button until recording finishes, and disable the Record button until recording starts or finishes. See the
	// AVCaptureFileOutputRecordingDelegate methods.
	self.cameraButton.enabled = NO;
	self.recordButton.enabled = NO;

	dispatch_async( self.sessionQueue, ^{
		if ( ! self.movieFileOutput.isRecording ) {
			if ( [UIDevice currentDevice].isMultitaskingSupported ) {
				// Setup background task. This is needed because the -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:]
				// callback is not received until AVCamManual returns to the foreground unless you request background execution time.
				// This also ensures that there will be time to write the file to the photo library when AVCamManual is backgrounded.
				// To conclude this background execution, -endBackgroundTask is called in
				// -[captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:] after the recorded file has been saved.
				self.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
			}

			// Update the orientation on the movie file output video connection before starting recording.
			AVCaptureConnection *movieConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
			AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
			movieConnection.videoOrientation = previewLayer.connection.videoOrientation;

			// Turn OFF flash for video recording.
			[AAPLCameraViewController setFlashMode:AVCaptureFlashModeOff forDevice:self.videoDevice];

			// Start recording to a temporary file.
			NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
			NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
			[self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputFilePath] recordingDelegate:self];
		}
		else {
			[self.movieFileOutput stopRecording];
		}
	} );
}

- (IBAction)changeCamera:(id)sender
{
	self.cameraButton.enabled = NO;
	self.recordButton.enabled = NO;
	self.stillButton.enabled = NO;

	dispatch_async( self.sessionQueue, ^{
		AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
		
		switch ( self.videoDevice.position )
		{
			case AVCaptureDevicePositionUnspecified:
			case AVCaptureDevicePositionFront:
				preferredPosition = AVCaptureDevicePositionBack;
				break;
			case AVCaptureDevicePositionBack:
				preferredPosition = AVCaptureDevicePositionFront;
				break;
		}

		AVCaptureDevice *newVideoDevice = [AAPLCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
		AVCaptureDeviceInput *newVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newVideoDevice error:nil];

		[self.session beginConfiguration];

		// Remove the existing device input first, since using the front and back camera simultaneously is not supported.
		[self.session removeInput:self.videoDeviceInput];
		if ( [self.session canAddInput:newVideoDeviceInput] ) {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDevice];
			
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:newVideoDevice];

			[self.session addInput:newVideoDeviceInput];
			self.videoDeviceInput = newVideoDeviceInput;
			self.videoDevice = newVideoDevice;
		}
		else {
			[self.session addInput:self.videoDeviceInput];
		}

		AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
		if ( connection.isVideoStabilizationSupported ) {
			connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
		}

		[self.session commitConfiguration];

		dispatch_async( dispatch_get_main_queue(), ^{
			self.cameraButton.enabled = YES;
			self.recordButton.enabled = YES;
			self.stillButton.enabled = YES;
			
			[self configureManualHUD];
		} );
	} );
}

- (IBAction)snapStillImage:(id)sender
{
	dispatch_async( self.sessionQueue, ^{
		AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
		AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;

		// Update the orientation on the still image output video connection before capturing.
		stillImageConnection.videoOrientation = previewLayer.connection.videoOrientation;

		// Flash set to Auto for Still Capture
		if ( self.videoDevice.exposureMode == AVCaptureExposureModeCustom ) {
			[AAPLCameraViewController setFlashMode:AVCaptureFlashModeOff forDevice:self.videoDevice];
		}
		else {
			[AAPLCameraViewController setFlashMode:AVCaptureFlashModeAuto forDevice:self.videoDevice];
		}

		if ( ! self.stillImageOutput.lensStabilizationDuringBracketedCaptureEnabled ) {
			// Capture a still image
			[self.stillImageOutput captureStillImageAsynchronouslyFromConnection:[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
				if ( error ) {
					NSLog( @"Error capture still image %@", error );
				}
				else if ( imageDataSampleBuffer ) {
					NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];

					[PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
						if ( status == PHAuthorizationStatusAuthorized ) {
							[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
								[[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
							} completionHandler:^( BOOL success, NSError *error ) {
								if ( ! success ) {
									NSLog( @"Error occured while saving image to photo library: %@", error );
								}
							}];
						}
					}];
				}
			}];
		}
		else {
			// Capture a bracket
			NSArray *bracketSettings;
			if ( self.videoDevice.exposureMode == AVCaptureExposureModeCustom ) {
				bracketSettings = @[[AVCaptureManualExposureBracketedStillImageSettings manualExposureSettingsWithExposureDuration:AVCaptureExposureDurationCurrent ISO:AVCaptureISOCurrent]];
			}
			else {
				bracketSettings = @[[AVCaptureAutoExposureBracketedStillImageSettings autoExposureSettingsWithExposureTargetBias:AVCaptureExposureTargetBiasCurrent]];
			}

			[self.stillImageOutput captureStillImageBracketAsynchronouslyFromConnection:[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo]
																	  withSettingsArray:bracketSettings
																	  completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, AVCaptureBracketedStillImageSettings *stillImageSettings, NSError *error ) {
																		  if ( error ) {
																			  NSLog( @"Error bracketing capture still image %@", error );
																		  }
																		  else if (imageDataSampleBuffer) {
																			  NSLog( @"Lens Stabilization State: %@", (__bridge id)CMGetAttachment(imageDataSampleBuffer, kCMSampleBufferAttachmentKey_StillImageLensStabilizationInfo, NULL) );
																			  NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
																			  
																			  [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
																				  if ( status == PHAuthorizationStatusAuthorized ) {
																					  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
																						  [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
																					  } completionHandler:^( BOOL success, NSError *error ) {
																						  if ( ! success ) {
																							  NSLog( @"Error occured while saving image to photo library: %@", error );
																						  }
																					  }];
																				  }
																			  }];
																		  }
																	  }];
		}
	} );
}

- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
	if ( self.videoDevice.focusMode != AVCaptureFocusModeLocked && self.videoDevice.exposureMode != AVCaptureExposureModeCustom ) {
		CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.previewView.layer captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
		[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
	}
}

- (IBAction)changeManualHUD:(id)sender
{
	UISegmentedControl *control = sender;
	
	self.manualHUDFocusView.hidden = ( control.selectedSegmentIndex == 1 ) ? NO : YES;
	self.manualHUDExposureView.hidden = ( control.selectedSegmentIndex == 2 ) ? NO : YES;
	self.manualHUDWhiteBalanceView.hidden = ( control.selectedSegmentIndex == 3 ) ? NO : YES;
	self.manualHUDLensStabilizationView.hidden = ( control.selectedSegmentIndex == 4 ) ? NO : YES;
}

- (IBAction)changeFocusMode:(id)sender
{
	UISegmentedControl *control = sender;
	AVCaptureFocusMode mode = (AVCaptureFocusMode)[self.focusModes[control.selectedSegmentIndex] intValue];
	NSError *error = nil;
	
	if ( [self.videoDevice lockForConfiguration:&error] ) {
		if ( [self.videoDevice isFocusModeSupported:mode] ) {
			self.videoDevice.focusMode = mode;
		}
		else {
			NSLog( @"Focus mode %@ is not supported. Focus mode is %@.", [self stringFromFocusMode:mode], [self stringFromFocusMode:self.videoDevice.focusMode] );
			self.focusModeControl.selectedSegmentIndex = [self.focusModes indexOfObject:@(self.videoDevice.focusMode)];
		}
		[self.videoDevice unlockForConfiguration];
	}
	else {
		NSLog( @"Could not lock device for configuration: %@", error );
	}
}
- (IBAction)changeExposureMode:(id)sender
{
	UISegmentedControl *control = sender;
	AVCaptureExposureMode mode = (AVCaptureExposureMode)[self.exposureModes[control.selectedSegmentIndex] intValue];
	NSError *error = nil;
	
	if ( [self.videoDevice lockForConfiguration:&error] ) {
		if ( [self.videoDevice isExposureModeSupported:mode] ) {
			self.videoDevice.exposureMode = mode;
		}
		else {
			NSLog( @"Exposure mode %@ is not supported. Exposure mode is %@.", [self stringFromExposureMode:mode], [self stringFromExposureMode:self.videoDevice.exposureMode] );
		}
		[self.videoDevice unlockForConfiguration];
	}
	else {
		NSLog( @"Could not lock device for configuration: %@", error );
	}
}

- (IBAction)changeWhiteBalanceMode:(id)sender
{
	UISegmentedControl *control = sender;
	AVCaptureWhiteBalanceMode mode = (AVCaptureWhiteBalanceMode)[self.whiteBalanceModes[control.selectedSegmentIndex] intValue];
	NSError *error = nil;
	
	if ( [self.videoDevice lockForConfiguration:&error] ) {
		if ( [self.videoDevice isWhiteBalanceModeSupported:mode] ) {
			self.videoDevice.whiteBalanceMode = mode;
		}
		else {
			NSLog( @"White balance mode %@ is not supported. White balance mode is %@.", [self stringFromWhiteBalanceMode:mode], [self stringFromWhiteBalanceMode:self.videoDevice.whiteBalanceMode] );
		}
		[self.videoDevice unlockForConfiguration];
	}
	else {
		NSLog( @"Could not lock device for configuration: %@", error );
	}
}

- (IBAction)changeLensPosition:(id)sender
{
	UISlider *control = sender;
	NSError *error = nil;
	
	if ( [self.videoDevice lockForConfiguration:&error] ) {
		[self.videoDevice setFocusModeLockedWithLensPosition:control.value completionHandler:nil];
	    [self.videoDevice unlockForConfiguration];
	}
	else {
		NSLog( @"Could not lock device for configuration: %@", error );
	}
}

- (IBAction)changeExposureDuration:(id)sender
{
	UISlider *control = sender;
	NSError *error = nil;
	
	double p = pow( control.value, kExposureDurationPower ); // Apply power function to expand slider's low-end range
	double minDurationSeconds = MAX( CMTimeGetSeconds( self.videoDevice.activeFormat.minExposureDuration ), kExposureMinimumDuration );
	double maxDurationSeconds = CMTimeGetSeconds( self.videoDevice.activeFormat.maxExposureDuration );
	double newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
	
	if ( self.videoDevice.exposureMode == AVCaptureExposureModeCustom ) {
		if ( newDurationSeconds < 1 ) {
			int digits = MAX( 0, 2 + floor( log10( newDurationSeconds ) ) );
			self.exposureDurationValueLabel.text = [NSString stringWithFormat:@"1/%.*f", digits, 1/newDurationSeconds];
		}
		else {
			self.exposureDurationValueLabel.text = [NSString stringWithFormat:@"%.2f", newDurationSeconds];
		}
	}

	if ( [self.videoDevice lockForConfiguration:&error] ) {
		[self.videoDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds( newDurationSeconds, 1000*1000*1000 )  ISO:AVCaptureISOCurrent completionHandler:nil];
        [self.videoDevice unlockForConfiguration];
	}
	else {
		NSLog( @"Could not lock device for configuration: %@", error );
	}
}

- (IBAction)changeISO:(id)sender
{
	UISlider *control = sender;
	NSError *error = nil;
	
	if ( [self.videoDevice lockForConfiguration:&error] ) {
		[self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:control.value completionHandler:nil];
        [self.videoDevice unlockForConfiguration];
	}
	else {
		NSLog( @"Could not lock device for configuration: %@", error );
	}
}

- (IBAction)changeExposureTargetBias:(id)sender
{
	UISlider *control = sender;
	NSError *error = nil;
	
	if ( [self.videoDevice lockForConfiguration:&error] ) {
		[self.videoDevice setExposureTargetBias:control.value completionHandler:nil];
        [self.videoDevice unlockForConfiguration];
		self.exposureTargetBiasValueLabel.text = [NSString stringWithFormat:@"%.1f", control.value];
	}
	else {
		NSLog( @"Could not lock device for configuration: %@", error );
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

- (IBAction)changeLensStabilization:(id)sender
{
	UISegmentedControl *control = sender;
	BOOL lensStabilizationDuringBracketedCaptureEnabled = ( control.selectedSegmentIndex ? YES : NO );
	if ( lensStabilizationDuringBracketedCaptureEnabled ) {
		self.stillButton.enabled = NO;
	}
	dispatch_async( self.sessionQueue, ^{
		if ( self.stillImageOutput.lensStabilizationDuringBracketedCaptureSupported ) {
			if ( lensStabilizationDuringBracketedCaptureEnabled ) {
				// Still image capture will be done with the bracketed capture API.
				self.stillImageOutput.lensStabilizationDuringBracketedCaptureEnabled = YES;
				NSArray *bracketSettings;
				if ( self.videoDevice.exposureMode == AVCaptureExposureModeCustom ) {
					bracketSettings = @[[AVCaptureManualExposureBracketedStillImageSettings manualExposureSettingsWithExposureDuration:AVCaptureExposureDurationCurrent ISO:AVCaptureISOCurrent]];
				}
				else {
					bracketSettings = @[[AVCaptureAutoExposureBracketedStillImageSettings autoExposureSettingsWithExposureTargetBias:AVCaptureExposureTargetBiasCurrent]];
				}
				[self.stillImageOutput prepareToCaptureStillImageBracketFromConnection:[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo]
													 withSettingsArray:bracketSettings
													 completionHandler:^( BOOL prepared, NSError *error ) {
														 if ( error ) {
															 NSLog( @"Error preparing for bracketed capture %@", error );
														 }
														 dispatch_async( dispatch_get_main_queue(), ^{
															 self.stillButton.enabled = YES;
														 } );
													 }];
			}
			else {
				self.stillImageOutput.lensStabilizationDuringBracketedCaptureEnabled = NO;
			}
		}
	} );
}

- (IBAction)sliderTouchBegan:(id)sender
{
	UISlider *slider = (UISlider*)sender;
	[self setSlider:slider highlightColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]];
}

- (IBAction)sliderTouchEnded:(id)sender
{
	UISlider *slider = (UISlider*)sender;
	[self setSlider:slider highlightColor:[UIColor yellowColor]];
}

#pragma mark UI

- (void)configureManualHUD
{
	// Manual focus controls
	self.focusModes = @[@(AVCaptureFocusModeContinuousAutoFocus), @(AVCaptureFocusModeLocked)];

	self.focusModeControl.enabled = ( self.videoDevice != nil );
	self.focusModeControl.selectedSegmentIndex = [self.focusModes indexOfObject:@(self.videoDevice.focusMode)];
	for ( NSNumber *mode in self.focusModes ) {
		[self.focusModeControl setEnabled:([self.videoDevice isFocusModeSupported:mode.intValue]) forSegmentAtIndex:[self.focusModes indexOfObject:mode]];
	}

	self.lensPositionSlider.minimumValue = 0.0;
	self.lensPositionSlider.maximumValue = 1.0;
	self.lensPositionSlider.enabled = ( self.videoDevice && self.videoDevice.focusMode == AVCaptureFocusModeLocked );

	// Manual exposure controls
	self.exposureModes = @[@(AVCaptureExposureModeContinuousAutoExposure), @(AVCaptureExposureModeLocked), @(AVCaptureExposureModeCustom)];

	self.exposureModeControl.enabled = ( self.videoDevice != nil );
	self.exposureModeControl.selectedSegmentIndex = [self.exposureModes indexOfObject:@(self.videoDevice.exposureMode)];
	for ( NSNumber *mode in self.exposureModes ) {
		[self.exposureModeControl setEnabled:([self.videoDevice isExposureModeSupported:mode.intValue]) forSegmentAtIndex:[self.exposureModes indexOfObject:mode]];
	}

	// Use 0-1 as the slider range and do a non-linear mapping from the slider value to the actual device exposure duration
	self.exposureDurationSlider.minimumValue = 0;
	self.exposureDurationSlider.maximumValue = 1;
	self.exposureDurationSlider.enabled = ( self.videoDevice && self.videoDevice.exposureMode == AVCaptureExposureModeCustom );

	self.ISOSlider.minimumValue = self.videoDevice.activeFormat.minISO;
	self.ISOSlider.maximumValue = self.videoDevice.activeFormat.maxISO;
	self.ISOSlider.enabled = ( self.videoDevice.exposureMode == AVCaptureExposureModeCustom );

	self.exposureTargetBiasSlider.minimumValue = self.videoDevice.minExposureTargetBias;
	self.exposureTargetBiasSlider.maximumValue = self.videoDevice.maxExposureTargetBias;
	self.exposureTargetBiasSlider.enabled = ( self.videoDevice != nil );

	self.exposureTargetOffsetSlider.minimumValue = self.videoDevice.minExposureTargetBias;
	self.exposureTargetOffsetSlider.maximumValue = self.videoDevice.maxExposureTargetBias;
	self.exposureTargetOffsetSlider.enabled = NO;

	// Manual white balance controls
	self.whiteBalanceModes = @[@(AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance), @(AVCaptureWhiteBalanceModeLocked)];

	self.whiteBalanceModeControl.enabled = (self.videoDevice != nil);
	self.whiteBalanceModeControl.selectedSegmentIndex = [self.whiteBalanceModes indexOfObject:@(self.videoDevice.whiteBalanceMode)];
	for ( NSNumber *mode in self.whiteBalanceModes ) {
		[self.whiteBalanceModeControl setEnabled:[self.videoDevice isWhiteBalanceModeSupported:mode.intValue] forSegmentAtIndex:[self.whiteBalanceModes indexOfObject:mode]];
	}

	self.temperatureSlider.minimumValue = 3000;
	self.temperatureSlider.maximumValue = 8000;
	self.temperatureSlider.enabled = ( self.videoDevice && self.videoDevice.whiteBalanceMode == AVCaptureWhiteBalanceModeLocked );

	self.tintSlider.minimumValue = -150;
	self.tintSlider.maximumValue = 150;
	self.tintSlider.enabled = ( self.videoDevice && self.videoDevice.whiteBalanceMode == AVCaptureWhiteBalanceModeLocked );

	self.lensStabilizationControl.enabled = ( self.videoDevice != nil );
	self.lensStabilizationControl.selectedSegmentIndex = ( self.stillImageOutput.lensStabilizationDuringBracketedCaptureEnabled ? 1 : 0 );
	[self.lensStabilizationControl setEnabled:self.stillImageOutput.lensStabilizationDuringBracketedCaptureSupported forSegmentAtIndex:1];
}

- (void)setSlider:(UISlider*)slider highlightColor:(UIColor*)color
{
	slider.tintColor = color;
	
	if ( slider == self.lensPositionSlider ) {
		self.lensPositionNameLabel.textColor = self.lensPositionValueLabel.textColor = slider.tintColor;
	}
	else if ( slider == self.exposureDurationSlider ) {
		self.exposureDurationNameLabel.textColor = self.exposureDurationValueLabel.textColor = slider.tintColor;
	}
	else if ( slider == self.ISOSlider ) {
		self.ISONameLabel.textColor = self.ISOValueLabel.textColor = slider.tintColor;
	}
	else if ( slider == self.exposureTargetBiasSlider ) {
		self.exposureTargetBiasNameLabel.textColor = self.exposureTargetBiasValueLabel.textColor = slider.tintColor;
	}
	else if ( slider == self.temperatureSlider ) {
		self.temperatureNameLabel.textColor = self.temperatureValueLabel.textColor = slider.tintColor;
	}
	else if ( slider == self.tintSlider ) {
		self.tintNameLabel.textColor = self.tintValueLabel.textColor = slider.tintColor;
	}
}

#pragma mark File Output Recording Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
	// Enable the Record button to let the user stop the recording.
	dispatch_async( dispatch_get_main_queue(), ^{
		self.recordButton.enabled = YES;
		[self.recordButton setTitle:NSLocalizedString( @"Stop", @"Recording button stop title") forState:UIControlStateNormal];
	});
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
	// Note that currentBackgroundRecordingID is used to end the background task associated with this recording.
	// This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's isRecording property
	// is back to NO — which happens sometime after this method returns.
	// Note: Since we use a unique file path for each recording, a new recording will not overwrite a recording currently being saved.
	UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
	self.backgroundRecordingID = UIBackgroundTaskInvalid;

	dispatch_block_t cleanup = ^{
		[[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
		if ( currentBackgroundRecordingID != UIBackgroundTaskInvalid ) {
			[[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
		}
	};

	BOOL success = YES;

	if ( error ) {
		NSLog( @"Movie file finishing error: %@", error );
		success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
	}
	if ( success ) {
		// Check authorization status.
		[PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
			if ( status == PHAuthorizationStatusAuthorized ) {
				// Save the movie file to the photo library and cleanup.
				[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
					// In iOS 9 and later, it's possible to move the file into the photo library without duplicating the file data.
					// This avoids using double the disk space during save, which can make a difference on devices with limited free disk space.
					PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
					options.shouldMoveFile = YES;
					PHAssetCreationRequest *changeRequest = [PHAssetCreationRequest creationRequestForAsset];
					[changeRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:outputFileURL options:options];
				} completionHandler:^( BOOL success, NSError *error ) {
					if ( ! success ) {
						NSLog( @"Could not save movie to photo library: %@", error );
					}
					cleanup();
				}];
			}
			else {
				cleanup();
			}
		}];
	}
	else {
		cleanup();
	}

	// Enable the Camera and Record buttons to let the user switch camera and start another recording.
	dispatch_async( dispatch_get_main_queue(), ^{
		// Only enable the ability to change camera if the device has more than one camera.
		self.cameraButton.enabled = ( [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1 );
		self.recordButton.enabled = YES;
		[self.recordButton setTitle:NSLocalizedString( @"Record", @"Recording button record title") forState:UIControlStateNormal];
	});
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
	dispatch_async( self.sessionQueue, ^{
		AVCaptureDevice *device = self.videoDevice;

		NSError *error = nil;
		if ( [device lockForConfiguration:&error] ) {
			// Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
			// Call -set(Focus/Exposure)Mode: to apply the new point of interest.
			if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
				device.focusPointOfInterest = point;
				device.focusMode = focusMode;
			}

			if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
				device.exposurePointOfInterest = point;
				device.exposureMode = exposureMode;
			}

			device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
			[device unlockForConfiguration];
		}
		else {
			NSLog( @"Could not lock device for configuration: %@", error );
		}
	} );
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
	if ( device.hasFlash && [device isFlashModeSupported:flashMode] ) {
		NSError *error = nil;
		if ( [device lockForConfiguration:&error] ) {
			device.flashMode = flashMode;
			[device unlockForConfiguration];
		}
		else {
			NSLog( @"Could not lock device for configuration: %@", error );
		}
	}
}

- (void)setWhiteBalanceGains:(AVCaptureWhiteBalanceGains)gains
{
	NSError *error = nil;
	
	if ( [self.videoDevice lockForConfiguration:&error] ) {
		AVCaptureWhiteBalanceGains normalizedGains = [self normalizedGains:gains]; // Conversion can yield out-of-bound values, cap to limits
		[self.videoDevice setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:normalizedGains completionHandler:nil];
        [self.videoDevice unlockForConfiguration];
	}
	else {
		NSLog( @"Could not lock device for configuration: %@", error );
	}
}

#pragma mark Utilities

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = devices.firstObject;

	for ( AVCaptureDevice *device in devices ) {
		if ( device.position == position ) {
			captureDevice = device;
			break;
		}
	}

	return captureDevice;
}

- (NSString *)stringFromFocusMode:(AVCaptureFocusMode) focusMode
{
	NSString *string = @"INVALID FOCUS MODE";
	
	if ( focusMode == AVCaptureFocusModeLocked ) {
		string = @"Locked";
	}
	else if ( focusMode == AVCaptureFocusModeAutoFocus ) {
		string = @"Auto";
	}
	else if ( focusMode == AVCaptureFocusModeContinuousAutoFocus ) {
		string = @"ContinuousAuto";
	}
	
	return string;
}

- (NSString *)stringFromExposureMode:(AVCaptureExposureMode) exposureMode
{
	NSString *string = @"INVALID EXPOSURE MODE";
	
	if ( exposureMode == AVCaptureExposureModeLocked ) {
		string = @"Locked";
	}
	else if ( exposureMode == AVCaptureExposureModeAutoExpose ) {
		string = @"Auto";
	}
	else if ( exposureMode == AVCaptureExposureModeContinuousAutoExposure ) {
		string = @"ContinuousAuto";
	}
	else if ( exposureMode == AVCaptureExposureModeCustom ) {
		string = @"Custom";
	}
	
	return string;
}

- (NSString *)stringFromWhiteBalanceMode:(AVCaptureWhiteBalanceMode) whiteBalanceMode
{
	NSString *string = @"INVALID WHITE BALANCE MODE";
	
	if ( whiteBalanceMode == AVCaptureWhiteBalanceModeLocked ) {
		string = @"Locked";
	}
	else if ( whiteBalanceMode == AVCaptureWhiteBalanceModeAutoWhiteBalance ) {
		string = @"Auto";
	}
	else if ( whiteBalanceMode == AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance ) {
		string = @"ContinuousAuto";
	}
	
	return string;
}

- (AVCaptureWhiteBalanceGains)normalizedGains:(AVCaptureWhiteBalanceGains) gains
{
	AVCaptureWhiteBalanceGains g = gains;
	
	g.redGain = MAX( 1.0, g.redGain );
	g.greenGain = MAX( 1.0, g.greenGain );
	g.blueGain = MAX( 1.0, g.blueGain );
	
	g.redGain = MIN( self.videoDevice.maxWhiteBalanceGain, g.redGain );
	g.greenGain = MIN( self.videoDevice.maxWhiteBalanceGain, g.greenGain );
	g.blueGain = MIN( self.videoDevice.maxWhiteBalanceGain, g.blueGain );
	
	return g;
}

@end
