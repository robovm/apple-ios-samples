/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Camera preview.
*/

@import AVFoundation;

#import "AAPLPreviewView.h"

@implementation AAPLPreviewView

+ (Class)layerClass
{
	return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
	AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
	return previewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session
{
	AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
	previewLayer.session = session;
}

@end
