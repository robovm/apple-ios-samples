/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
 View controller for the camera interface and selecting location capture mode.
  
 */

#import "AAPLViewController.h"
#import "AAPLCaptureManager.h"

@import AssetsLibrary;

@interface AAPLViewController () <AAPLCaptureManagerDelegate>
{
	AAPLCaptureManager				*_captureManager;
	UIBackgroundTaskIdentifier		_backgroundRecordingID;
}

@property IBOutlet UIView				*previewView;
@property IBOutlet UIBarButtonItem		*recordButton;
@property IBOutlet UISegmentedControl	*locationUpdateModeButton;
@property IBOutlet UILabel				*currentLocation;

- (IBAction)toggleLocationUpdateMode:(id)sender;
- (IBAction)toggleRecording:(id)sender;

@end

@implementation AAPLViewController

#pragma mark - View Loading

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Initialize the class responsible for managing AV capture session and asset writer
    _captureManager = [[AAPLCaptureManager alloc] init];
	_captureManager.delegate = self;
	
	//Set default distance senstivity to 5 meters, which for this sample code purpose is considered as sensitivity for walking
	_captureManager.distanceUpdateInMeters = 5.0;
	
	// Keep track of changes to the device orientation so we can update the capture manager
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	
	// Setup and start the capture session
    [_captureManager setupAndStartCaptureSession];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
	
	// Setup preview layer
	if (_captureManager.session)
	{
		AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:_captureManager.session];
		layer.videoGravity = AVLayerVideoGravityResizeAspect;
		layer.frame = self.previewView.bounds;
		[self.previewView.layer addSublayer:layer];
	}
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	[self cleanup];
}

- (void)cleanup
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	
	[notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
	
    // Stop and tear down the capture session
	[_captureManager stopAndTearDownCaptureSession];
	_captureManager.delegate = nil;
}

- (void)applicationDidBecomeActive:(NSNotification*)notifcation
{
	// For performance reasons, we manually pause/resume the session when saving a recording.
	// If we try to resume the session in the background it will fail. Resume the session here as well to ensure we will succeed.
	[_captureManager resumeCaptureSession];
}

- (void)deviceOrientationDidChange
{
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	// Don't update the reference orientation when the device orientation is face up/down or unknown.
	if (UIDeviceOrientationIsPortrait(orientation) || UIDeviceOrientationIsLandscape(orientation))
		[_captureManager setReferenceOrientation:(AVCaptureVideoOrientation)orientation];
}

#pragma mark - IBActions

- (IBAction)toggleRecording:(id)sender
{
	// Wait for the recording to start/stop before re-enabling the record button.
	self.recordButton.enabled = NO;
		
	if ([_captureManager isRecording])
	{
		// The recordingWill/DidStop delegate methods will fire asynchronously in response to this call
		[_captureManager stopRecording];
	}
	else
	{
		// The recordingWill/DidStart delegate methods will fire asynchronously in response to this call
        [_captureManager startRecording];
	}
}

- (IBAction)toggleLocationUpdateMode:(id)sender
{
	if(_locationUpdateModeButton.selectedSegmentIndex == 0) // Walking - set distance sensitibity to 5 meters
	{
		_captureManager.distanceUpdateInMeters = 5.0;
	}
	else // Driving - set distance sensitivity to 20 meters
	{
		_captureManager.distanceUpdateInMeters = 20.0;
	}
}

#pragma mark - AVCLVideoProcessorDelegate

- (void)recordingWillStart
{
	dispatch_async(dispatch_get_main_queue(), ^{
		self.recordButton.enabled = NO;
		self.recordButton.title = @"Stop";
		self.locationUpdateModeButton.enabled = NO;
		
		// Disable the idle timer while we are recording
		[UIApplication sharedApplication].idleTimerDisabled = YES;
		
		// Make sure we have time to finish saving the movie if the app is backgrounded during recording
		if ([UIDevice currentDevice].multitaskingSupported)
			_backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
	});
}

- (void)recordingDidStart
{
	dispatch_async(dispatch_get_main_queue(), ^{
		// Enable the stop button now that the recording has started
		self.recordButton.enabled = YES;
	});
}

- (void)recordingWillStop
{
	dispatch_async(dispatch_get_main_queue(), ^{
		// Disable until saving to the camera roll is complete
		self.recordButton.title = @"Record";
		self.recordButton.enabled = NO;
		self.locationUpdateModeButton.enabled = NO;
		
		// Pause the capture session so that saving will be as fast as possible.
		// We resume the sesssion in recordingDidStop:
		[_captureManager pauseCaptureSession];
	});
}

- (void)recordingDidStop
{
	dispatch_async(dispatch_get_main_queue(), ^{
		// Enable record and update mode buttons
		self.recordButton.enabled = YES;
		self.locationUpdateModeButton.enabled = YES;
		[self newLocationUpdate:@""]; // clear out the current location label
		
		[UIApplication sharedApplication].idleTimerDisabled = NO;
		
		[_captureManager resumeCaptureSession];
		
		if ([UIDevice currentDevice].multitaskingSupported)
		{
			[[UIApplication sharedApplication] endBackgroundTask:_backgroundRecordingID];
			_backgroundRecordingID = UIBackgroundTaskInvalid;
		}
	});
}

- (void)newLocationUpdate:(NSString *)locationDescription
{
	// Use this method to update the label which indicates the current location
	self.currentLocation.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
	self.currentLocation.text = locationDescription;
}
@end
