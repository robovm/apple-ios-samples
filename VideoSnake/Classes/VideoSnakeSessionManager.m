
/*
     File: VideoSnakeSessionManager.m
 Abstract: The class that creates and manages the AVCaptureSession
  Version: 2.1
 
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

#import "VideoSnakeSessionManager.h"

#import "VideoSnakeOpenGLRenderer.h"

#import "MovieRecorder.h"
#import "MotionSynchronizer.h"

#import <CoreMedia/CMBufferQueue.h>
#import <CoreMedia/CMAudioClock.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/CGImageProperties.h>

#include <objc/runtime.h> // for objc_loadWeak() and objc_storeWeak()

/*
 RETAINED_BUFFER_COUNT is the number of pixel buffers we expect to hold on to from the renderer. This value informs the renderer how to size its buffer pool and how many pixel buffers to preallocate (done in the prepareWithOutputDimensions: method). Preallocation helps to lessen the chance of frame drops in our recording, in particular during recording startup. If we try to hold on to more buffers than RETAINED_BUFFER_COUNT then the renderer will fail to allocate new buffers from its pool and we will drop frames.

 A back of the envelope calculation to arrive at a RETAINED_BUFFER_COUNT of '5':
 - The preview path only has the most recent frame, so this makes the movie recording path the long pole.
 - The movie recorder internally does a dispatch_async to avoid blocking the caller when enqueuing to its internal asset writer.
 - Allow 2 frames of latency to cover the dispatch_async and the -[AVAssetWriterInput appendSampleBuffer:] call.
 - Then we allow for the encoder to retain up to 3 frames. One frame is retained while being encoded/format converted, while the other two are to handle encoder format conversion pipelining and encoder startup latency.

 Really you need to test and measure the latency in your own application pipeline to come up with an appropriate number. 1080p BGRA buffers are quite large, so it's a good idea to keep this number as low as possible.
 */

#define RETAINED_BUFFER_COUNT 5

#define RECORD_AUDIO 0

#define LOG_STATUS_TRANSITIONS 0

typedef NS_ENUM( NSInteger, VideoSnakeRecordingStatus ) {
	VideoSnakeRecordingStatusIdle = 0,
	VideoSnakeRecordingStatusStartingRecording,
	VideoSnakeRecordingStatusRecording,
	VideoSnakeRecordingStatusStoppingRecording,
}; // internal state machine

static CGFloat angleOffsetFromPortraitOrientationToOrientation(AVCaptureVideoOrientation orientation)
{
	CGFloat angle = 0.0;
	
	switch (orientation) {
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

@interface VideoSnakeSessionManager () <AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, MovieRecorderDelegate, MotionSynchronizationDelegate>
{
	__weak id <VideoSnakeSessionManagerDelegate> _delegate; // __weak doesn't actually do anything under non-ARC
	dispatch_queue_t _delegateCallbackQueue;
	
	NSMutableArray *_previousSecondTimestamps;

	AVCaptureSession *_captureSession;
	AVCaptureDevice *_videoDevice;
	AVCaptureConnection *_audioConnection;
	AVCaptureConnection *_videoConnection;
	BOOL _running;
	BOOL _startCaptureSessionOnEnteringForeground;
	id _applicationWillEnterForegroundNotificationObserver;
	
	dispatch_queue_t _sessionQueue;
	dispatch_queue_t _videoDataOutputQueue;
	dispatch_queue_t _motionSyncedVideoQueue;
	
	VideoSnakeOpenGLRenderer *_renderer;
	BOOL _renderingEnabled;
	
	NSURL *_recordingURL;
	VideoSnakeRecordingStatus _recordingStatus;
	
	UIBackgroundTaskIdentifier _pipelineRunningTask;
}

@property (nonatomic, retain) __attribute__((NSObject)) CVPixelBufferRef currentPreviewPixelBuffer;

@property (readwrite) float videoFrameRate;
@property (readwrite) CMVideoDimensions videoDimensions;
@property (nonatomic, readwrite) AVCaptureVideoOrientation videoOrientation;
@property (nonatomic, retain) MotionSynchronizer *motionSynchronizer;

@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;
@property (nonatomic, retain) MovieRecorder *recorder;

@end

@implementation VideoSnakeSessionManager

- (id)init
{
	if (self = [super init]) {
		_previousSecondTimestamps = [[NSMutableArray alloc] init];
		_recordingOrientation = (AVCaptureVideoOrientation)UIDeviceOrientationPortrait;
		
		_recordingURL = [[NSURL alloc] initFileURLWithPath:[NSString pathWithComponents:@[NSTemporaryDirectory(), @"Movie.MOV"]]];
		
		_sessionQueue = dispatch_queue_create( "com.apple.sample.sessionmanager.capture", DISPATCH_QUEUE_SERIAL );
		
		// In a multi-threaded producer consumer system it's generally a good idea to make sure that producers do not get starved of CPU time by their consumers.
		// In this app we start with VideoDataOutput frames on a high priority queue, and downstream consumers use default priority queues.
		// Audio uses a default priority queue because we aren't monitoring it live and just want to get it into the movie.
		// AudioDataOutput can tolerate more latency than VideoDataOutput as its buffers aren't allocated out of a fixed size pool.
		_videoDataOutputQueue = dispatch_queue_create( "com.apple.sample.sessionmanager.video", DISPATCH_QUEUE_SERIAL );
		dispatch_set_target_queue( _videoDataOutputQueue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0) );
		
		_motionSynchronizer = [[MotionSynchronizer alloc] init];
		_motionSyncedVideoQueue = dispatch_queue_create( "com.apple.sample.sessionmanager.motion", DISPATCH_QUEUE_SERIAL );
		[_motionSynchronizer setSynchronizedSampleBufferDelegate:self queue:_motionSyncedVideoQueue];
		
		_renderer = [[VideoSnakeOpenGLRenderer alloc] init];
				
		_pipelineRunningTask = UIBackgroundTaskInvalid;
	}
	return self;
}

- (void)dealloc
{
	objc_storeWeak( &_delegate, nil ); // unregister _delegate as a weak reference
	
	if ( _delegateCallbackQueue )
		[_delegateCallbackQueue release];

	if ( _currentPreviewPixelBuffer )
		CFRelease( _currentPreviewPixelBuffer );
	
	[_previousSecondTimestamps release];
	
	[self teardownCaptureSession];
	
	if ( _sessionQueue )
		[_sessionQueue release];
	
	if ( _videoDataOutputQueue )
		[_videoDataOutputQueue release];
	
	[_renderer release];
	
	[_motionSynchronizer release];
	if ( _motionSyncedVideoQueue )
		[_motionSyncedVideoQueue release];
		
	if ( _outputVideoFormatDescription )
		CFRelease( _outputVideoFormatDescription );
	
	if ( _outputAudioFormatDescription )
		CFRelease( _outputAudioFormatDescription );
	
	[_recorder release];
	[_recordingURL release];
	
	[super dealloc];
}

#pragma mark Delegate

- (void)setDelegate:(id<VideoSnakeSessionManagerDelegate>)delegate callbackQueue:(dispatch_queue_t)delegateCallbackQueue // delegate is weak referenced
{
	if ( delegate && ( delegateCallbackQueue == NULL ) )
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Caller must provide a delegateCallbackQueue" userInfo:nil];
	
	@synchronized( self ) {
		objc_storeWeak( &_delegate, delegate ); // unnecessary under ARC, just assign to _delegate directly
		if ( delegateCallbackQueue != _delegateCallbackQueue  ) {
			if ( delegateCallbackQueue )
				[delegateCallbackQueue retain];
			if ( _delegateCallbackQueue )
				[_delegateCallbackQueue release];
			_delegateCallbackQueue = delegateCallbackQueue;
		}
	}
}

- (id<VideoSnakeSessionManagerDelegate>)delegate
{
	id <VideoSnakeSessionManagerDelegate> delegate = nil;
	@synchronized( self ) {
		delegate = objc_loadWeak( &_delegate ); // unnecessary under ARC, just assign delegate to _delegate directly
	}
	return delegate;
}

#pragma mark Capture Session

- (void)startRunning
{
	dispatch_sync( _sessionQueue, ^{
		[self setupCaptureSession];
		
		[_captureSession startRunning];
		_running = YES;
	});
}

- (void)stopRunning
{
	dispatch_sync( _sessionQueue, ^{
		_running = NO;
		
		// the captureSessionDidStopRunning method will stop recording if necessary as well, but we do it here so that the last video and audio samples are better aligned
		[self stopRecording]; // does nothing if we aren't currently recording
		
		[_captureSession stopRunning];
		
		[self captureSessionDidStopRunning];
		
		[self teardownCaptureSession];
	});
}

- (void)setupCaptureSession
{
	if ( _captureSession )
		return;
	
	_captureSession = [[AVCaptureSession alloc] init];	

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionNotification:) name:nil object:_captureSession];
	_applicationWillEnterForegroundNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication] queue:nil usingBlock:^(NSNotification *note) {
		// Retain self while the capture session is alive by referencing it in this observer block which is tied to the session lifetime
		// Client must stop us running before we can be deallocated
		[self applicationWillEnterForeground];
	}];
	
#if RECORD_AUDIO
	/* Audio */
	AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	AVCaptureDeviceInput *audioIn = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:nil];
	if ([_captureSession canAddInput:audioIn])
		[_captureSession addInput:audioIn];
	[audioIn release];
	
	AVCaptureAudioDataOutput *audioOut = [[AVCaptureAudioDataOutput alloc] init];
	// Put audio on its own queue to ensure that our video processing doesn't cause us to drop audio
	dispatch_queue_t audioCaptureQueue = dispatch_queue_create("com.apple.sample.sessionmanager.audio", DISPATCH_QUEUE_SERIAL);
	[audioOut setSampleBufferDelegate:self queue:audioCaptureQueue];
	[audioCaptureQueue release];
	
	if ([_captureSession canAddOutput:audioOut])
		[_captureSession addOutput:audioOut];
	_audioConnection = [audioOut connectionWithMediaType:AVMediaTypeAudio];
	[audioOut release];
#endif // RECORD_AUDIO
	
	/* Video */
	AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	_videoDevice = videoDevice;
	AVCaptureDeviceInput *videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
	if ([_captureSession canAddInput:videoIn])
		[_captureSession addInput:videoIn];
	[videoIn release];
	
	AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
	[videoOut setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	[videoOut setSampleBufferDelegate:self queue:_videoDataOutputQueue];
	
	// VideoSnake records videos and we prefer not to have any dropped frames in the video recording.
	// By setting alwaysDiscardsLateVideoFrames to NO we ensure that minor fluctuations in system load or in our processing time for a given frame won't cause framedrops.
	// We do however need to ensure that on average we can process frames in realtime.
	// If we were doing preview only we would probably want to set alwaysDiscardsLateVideoFrames to YES.
	[videoOut setAlwaysDiscardsLateVideoFrames:NO];
	
	if ([_captureSession canAddOutput:videoOut])
		[_captureSession addOutput:videoOut];
	_videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
		
	int frameRate;
	CMTime frameDuration = kCMTimeInvalid;
	// For single core systems like iPhone 4 and iPod Touch 4th Generation we use a lower resolution and framerate to maintain real-time performance.
	if ( [[NSProcessInfo processInfo] processorCount] == 1 ) {
		if ( [_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480] )
			_captureSession.sessionPreset = AVCaptureSessionPreset640x480;
		frameRate = 15;
	}
	else {
		_captureSession.sessionPreset = AVCaptureSessionPresetHigh;
		frameRate = 30;
	}
	frameDuration = CMTimeMake( 1, frameRate );

	NSError *error;
	if ([videoDevice lockForConfiguration:&error]) {
		[videoDevice setActiveVideoMaxFrameDuration:frameDuration];
		[videoDevice setActiveVideoMinFrameDuration:frameDuration];
		[videoDevice unlockForConfiguration];
	} else {
		NSLog(@"videoDevice lockForConfiguration returned error %@", error);
	}

	self.videoOrientation = [_videoConnection videoOrientation];
	
	[videoOut release];
	
	/* Motion */
    [self.motionSynchronizer setMotionRate:frameRate * 2];
	[self updateMotionSynchronizerSampleBufferClock];
	
	return;
}

- (void)teardownCaptureSession
{
	if ( _captureSession ) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:_captureSession];
		
		[[NSNotificationCenter defaultCenter] removeObserver:_applicationWillEnterForegroundNotificationObserver];
		_applicationWillEnterForegroundNotificationObserver = nil;
		
		[_captureSession release];
		_captureSession = nil;
	}
}

- (void)captureSessionNotification:(NSNotification *)notification
{
	dispatch_async( _sessionQueue, ^{
		if ( [[notification name] isEqualToString:AVCaptureSessionWasInterruptedNotification] ) {
			NSLog( @"session interrupted" );
			
			[self captureSessionDidStopRunning];
		}
		else if ( [[notification name] isEqualToString:AVCaptureSessionInterruptionEndedNotification] ) {
			NSLog( @"session interruption ended" );
		}
		else if ( [[notification name] isEqualToString:AVCaptureSessionRuntimeErrorNotification] ) {
			[self captureSessionDidStopRunning];
			
			NSError *error = [[notification userInfo] objectForKey:AVCaptureSessionErrorKey];
			if ( error.code == AVErrorDeviceIsNotAvailableInBackground ) {
				NSLog( @"device not available in background" );

				// Since we can't resume running while in the background we need to remember this for next time we come to the foreground
				if ( _running )
					_startCaptureSessionOnEnteringForeground = YES;
			}
			else if ( error.code == AVErrorMediaServicesWereReset ) {
				NSLog( @"media services were reset" );
				[self handleRecoverableCaptureSessionRuntimeError:error];
			}
			else {
				[self handleNonRecoverableCaptureSessionRuntimeError:error];
			}
		}
		else if ( [[notification name] isEqualToString:AVCaptureSessionDidStartRunningNotification] ) {
			NSLog( @"session started running" );
		}
		else if ( [[notification name] isEqualToString:AVCaptureSessionDidStopRunningNotification] ) {
			NSLog( @"session stopped running" );
		}
	});
}

- (void)handleRecoverableCaptureSessionRuntimeError:(NSError *)error
{
	if ( _running ) {
		// This code works around a known issue in iOS where an audio CMClock becomes invalid when media services are reset
		// Make sure there are no sbufs being concurrently appended to the motion synchronizer while we update its clock
		
		if ( error.code == AVErrorMediaServicesWereReset ) {
			dispatch_sync( _videoDataOutputQueue, ^{
				[self updateMotionSynchronizerSampleBufferClock];
			});
		}
		
		[_captureSession startRunning];
	}
}

- (void)handleNonRecoverableCaptureSessionRuntimeError:(NSError *)error
{
	NSLog( @"fatal runtime error %@, code %i", error, (int)error.code );
	
	_running = NO;
	[self teardownCaptureSession];
	
	@synchronized( self ) {
		if ( [self delegate] ) {
			dispatch_async( _delegateCallbackQueue, ^{
				@autoreleasepool {
					[[self delegate] sessionManager:self didStopRunningWithError:error];
				}
			});
		}
	}
}

- (void)captureSessionDidStopRunning
{
	[self stopRecording]; // does nothing if we aren't currently recording
	[self teardownVideoPipeline];
}

- (void)applicationWillEnterForeground
{
	NSLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
	
	dispatch_sync( _sessionQueue, ^{
		if ( _startCaptureSessionOnEnteringForeground ) {
			NSLog( @"-[%@ %@] manually restarting session", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
			
			_startCaptureSessionOnEnteringForeground = NO;
			if ( _running )
				[_captureSession startRunning];
		}
	});
}

#pragma mark Capture Pipeline

- (void)setupVideoPipelineWithInputFormatDescription:(CMFormatDescriptionRef)inputFormatDescription
{
	NSLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
	
	[self videoPipelineWillStartRunning];
	
	[self.motionSynchronizer start];
	
	self.videoDimensions = CMVideoFormatDescriptionGetDimensions( inputFormatDescription );
	[_renderer prepareWithOutputDimensions:self.videoDimensions retainedBufferCountHint:RETAINED_BUFFER_COUNT];
	_renderer.shouldMirrorMotion = (_videoDevice.position == AVCaptureDevicePositionFront); // Account for the fact that front camera preview is mirrored
	self.outputVideoFormatDescription = _renderer.outputFormatDescription;
}

// synchronous, blocks until the pipeline is drained, don't call from within the pipeline
- (void)teardownVideoPipeline
{
	// The session is stopped so we are guaranteed that no new buffers are coming through the video data output.
	// There may be inflight buffers on _videoDataOutputQueue or _motionSyncedVideoQueue however.
	// Synchronize with those queues to guarantee no more buffers are in flight.
	// Once the pipeline is drained we can tear it down safely.

	NSLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
	
	dispatch_sync( _videoDataOutputQueue, ^{
		
		if ( ! self.outputVideoFormatDescription )
			return;
		
		[self.motionSynchronizer stop]; // no new sbufs will be enqueued to _motionSyncedVideoQueue, but some may already be queued
		dispatch_sync( _motionSyncedVideoQueue, ^{
			self.outputVideoFormatDescription = nil;
			[_renderer reset];
			self.currentPreviewPixelBuffer = NULL;
			
			NSLog( @"-[%@ %@] finished teardown", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
			
			[self videoPipelineDidFinishRunning];
		});
	});
}

- (void)updateMotionSynchronizerSampleBufferClock
{
	[self.motionSynchronizer setSampleBufferClock:_captureSession.masterClock];
}

- (void)videoPipelineWillStartRunning
{
	NSLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
	
	NSAssert( _pipelineRunningTask == UIBackgroundTaskInvalid, @"should not have a background task active before the video pipeline starts running" );
	
	_pipelineRunningTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		NSLog( @"video capture pipeline background task expired" );
	}];
}

- (void)videoPipelineDidFinishRunning
{
	NSLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
	
	NSAssert( _pipelineRunningTask != UIBackgroundTaskInvalid, @"should have a background task active when the video pipeline finishes running" );
	
	[[UIApplication sharedApplication] endBackgroundTask:_pipelineRunningTask];
	_pipelineRunningTask = UIBackgroundTaskInvalid;
}

// call under @synchronized( self )
- (void)videoPipelineDidRunOutOfBuffers
{
	// We have run out of buffers.
	// Tell the delegate so that it can flush any cached buffers.
	if ( [self delegate] ) {
		dispatch_async( _delegateCallbackQueue, ^{
			@autoreleasepool {
				[[self delegate] sessionManagerDidRunOutOfPreviewBuffers:self];
			}
		});
	}
}

- (void)setRenderingEnabled:(BOOL)renderingEnabled
{
	@synchronized( _renderer ) {
		_renderingEnabled = renderingEnabled;
	}
}

- (BOOL)renderingEnabled
{
	@synchronized( _renderer ) {
		return _renderingEnabled;
	}
}

// call under @synchronized( self )
- (void)outputPreviewPixelBuffer:(CVPixelBufferRef)previewPixelBuffer
{
	if ( [self delegate] ) {
		// Keep preview latency low by dropping stale frames that have not been picked up by the delegate yet
		self.currentPreviewPixelBuffer = previewPixelBuffer;
		
		dispatch_async( _delegateCallbackQueue, ^{
			@autoreleasepool {
				CVPixelBufferRef currentPreviewPixelBuffer = NULL;
				@synchronized( self ) {
					currentPreviewPixelBuffer = self.currentPreviewPixelBuffer;
					if ( currentPreviewPixelBuffer ) {
						CFRetain( currentPreviewPixelBuffer );
						self.currentPreviewPixelBuffer = NULL;
					}
				}
				if ( currentPreviewPixelBuffer ) {
					[[self delegate] sessionManager:self previewPixelBufferReadyForDisplay:currentPreviewPixelBuffer];
					CFRelease( currentPreviewPixelBuffer );
				}
			}
		});
	}
}

#pragma mark Pipeline Stage Output Callbacks

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	// For video the basic sample flow is:
	//	1) Frame received from video data output on _videoDataOutputQueue via captureOutput:didOutputSampleBuffer:fromConnection: (this method)
	//	2) Frame sent to motion synchronizer to be asynchronously correlated with motion data
	//	3) Frame and correlated motion data received on _motionSyncedVideoQueue via motionSynchronizer:didOutputSampleBuffer:withMotion:
	//	4) Frame and motion data rendered via VideoSnakeOpenGLRenderer while running on _motionSyncedVideoQueue
	//	5) Rendered frame sent to the delegate for previewing
	//	6) Rendered frame sent to the movie recorder if recording is enabled

	// For audio the basic sample flow is:
	//	1) Audio sample buffer received from audio data output on an audio specific serial queue via captureOutput:didOutputSampleBuffer:fromConnection: (this method)
	//	2) Audio sample buffer sent to the movie recorder if recording is enabled

	CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
	
	if ( connection == _videoConnection ) {
		if ( self.outputVideoFormatDescription == nil ) {
			[self setupVideoPipelineWithInputFormatDescription:formatDescription];
		}
		
		[self.motionSynchronizer appendSampleBufferForSynchronization:sampleBuffer];
	}
	else if ( connection == _audioConnection ) {
		self.outputAudioFormatDescription = formatDescription;
		
		@synchronized( self ) {
			if ( _recordingStatus == VideoSnakeRecordingStatusRecording ) {
				[self.recorder appendAudioSampleBuffer:sampleBuffer];
			}
		}
	}
}

- (void)motionSynchronizer:(MotionSynchronizer *)synchronizer didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer withMotion:(CMDeviceMotion *)motion
{
	CVPixelBufferRef renderedPixelBuffer = NULL;
	CMTime timestamp = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );
	
	[self calculateFramerateAtTimestamp:timestamp];
	
	// We must not use the GPU while running in the background.
	// setRenderingEnabled: takes the same lock so the caller can guarantee no GPU usage once the setter returns.
	@synchronized( _renderer ) {
		if ( _renderingEnabled ) {
			CVPixelBufferRef sourcePixelBuffer = CMSampleBufferGetImageBuffer( sampleBuffer );
			renderedPixelBuffer = [_renderer copyRenderedPixelBuffer:sourcePixelBuffer motion:motion];
		}
		else {
			return;
		}
	}
	
	@synchronized( self ) {
		if ( renderedPixelBuffer ) {
			[self outputPreviewPixelBuffer:renderedPixelBuffer];
			
			if ( _recordingStatus == VideoSnakeRecordingStatusRecording ) {
				[self.recorder appendVideoPixelBuffer:renderedPixelBuffer withPresentationTime:timestamp];
			}
			
			CFRelease( renderedPixelBuffer );
		}
		else {
			[self videoPipelineDidRunOutOfBuffers];
		}
	}
}

#pragma mark Recording

- (void)startRecording
{
	@synchronized( self ) {
		if ( _recordingStatus != VideoSnakeRecordingStatusIdle ) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Already recording" userInfo:nil];
			return;
		}
		
		[self transitionToRecordingStatus:VideoSnakeRecordingStatusStartingRecording error:nil];
	}
	
	MovieRecorder *recorder = [[[MovieRecorder alloc] initWithURL:_recordingURL] autorelease];
	
#if RECORD_AUDIO
	[recorder addAudioTrackWithSourceFormatDescription:self.outputAudioFormatDescription];
#endif // RECORD_AUDIO
    
	CGAffineTransform videoTransform = [self transformFromVideoBufferOrientationToOrientation:self.recordingOrientation withAutoMirroring:NO]; // Front camera recording shouldn't be mirrored

	[recorder addVideoTrackWithSourceFormatDescription:self.outputVideoFormatDescription transform:videoTransform];
	
	dispatch_queue_t callbackQueue = dispatch_queue_create( "com.apple.sample.sessionmanager.recordercallback", DISPATCH_QUEUE_SERIAL ); // guarantee ordering of callbacks with a serial queue
	[recorder setDelegate:self callbackQueue:callbackQueue];
	[callbackQueue release];
	self.recorder = recorder;
	
	[recorder prepareToRecord]; // asynchronous, will call us back with recorderDidFinishPreparing: or recorder:didFailWithError: when done
}

- (void)stopRecording
{
	@synchronized( self ) {
		if ( _recordingStatus != VideoSnakeRecordingStatusRecording ) {
			return;
		}
		
		[self transitionToRecordingStatus:VideoSnakeRecordingStatusStoppingRecording error:nil];
	}
	
	[self.recorder finishRecording]; // asynchronous, will call us back with recorderDidFinishRecording: or recorder:didFailWithError: when done
}

#pragma mark MovieRecorder Delegate

- (void)movieRecorderDidFinishPreparing:(MovieRecorder *)recorder
{
	@synchronized( self ) {
		if ( _recordingStatus != VideoSnakeRecordingStatusStartingRecording ) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Expected to be in StartingRecording state" userInfo:nil];
			return;
		}
		
		[self transitionToRecordingStatus:VideoSnakeRecordingStatusRecording error:nil];
	}
}

- (void)movieRecorder:(MovieRecorder *)recorder didFailWithError:(NSError *)error
{
	@synchronized( self ) {
		self.recorder = nil;
		[self transitionToRecordingStatus:VideoSnakeRecordingStatusIdle error:error];
	}
}

- (void)movieRecorderDidFinishRecording:(MovieRecorder *)recorder
{
	@synchronized( self ) {
		if ( _recordingStatus != VideoSnakeRecordingStatusStoppingRecording ) {
			@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Expected to be in StoppingRecording state" userInfo:nil];
			return;
		}
		
		// No state transition, we are still in the process of stopping.
		// We will be stopped once we save to the assets library.
	}
	
	self.recorder = nil;
	
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	[library writeVideoAtPathToSavedPhotosAlbum:_recordingURL completionBlock:^(NSURL *assetURL, NSError *error) {
		
		[[NSFileManager defaultManager] removeItemAtURL:_recordingURL error:NULL];
		
 		@synchronized( self ) {
			if ( _recordingStatus != VideoSnakeRecordingStatusStoppingRecording ) {
				@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Expected to be in StoppingRecording state" userInfo:nil];
				return;
			}
			[self transitionToRecordingStatus:VideoSnakeRecordingStatusIdle error:error];
		}
	}];
	[library release];
}

#pragma mark Recording State Machine

// call under @synchonized( self )
- (void)transitionToRecordingStatus:(VideoSnakeRecordingStatus)newStatus error:(NSError*)error
{
	SEL delegateSelector = NULL;
	VideoSnakeRecordingStatus oldStatus = _recordingStatus;
	_recordingStatus = newStatus;
	
#if LOG_STATUS_TRANSITIONS
	NSLog( @"VideoSnakeSessionManager recording state transition: %@->%@", [self stringForRecordingStatus:oldStatus], [self stringForRecordingStatus:newStatus] );
#endif
	
	if ( newStatus != oldStatus ) {
		if ( error && ( newStatus == VideoSnakeRecordingStatusIdle ) ) {
			delegateSelector = @selector(sessionManager:recordingDidFailWithError:);
		}
		else {
			error = nil; // only the above delegate method takes an error
			if ( ( oldStatus == VideoSnakeRecordingStatusStartingRecording ) && ( newStatus == VideoSnakeRecordingStatusRecording ) )
				delegateSelector = @selector(sessionManagerRecordingDidStart:);
			else if ( ( oldStatus == VideoSnakeRecordingStatusRecording ) && ( newStatus == VideoSnakeRecordingStatusStoppingRecording ) )
				delegateSelector = @selector(sessionManagerRecordingWillStop:);
			else if ( ( oldStatus == VideoSnakeRecordingStatusStoppingRecording ) && ( newStatus == VideoSnakeRecordingStatusIdle ) )
				delegateSelector = @selector(sessionManagerRecordingDidStop:);
		}
	}
	
	if ( delegateSelector && [self delegate] ) {
		dispatch_async( _delegateCallbackQueue, ^{
			@autoreleasepool {
				if ( error )
					[[self delegate] performSelector:delegateSelector withObject:self withObject:error];
				else
					[[self delegate] performSelector:delegateSelector withObject:self];
			}
		});
	}
}

#if LOG_STATUS_TRANSITIONS

- (NSString*)stringForRecordingStatus:(VideoSnakeRecordingStatus)status
{
	NSString *statusString = nil;
	
	switch ( status ) {
		case VideoSnakeRecordingStatusIdle:
			statusString = @"Idle";
			break;
		case VideoSnakeRecordingStatusStartingRecording:
			statusString = @"StartingRecording";
			break;
		case VideoSnakeRecordingStatusRecording:
			statusString = @"Recording";
			break;
		case VideoSnakeRecordingStatusStoppingRecording:
			statusString = @"StoppingRecording";
			break;
		default:
			statusString = @"Unknown";
			break;
	}
	return statusString;
}

#endif // LOG_STATUS_TRANSITIONS

#pragma mark Utilities

// Auto mirroring: Front camera is mirrored; back camera isn't 
- (CGAffineTransform)transformFromVideoBufferOrientationToOrientation:(AVCaptureVideoOrientation)orientation withAutoMirroring:(BOOL)mirror
{
	CGAffineTransform transform = CGAffineTransformIdentity;
		
	// Calculate offsets from an arbitrary reference orientation (portrait)
	CGFloat orientationAngleOffset = angleOffsetFromPortraitOrientationToOrientation( orientation );
	CGFloat videoOrientationAngleOffset = angleOffsetFromPortraitOrientationToOrientation( self.videoOrientation );
	
	// Find the difference in angle between the desired orientation and the video orientation
	CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
	transform = CGAffineTransformMakeRotation(angleOffset);

	if ( _videoDevice.position == AVCaptureDevicePositionFront ) {
		if ( mirror ) {
			transform = CGAffineTransformScale(transform, -1, 1);
		}
		else {
			if ( UIInterfaceOrientationIsPortrait(orientation) ) {
				transform = CGAffineTransformRotate(transform, M_PI);
			}
		}
	}
	
	return transform;
}

- (void)calculateFramerateAtTimestamp:(CMTime)timestamp
{
	[_previousSecondTimestamps addObject:[NSValue valueWithCMTime:timestamp]];
	
	CMTime oneSecond = CMTimeMake( 1, 1 );
	CMTime oneSecondAgo = CMTimeSubtract( timestamp, oneSecond );
	
	while( CMTIME_COMPARE_INLINE( [[_previousSecondTimestamps objectAtIndex:0] CMTimeValue], <, oneSecondAgo ) )
		[_previousSecondTimestamps removeObjectAtIndex:0];
	
	if ( [_previousSecondTimestamps count] > 1 ) {
		const Float64 duration = CMTimeGetSeconds(CMTimeSubtract([[_previousSecondTimestamps lastObject] CMTimeValue], [[_previousSecondTimestamps objectAtIndex:0] CMTimeValue]));
		const float newRate = (float) ([_previousSecondTimestamps count] - 1) / duration;
		self.videoFrameRate = newRate;
	}
}

@end
