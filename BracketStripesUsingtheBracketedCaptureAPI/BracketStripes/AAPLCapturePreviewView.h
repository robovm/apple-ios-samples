/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
         Camera preview view, with automatic "flash" animation
     
 */

@import AVFoundation;


@interface AAPLCapturePreviewView : UIView

- (void)configureCaptureSession:(AVCaptureSession *)captureSession captureOutput:(AVCaptureOutput *)captureOutput;

@end
