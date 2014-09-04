/*
     File: StopNGoViewController.m
 Abstract: Document that captures stills to a QuickTime movie
  Version: 1.0
 
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
 
#import "StopNGoViewController.h"
#include <mach/mach_time.h>
#import <AssetsLibrary/AssetsLibrary.h>
@implementation StopNGoViewController

@synthesize previewView, fpsSlider, startFinishButton, takePictureButton;

- (BOOL)setupAVCapture
{
	NSError *error = nil;
    // 5 fps - taking 5 pictures will equal 1 second of video
	frameDuration = CMTimeMakeWithSeconds(1./5., 90000); 
	
	AVCaptureSession *session = [AVCaptureSession new];
	[session setSessionPreset:AVCaptureSessionPresetHigh];
	
	// Select a video device, make an input
	AVCaptureDevice *backCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
	if (error)
		return NO;
	if ([session canAddInput:input])
		[session addInput:input];
	
	// Make a still image output
	stillImageOutput = [AVCaptureStillImageOutput new];
	if ([session canAddOutput:stillImageOutput])
		[session addOutput:stillImageOutput];
	
	// Make a preview layer so we can see the visual output of an AVCaptureSession
	AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
	[previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
	[previewLayer setFrame:[previewView bounds]];
	
    // add the preview layer to the hierarchy
    CALayer *rootLayer = [previewView layer];
	[rootLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	[rootLayer addSublayer:previewLayer];
	
    // start the capture session running, note this is an async operation
    // status is provided via notifications such as AVCaptureSessionDidStartRunningNotification/AVCaptureSessionDidStopRunningNotification
    [session startRunning];
	
	return YES;
}

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

- (BOOL)setupAssetWriterForURL:(NSURL *)fileURL formatDescription:(CMFormatDescriptionRef)formatDescription
{
    // allocate the writer object with our output file URL
	NSError *error = nil;
	assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:AVFileTypeQuickTimeMovie error:&error];
	if (error)
		return NO;
	
    // initialized a new input for video to receive sample buffers for writing
    // passing nil for outputSettings instructs the input to pass through appended samples, doing no processing before they are written
	assetWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:nil];
	[assetWriterInput setExpectsMediaDataInRealTime:YES];
	if ([assetWriter canAddInput:assetWriterInput])
		[assetWriter addInput:assetWriterInput];
	
    // specify the prefered transform for the output file
	CGFloat rotationDegrees;
	switch ([[UIDevice currentDevice] orientation]) { 
		case UIDeviceOrientationPortraitUpsideDown:
			rotationDegrees = -90.;
			break;
		case UIDeviceOrientationLandscapeLeft: // no rotation
			rotationDegrees = 0.;
			break;
		case UIDeviceOrientationLandscapeRight:
			rotationDegrees = 180.;
			break;
		case UIDeviceOrientationPortrait:
		case UIDeviceOrientationUnknown:
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
		default:
			rotationDegrees = 90.;
			break;
	}
	CGFloat rotationRadians = DegreesToRadians(rotationDegrees);
	[assetWriterInput setTransform:CGAffineTransformMakeRotation(rotationRadians)];
	
    // initiates a sample-writing at time 0
	nextPTS = kCMTimeZero;
	[assetWriter startWriting];
	[assetWriter startSessionAtSourceTime:nextPTS];
	
    return YES;
}

- (IBAction)takePicture:(id)sender
{
    // initiate a still image capture, return immediately
    // the completionHandler is called when a sample buffer has been captured
	AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
	[stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection 
		completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *__strong error) {
		  
          // set up the AVAssetWriter using the format description from the first sample buffer captured
          if ( !assetWriter ) {
			  outputURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%llu.mov", NSTemporaryDirectory(), mach_absolute_time()]];
			  //NSLog(@"Writing movie to \"%@\"", outputURL);
			  CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(imageDataSampleBuffer);
			  if ( NO == [self setupAssetWriterForURL:outputURL formatDescription:formatDescription] )
				  return;
		  }
          
		  // re-time the sample buffer - in this sample frameDuration is set to 5 fps
		  CMSampleTimingInfo timingInfo = kCMTimingInfoInvalid;
		  timingInfo.duration = frameDuration;
		  timingInfo.presentationTimeStamp = nextPTS;
		  CMSampleBufferRef sbufWithNewTiming = NULL;
		  OSStatus err = CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, 
															   imageDataSampleBuffer, 
															   1, // numSampleTimingEntries
															   &timingInfo, 
															   &sbufWithNewTiming);
		  if (err)
			  return;
		  
           // append the sample buffer if we can and increment presnetation time
		  if ( [assetWriterInput isReadyForMoreMediaData] ) {
			  if ([assetWriterInput appendSampleBuffer:sbufWithNewTiming]) {
				  nextPTS = CMTimeAdd(frameDuration, nextPTS);
			  }
			  else {
				  NSError *error = [assetWriter error];
				  NSLog(@"failed to append sbuf: %@", error);
			  }
		  }
          
          // release the copy of the sample buffer we made
		  CFRelease(sbufWithNewTiming);
		}];
}

- (void)saveMovieToCameraRoll
{
    // save the movie to the camera roll
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	//NSLog(@"writing \"%@\" to photos album", outputURL);
	[library writeVideoAtPathToSavedPhotosAlbum:outputURL
								completionBlock:^(NSURL *assetURL, NSError *error) {
									if (error) {
										NSLog(@"assets library failed (%@)", error);
									}
									else {
										[[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
										if (error)
											NSLog(@"Couldn't remove temporary movie file \"%@\"", outputURL);
									}
									outputURL = nil;
								}];
}

- (IBAction)startStop:(id)sender
{
	if (started) {
		if (assetWriter) {
			[assetWriterInput markAsFinished];
			[assetWriter finishWriting];
			assetWriterInput = nil;
			assetWriter = nil;
			[self saveMovieToCameraRoll];
		}
		[sender setTitle:@"Start"];
		[takePictureButton setEnabled:NO];
	}
	else {
		[sender setTitle:@"Finish"];
		[takePictureButton setEnabled:YES];
		
	}
	started = !started;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setupAVCapture];
	// Do any additional setup after loading the view, typically from a nib.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return ( UIInterfaceOrientationPortrait == interfaceOrientation );
}


@end
