/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class creates and manages the AV capture session and CLLocationManager, to gather location data, and writes out this data using asset writer. 
  
 */

#import "AAPLCaptureManager.h"
#import <CoreMedia/CoreMedia.h>
#import <CoreMedia/CMMetadata.h>

@import MobileCoreServices;
@import AssetsLibrary;
@import CoreLocation;


@interface AAPLCaptureManager () <AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, CLLocationManagerDelegate>
{
	AVCaptureSession					*_captureSession;
	AVCaptureConnection					*_audioConnection;
	AVCaptureConnection					*_videoConnection;
	
	NSURL								*_movieURL;
	AVAssetWriter						*_assetWriter;
	AVAssetWriterInput					*_assetWriterAudioIn;
	AVAssetWriterInput					*_assetWriterVideoIn;
	AVAssetWriterInput					*_assetWriterMetadataIn;
	AVAssetWriterInputMetadataAdaptor	*_assetWriterMetadataAdaptor;
	
	dispatch_queue_t					_movieWritingQueue;
	// Only accessed on movie writing queue
    BOOL								_readyToRecordAudio;
    BOOL								_readyToRecordVideo;
	BOOL								_readyToRecordMetadata;
	BOOL								_recordingWillBeStarted;
	BOOL								_recordingWillBeStopped;
}

@property (nonatomic) CLLocationManager			*locationManager;
@property (readwrite, getter=isRecording) BOOL	recording;
@property (readwrite) AVCaptureVideoOrientation videoOrientation;

@end

@implementation AAPLCaptureManager

- (id)init
{
    if (self = [super init])
	{
		// Initialize CLLocationManager to receive updates in current location
		self.locationManager = [[CLLocationManager alloc] init];
		self.locationManager.delegate = self;
		[self.locationManager requestWhenInUseAuthorization];
		self.referenceOrientation = AVCaptureVideoOrientationPortrait;
		
        // The temporary path for the video before saving it to the photo album
        _movieURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"Movie.MOV"]];
    }
    return self;
}

#pragma mark - Asset writing

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType
{
	if ( _assetWriter.status == AVAssetWriterStatusUnknown )
	{
		// If the asset writer status is unknown, implies writing hasn't started yet, hence start writing with start time as the buffer's presentation timestamp
		if ([_assetWriter startWriting])
			[_assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
		else
			[self showError:_assetWriter.error];
	}
	
	if ( _assetWriter.status == AVAssetWriterStatusWriting )
	{
		// If the asset writer status is writing, append sample buffer to its corresponding asset writer input
		if (mediaType == AVMediaTypeVideo)
		{
			if (_assetWriterVideoIn.readyForMoreMediaData)
			{
				if (![_assetWriterVideoIn appendSampleBuffer:sampleBuffer])
					[self showError:_assetWriter.error];
			}
		}
		else if (mediaType == AVMediaTypeAudio)
		{
			if (_assetWriterAudioIn.readyForMoreMediaData)
			{
				if (![_assetWriterAudioIn appendSampleBuffer:sampleBuffer])
					[self showError:_assetWriter.error];
			}
		}
	}
}

- (BOOL)setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription
{
	// Create audio output settings dictionary which would be used to configure asset writer input
	const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
	size_t aclSize = 0;
	const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
	
	NSData *currentChannelLayoutData = nil;
	// AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
	if ( currentChannelLayout && aclSize > 0 )
		currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
	else
		currentChannelLayoutData = [NSData data];
	
	NSDictionary *audioCompressionSettings = @{AVFormatIDKey : [NSNumber numberWithInteger:kAudioFormatMPEG4AAC],
											   AVSampleRateKey : [NSNumber numberWithFloat:currentASBD->mSampleRate],
											   AVEncoderBitRatePerChannelKey : [NSNumber numberWithInt:64000],
											   AVNumberOfChannelsKey : [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame],
											   AVChannelLayoutKey : currentChannelLayoutData};
	
	if ([_assetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio])
	{
		// Intialize asset writer audio input with the above created settings dictionary
		_assetWriterAudioIn = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
		_assetWriterAudioIn.expectsMediaDataInRealTime = YES;
		
		// Add asset writer input to asset writer
		if ([_assetWriter canAddInput:_assetWriterAudioIn])
		{
			[_assetWriter addInput:_assetWriterAudioIn];
		}
		else
		{
			NSLog(@"Couldn't add asset writer audio input.");
			return NO;
		}
	}
	else
	{
		NSLog(@"Couldn't apply audio output settings.");
		return NO;
	}
	
	return YES;
}

- (BOOL)setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription
{
	// Create video output settings dictionary which would be used to configure asset writer input
	CGFloat bitsPerPixel;
	CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
	NSUInteger numPixels = dimensions.width * dimensions.height;
	NSUInteger bitsPerSecond;
	
	// Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
	if ( numPixels < (640 * 480) )
		bitsPerPixel = 4.05; // This bitrate matches the quality produced by AVCaptureSessionPresetMedium or Low.
	else
		bitsPerPixel = 11.4; // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
	
	bitsPerSecond = numPixels * bitsPerPixel;
	
	NSDictionary *videoCompressionSettings = @{AVVideoCodecKey : AVVideoCodecH264,
											   AVVideoWidthKey : [NSNumber numberWithInteger:dimensions.width],
											   AVVideoHeightKey : [NSNumber numberWithInteger:dimensions.height],
											   AVVideoCompressionPropertiesKey : @{ AVVideoAverageBitRateKey : [NSNumber numberWithInteger:bitsPerSecond],
																					AVVideoMaxKeyFrameIntervalKey :[NSNumber numberWithInteger:30]}};
	
	if ([_assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo])
	{
		// Intialize asset writer video input with the above created settings dictionary
		_assetWriterVideoIn = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
		_assetWriterVideoIn.expectsMediaDataInRealTime = YES;
		_assetWriterVideoIn.transform = [self transformFromCurrentVideoOrientationToOrientation:self.referenceOrientation];
		
		// Add asset writer input to asset writer
		if ([_assetWriter canAddInput:_assetWriterVideoIn])
		{
			[_assetWriter addInput:_assetWriterVideoIn];
		}
		else
		{
			NSLog(@"Couldn't add asset writer video input.");
			return NO;
		}
	}
	else
	{
		NSLog(@"Couldn't apply video output settings.");
		return NO;
	}
	
	return YES;
}

- (BOOL)setupAssetWriterMetadataInputAndMetadataAdaptor
{
	// All combinations of identifiers, data types and extended language tags that will be appended to the metadata adaptor must form the specifications dictionary
	CMFormatDescriptionRef metadataFormatDescription = NULL;
	NSArray *specifications = @[@{(__bridge NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier : (__bridge NSString *)kCMMetadataIdentifier_QuickTimeMetadataLocation_ISO6709,
						 (__bridge NSString *)kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType : (__bridge NSString *)kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709}];
	
	// Create metadata format description with the above created specifications which will be used to configure asset writer input
	OSStatus err = CMMetadataFormatDescriptionCreateWithMetadataSpecifications(kCFAllocatorDefault, kCMMetadataFormatType_Boxed, (__bridge CFArrayRef)specifications, &metadataFormatDescription);
	if (!err)
	{
		// Intialize asset writer video input with the above created specifications as source hint for the type of metadata to expect
		_assetWriterMetadataIn = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeMetadata outputSettings:nil sourceFormatHint:metadataFormatDescription];
		// Initialize metadata adaptor with the metadata input with the expected source hint
		_assetWriterMetadataAdaptor = [AVAssetWriterInputMetadataAdaptor assetWriterInputMetadataAdaptorWithAssetWriterInput:_assetWriterMetadataIn];
		_assetWriterMetadataIn.expectsMediaDataInRealTime = YES;
		
		// Add asset writer input to asset writer
		if ([_assetWriter canAddInput:_assetWriterMetadataIn])
		{
			[_assetWriter addInput:_assetWriterMetadataIn];
		}
		else
		{
			NSLog(@"Couldn't add asset writer metadata input.");
			return NO;
		}
	}
	else
	{
		NSLog(@"Failed to create format description with metadata specification: %@", specifications);
		return NO;
	}
	
	return YES;
}

- (void)startRecording
{
	[self resumeCaptureSession];
	[self.locationManager startUpdatingLocation];
	
	dispatch_async(_movieWritingQueue, ^{
		
		if (_recordingWillBeStarted || self.recording)
			return;
		
		_recordingWillBeStarted = YES;
		
		// recordingDidStart is called from captureOutput:didOutputSampleBuffer:fromConnection: once the asset writer is setup
		[self.delegate recordingWillStart];
		
		// Remove the file if one with the same name already exists
		[self removeFile:_movieURL];
		
		// Create an asset writer
		NSError *error;
		_assetWriter = [[AVAssetWriter alloc] initWithURL:_movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
		if (error)
			[self showError:error];
	});
}

- (void)stopRecording
{
	[self pauseCaptureSession];
	[self.locationManager stopUpdatingLocation];
	
	dispatch_async(_movieWritingQueue, ^{
		
		if (_recordingWillBeStopped || !self.recording)
			return;
		
		_recordingWillBeStopped = YES;
		
		// recordingDidStop is called from saveMovieToCameraRoll
		[self.delegate recordingWillStop];
		
		[_assetWriter finishWritingWithCompletionHandler:^()
		{
			AVAssetWriterStatus completionStatus = _assetWriter.status;
			switch (completionStatus)
			{
				case AVAssetWriterStatusCompleted:
				{
					// Save the movie stored in the temp folder into camera roll.
					_readyToRecordVideo = NO;
					_readyToRecordAudio = NO;
					_readyToRecordMetadata = NO;
					_assetWriter = nil;
					[self saveMovieToCameraRoll];
					break;
				}
				case AVAssetWriterStatusFailed:
				{
					[self showError:_assetWriter.error];
					break;
				}
				default:
					break;
			}
		}];
	});
}

#pragma mark - CLLocationManager

- (void)setDistanceUpdateInMeters:(CGFloat)distanceUpdateInMeters
{
	self.locationManager.distanceFilter = distanceUpdateInMeters;
}

- (CGFloat)distanceUpdateInMeters
{
	return self.locationManager.distanceFilter;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	for (CLLocation *newLocation in locations)
	{
		if (!newLocation)
			continue;
		
		// Disregard location updates that aren't accurate to within 1000 meters.
		if (newLocation.horizontalAccuracy > 1000.)
			continue;
		
		// Test the age of the location measurement to determine if the measurement is cached
		if (-([newLocation.timestamp timeIntervalSinceNow]) > 5.)
			continue;
		
		dispatch_async(_movieWritingQueue, ^{
			if (_assetWriter)
			{
				if (_assetWriter.status == AVAssetWriterStatusWriting)
				{
					AVMutableMetadataItem *metadataItem = [AVMutableMetadataItem metadataItem];
					metadataItem.identifier = AVMetadataIdentifierQuickTimeMetadataLocationISO6709;
					metadataItem.dataType = (__bridge NSString *)kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709;
					
					// CoreLocation objects contain altitude information as well
					// If you need to store an ISO 6709 notation which includes altitude too, append it at the end of the string below
					NSString *iso6709Notation = [NSString stringWithFormat:@"%+08.4lf%+09.4lf/", newLocation.coordinate.latitude, newLocation.coordinate.longitude];
					metadataItem.value = iso6709Notation;
					
					// Convert location time to movie time
					CMTime locationMovieTime = CMTimeConvertScale([self movieTimeForLocationTime:newLocation.timestamp], 1000, kCMTimeRoundingMethod_Default);
					
					AVTimedMetadataGroup *newGroup = [[AVTimedMetadataGroup alloc] initWithItems:@[metadataItem] timeRange:CMTimeRangeMake(locationMovieTime, kCMTimeInvalid)];
					
					if (_assetWriterMetadataIn.readyForMoreMediaData)
					{
						if (![_assetWriterMetadataAdaptor appendTimedMetadataGroup:newGroup])
						{
							[self showError:_assetWriter.error];
						}
						else
						{
							[self.delegate newLocationUpdate:iso6709Notation];
						}
					}
				}
			}
		});
	}
}

#pragma mark - Capture

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	CFRetain(sampleBuffer);
	dispatch_async(_movieWritingQueue, ^{
		if (_assetWriter)
		{
			BOOL wasReadyToRecord = [self inputsReadyToRecord];
			
			if (connection == _videoConnection)
			{
				// Initialize the video input if this is not done yet
				if (!_readyToRecordVideo)
					_readyToRecordVideo = [self setupAssetWriterVideoInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
				
				// Write video data to file only when all the inputs are ready
				if ([self inputsReadyToRecord])
					[self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo];
			}
			else if (connection == _audioConnection)
			{
				// Initialize the audio input if this is not done yet
				if (!_readyToRecordAudio)
					_readyToRecordAudio = [self setupAssetWriterAudioInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
				
				// Write audio data to file only when all the inputs are ready
				if ([self inputsReadyToRecord])
					[self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio];
			}
			
			// Initialize the metadata input since capture is about to setup/ already initialized video and audio inputs
			if (!_readyToRecordMetadata)
				_readyToRecordMetadata = [self setupAssetWriterMetadataInputAndMetadataAdaptor];
			
			BOOL isReadyToRecord = [self inputsReadyToRecord];
			
			if (!wasReadyToRecord && isReadyToRecord)
			{
				_recordingWillBeStarted = NO;
				self.recording = YES;
				[self.delegate recordingDidStart];
			}
		}
		CFRelease(sampleBuffer);
	});
}

- (BOOL)inputsReadyToRecord
{
	// Check if all inputs are ready to begin recording.
	return (_readyToRecordAudio && _readyToRecordVideo && _readyToRecordMetadata);
}

- (AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
        if (device.position == position)
            return device;
    
    return nil;
}

- (AVCaptureDevice *)audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if (devices.count > 0)
        return [devices firstObject];
    
    return nil;
}

- (BOOL)setupCaptureSession
{
    /*
	 * Create capture session
	 */
    _captureSession = [[AVCaptureSession alloc] init];
    
    /*
	 * Create audio connection
	 */
    AVCaptureDeviceInput *audioIn = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
    if ([_captureSession canAddInput:audioIn])
        [_captureSession addInput:audioIn];

	AVCaptureAudioDataOutput *audioOut = [[AVCaptureAudioDataOutput alloc] init];
	dispatch_queue_t audioCaptureQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
	[audioOut setSampleBufferDelegate:self queue:audioCaptureQueue];

	if ([_captureSession canAddOutput:audioOut])
		[_captureSession addOutput:audioOut];
	_audioConnection = [audioOut connectionWithMediaType:AVMediaTypeAudio];

	/*
	 * Create video connection
	 */
    AVCaptureDeviceInput *videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:[self videoDeviceWithPosition:AVCaptureDevicePositionBack] error:nil];
    if ([_captureSession canAddInput:videoIn])
        [_captureSession addInput:videoIn];
    
	AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
	[videoOut setAlwaysDiscardsLateVideoFrames:YES];
	[videoOut setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
	dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
	[videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];

	if ([_captureSession canAddOutput:videoOut])
		[_captureSession addOutput:videoOut];
	_videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
	self.videoOrientation = _videoConnection.videoOrientation;
	
	if([self.session canSetSessionPreset:AVCaptureSessionPreset640x480])
		[self.session setSessionPreset:AVCaptureSessionPreset640x480]; // Lower video resolution to decrease recorded movie size
    
	return YES;
}

- (void)setupAndStartCaptureSession
{
	// Create serial queue for movie writing
	_movieWritingQueue = dispatch_queue_create("Movie Writing Queue", DISPATCH_QUEUE_SERIAL);
	
    if (!_captureSession)
		[self setupCaptureSession];
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionStoppedRunningNotification:) name:AVCaptureSessionDidStopRunningNotification object:_captureSession];
	
	if (!_captureSession.isRunning)
		[_captureSession startRunning];
}

- (void)pauseCaptureSession
{
	if (_captureSession.isRunning)
		[_captureSession stopRunning];
}

- (void)resumeCaptureSession
{
	if (!_captureSession.isRunning)
		[_captureSession startRunning];
}

- (void)captureSessionStoppedRunningNotification:(NSNotification *)notification
{
	dispatch_async(_movieWritingQueue, ^{
		if ([self isRecording])
		{
			[self stopRecording];
		}
	});
}

- (void)stopAndTearDownCaptureSession
{
    [_captureSession stopRunning];
	[self.locationManager stopUpdatingLocation];
	self.locationManager.delegate = nil;
	if (_captureSession)
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStopRunningNotification object:_captureSession];
}

#pragma mark - Utilities

- (void)saveMovieToCameraRoll
{
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	[library writeVideoAtPathToSavedPhotosAlbum:_movieURL
								completionBlock:^(NSURL *assetURL, NSError *error)
	 {
		 if (error)
			 [self showError:error];
		 else
			 [self removeFile:_movieURL];
		 
		 dispatch_async(_movieWritingQueue, ^{
			_recordingWillBeStopped = NO;
			self.recording = NO;
			[self.delegate recordingDidStop];
		});
	 }];
}

- (void)removeFile:(NSURL *)fileURL
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filePath = fileURL.path;
	if ([fileManager fileExistsAtPath:filePath])
	{
		NSError *error;
		BOOL success = [fileManager removeItemAtPath:filePath error:&error];
		if (!success)
			[self showError:error];
	}
}

- (CMTime)cmTimeForNSDate:(NSDate *)date
{
	CMTime now = CMClockGetTime(CMClockGetHostTimeClock());
	NSTimeInterval elapsed = -(date.timeIntervalSinceNow); // this will be a negative number if date was in the past (it should be).
	CMTime eventTime = CMTimeSubtract(now, CMTimeMake(elapsed * now.timescale, now.timescale));
	return eventTime;
}

- (CMTime)movieTimeForLocationTime:(NSDate *)date
{
	CMTime locationTime = [self cmTimeForNSDate:date];
	CMTime locationMovieTime = CMSyncConvertTime(locationTime, CMClockGetHostTimeClock(), _captureSession.masterClock);
	
	return locationMovieTime;
}

- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
	CGFloat angle = 0.0;
	
	switch (orientation)
	{
		case AVCaptureVideoOrientationPortrait:
			angle = 0.0;
			break;
		case AVCaptureVideoOrientationPortraitUpsideDown:
			angle = M_PI;
			break;
		case AVCaptureVideoOrientationLandscapeRight:
			angle = -M_PI_2;
			break;
		case AVCaptureVideoOrientationLandscapeLeft:
			angle = M_PI_2;
			break;
		default:
			break;
	}
	
	return angle;
}

- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
	CGAffineTransform transform = CGAffineTransformIdentity;
	
	// Calculate offsets from an arbitrary reference orientation (portrait)
	CGFloat orientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:orientation];
	CGFloat videoOrientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:self.videoOrientation];
	
	// Find the difference in angle between the passed in orientation and the current video orientation
	CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
	transform = CGAffineTransformMakeRotation(angleOffset);
	
	return transform;
}

- (AVCaptureSession *)session
{
	return _captureSession;
}

#pragma mark - Error Handling

- (void)showError:(NSError *)error
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void)
	{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                            message:error.localizedFailureReason
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

@end
