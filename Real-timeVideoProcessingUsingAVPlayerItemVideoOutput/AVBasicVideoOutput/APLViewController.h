/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller handles the UI to load assets for playback and for adjusting the luma and chroma values. It also sets up the AVPlayerItemVideoOutput, from which CVPixelBuffers are pulled out and sent to the shaders for rendering.
*/

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface APLViewController : UIViewController <AVPlayerItemOutputPullDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIGestureRecognizerDelegate>

@end
