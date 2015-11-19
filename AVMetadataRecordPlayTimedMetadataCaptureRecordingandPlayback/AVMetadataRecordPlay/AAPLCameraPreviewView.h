/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Camera preview view.
*/

@import UIKit;

@class AVCaptureSession;

@interface AAPLCameraPreviewView : UIView

@property (nonatomic) AVCaptureSession *session;

@end
