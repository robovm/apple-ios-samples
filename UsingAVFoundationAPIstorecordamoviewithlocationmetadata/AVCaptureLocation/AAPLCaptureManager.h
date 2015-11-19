/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This class creates and manages the AV capture session and CLLocationManager, to gather location data, and writes out this data using asset writer. 
  
 */

@import Foundation;
@import AVFoundation;

@protocol AAPLCaptureManagerDelegate;

@interface AAPLCaptureManager : NSObject

@property (assign) id <AAPLCaptureManagerDelegate>	delegate;
@property (readonly) AVCaptureSession				*session;
@property (readonly, getter=isRecording) BOOL		recording;
@property AVCaptureVideoOrientation					referenceOrientation;
@property CGFloat									distanceUpdateInMeters;

- (void)setupAndStartCaptureSession;
- (void)stopAndTearDownCaptureSession;

- (void)startRecording;
- (void)stopRecording;

- (void)pauseCaptureSession; // Pausing while a recording is in progress will cause the recording to be stopped and saved.
- (void)resumeCaptureSession;

@end

@protocol AAPLCaptureManagerDelegate <NSObject>

@required
- (void)recordingWillStart;
- (void)recordingDidStart;
- (void)recordingWillStop;
- (void)recordingDidStop;
- (void)newLocationUpdate:(NSString *)locationDescription;

@end
