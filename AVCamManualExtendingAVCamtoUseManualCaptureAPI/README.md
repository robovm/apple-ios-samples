# AVCamManual: Using the Manual Capture API

### Description
AVCamManual adds manual controls for focus, exposure, and white balance to the AVCam sample application.

#### New for iOS 9
iPhone 6 Plus shipped with a lens stabilization module that is used during still image capture to reduce the effects of hand-shake in low-light situations.  

AVFoundation introduces an API to apply lens stabilization to still images captured via the bracketed capture APIs from iOS 8--this sample demonstrates the use of this API.

AVCamManual also uses size classes to work across all available sceen sizes.

#### Using the Lens Stabilization API
To turn lens stabilization on during a bracketed still image capture sequence, first check if it's supported by querying the read-only property `AVCaptureStillImageOutput.lensStabilizationDuringBracketedCaptureSupported`.  If it's supported, your code can then set `AVCaptureStillImageOutput.lensStabilizationDuringBracketedCaptureEnabled` to `YES`.

The property is "sticky" across still image captures.  If the `AVCaptureStillImageOutput.lensStabilizationDuringBracketedCaptureSupported` ever switches to `NO`, `AVCaptureStillImageOutput.lensStabilizationDuringBracketedCaptureEnabled` will be forced off and will remain off even if lens stabilization becomes supported later.  Both `AVCaptureStillImageOutput.lensStabilizationDuringBracketedCaptureSupported` and `AVCaptureStillImageOutput.lensStabilizationDuringBracketedCaptureEnabled` are KVO-able properties.

Applying lens stabilization will not always improve still image captures.  It's most effective when exposure durations are greater than or equal to 1/30s.  The motion or duration of capture may also exceed the amount of compensation the module is able to provide. To find out information about the stabilization applied to a given sample buffer of the bracket, examine the value of the `CMSampleBuffer` attachment key `kCMSampleBufferAttachmentKey_StillImageLensStabilizationInfo`:

	CFStringRef lensStabilizationInfo = CMGetAttachment( sbuf, kCMSampleBufferAttachmentKey_StillImageLensStabilizationInfo, NULL /* attachmentModeOut */ );

The value will match one of the following strings:

- `kCMSampleBufferLensStabilizationInfo_Active`: Stabilization was applied.
- `kCMSampleBufferLensStabilizationInfo_OutOfRange`: The motion couldn't be compensated for, or the capture duration exceeded the limits of the lens module.
- `kCMSampleBufferLensStabilizationInfo_Unavailable`: The module couldn't be used for this capture.
- `kCMSampleBufferLensStabilizationInfo_Off`: Lens stabilization wasn't requested for the bracketed capture.


## Requirements

### Build

Xcode 7, iOS 9 SDK

### Runtime

iOS 9.0

Copyright (C) 2015 Apple Inc. All rights reserved.
