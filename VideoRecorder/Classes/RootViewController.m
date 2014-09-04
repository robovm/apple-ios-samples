/*
     File: RootViewController.m 
 Abstract: n/a 
  Version: 1.0.1 
  
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

#import "RootViewController.h"

@interface RootViewController ()
- (void)changeVideoQuality:(id)sender;
- (void)changeFlashMode:(id)sender;
- (void)changeCamera:(id)sender;

- (void)createImagePicker;
- (void)startRecording;
- (void)stopRecording;

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
@end

@implementation RootViewController

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    cameraSelectionButton.alpha = 0.0;
    flashModeButton.alpha = 0.0;
    recordIndicatorView.alpha = 0.0;
    
    [self createImagePicker];
    
    recordGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleVideoRecording)];
    recordGestureRecognizer.numberOfTapsRequired = 2;
    
    [cameraOverlayView addGestureRecognizer:recordGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    CGRect theRect = [imagePicker.view frame];
    [cameraOverlayView setFrame:theRect];
    
    [self presentViewController:imagePicker animated:animated completion:nil];
    imagePicker.cameraOverlayView = cameraOverlayView;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
    [recordGestureRecognizer release];
    
    [super dealloc];
}

- (void)createImagePicker {
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    imagePicker.mediaTypes = [NSArray arrayWithObject:@"public.movie"];
    imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    
    imagePicker.allowsEditing = NO;
    imagePicker.showsCameraControls = NO;
    imagePicker.cameraViewTransform = CGAffineTransformIdentity;
    
    // not all devices have two cameras or a flash so just check here
    if ( [UIImagePickerController isCameraDeviceAvailable: UIImagePickerControllerCameraDeviceRear] ) {
        imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        if ( [UIImagePickerController isCameraDeviceAvailable: UIImagePickerControllerCameraDeviceFront] ) {
            cameraSelectionButton.alpha = 1.0;
            showCameraSelection = YES;
        }
    } else {
        imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    
    if ( [UIImagePickerController isFlashAvailableForCameraDevice:imagePicker.cameraDevice] ) {
        imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        flashModeButton.alpha = 1.0;
        showFlashMode = YES;
    }

    imagePicker.videoQuality = UIImagePickerControllerQualityType640x480;

    imagePicker.delegate = self;
    imagePicker.wantsFullScreenLayout = YES;
}


- (void)toggleVideoRecording {
    if (!recording) {
        recording = YES;
        [self startRecording];
    } else {
        recording = NO;
        [self stopRecording];
    }
}

- (void)changeVideoQuality:(id)sender {
    if (imagePicker.videoQuality == UIImagePickerControllerQualityType640x480) {
        imagePicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
        [videoQualitySelectionButton setImage:[UIImage imageNamed:@"hd-selected.png"] forState:UIControlStateNormal];
    } else {
        imagePicker.videoQuality = UIImagePickerControllerQualityType640x480;
        [videoQualitySelectionButton setImage:[UIImage imageNamed:@"sd-selected.png"] forState:UIControlStateNormal];
    }
}

- (void)changeFlashMode:(id)sender {
    if (imagePicker.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff) {
        imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        [flashModeButton setImage:[UIImage imageNamed:@"flash-on.png"] forState:UIControlStateNormal];
    } else {
        imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        [flashModeButton setImage:[UIImage imageNamed:@"flash-off.png"] forState:UIControlStateNormal];
    }
}

- (void)changeCamera:(id)sender {
    if (imagePicker.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    } else {
        imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
    
    if ( ![UIImagePickerController isFlashAvailableForCameraDevice:imagePicker.cameraDevice] ) {
        [UIView animateWithDuration:0.3 animations:^(void) {flashModeButton.alpha = 0;}];
        showFlashMode = NO;
    } else {
        [UIView animateWithDuration:0.3 animations:^(void) {flashModeButton.alpha = 1.0;}];
        showFlashMode = YES;
    }
}

- (void)startRecording {
    
    void (^hideControls)(void);
    hideControls = ^(void) {
        cameraSelectionButton.alpha = 0;
        flashModeButton.alpha = 0;
        videoQualitySelectionButton.alpha = 0;
        recordIndicatorView.alpha = 1.0;
    };

    void (^recordMovie)(BOOL finished);
    recordMovie = ^(BOOL finished) {
        [imagePicker startVideoCapture];
    };
    
    // Hide controls
    [UIView  animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:hideControls completion:recordMovie];
}

- (void)stopRecording {
    [imagePicker stopVideoCapture];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSURL *videoURL = [info valueForKey:UIImagePickerControllerMediaURL];
    NSString *pathToVideo = [videoURL path];
    BOOL okToSaveVideo = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToVideo);
    if (okToSaveVideo) {
        UISaveVideoAtPathToSavedPhotosAlbum(pathToVideo, self, @selector(video:didFinishSavingWithError:contextInfo:), NULL);
    } else {
        [self video:pathToVideo didFinishSavingWithError:nil contextInfo:NULL];
    }
    
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    void (^showControls)(void);
    showControls = ^(void) {
        if (showCameraSelection) cameraSelectionButton.alpha = 1.0;
        if (showFlashMode) flashModeButton.alpha = 1.0;
        videoQualitySelectionButton.alpha = 1.0;
        recordIndicatorView.alpha = 0.0;
    };

    // Show controls
    [UIView  animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:showControls completion:NULL];

}
@end
