/*
     File: FHViewController.h
 Abstract: The view controller for the capture preview
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
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import <AVFoundation/AVFoundation.h>
#import <CoreText/CoreText.h>
#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>
#import "FilterListController.h"
#import "FilterStack.h"
#import "FrameRateCalculator.h"
#import "SettingsController.h"

@interface FHViewController : UIViewController
<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, FilterListControllerDelegate, SettingsControllerDelegate>
{
@private
    GLKView *_videoPreviewView;    
    CIContext *_ciContext;
    EAGLContext *_eaglContext;
    CGRect _videoPreviewViewBounds;
    
    AVCaptureDevice *_audioDevice;
    AVCaptureDevice *_videoDevice;
    AVCaptureSession *_captureSession;

    AVAssetWriter *_assetWriter;
	AVAssetWriterInput *_assetWriterAudioInput;
    AVAssetWriterInput *_assetWriterVideoInput;
    AVAssetWriterInputPixelBufferAdaptor *_assetWriterInputPixelBufferAdaptor;

    dispatch_queue_t _captureSessionQueue;    
    UIBackgroundTaskIdentifier _backgroundRecordingID;
    
    FilterStack *_filterStack;
    NSArray *_activeFilters;
    
    BOOL _videoWritingStarted;
    CMTime _videoWrtingStartTime;
    CMFormatDescriptionRef _currentAudioSampleBufferFormatDescription;
    CMVideoDimensions _currentVideoDimensions;
    CMTime _currentVideoTime;

    NSTimer *_labelUpdateTimer;
    
    FrameRateCalculator *_frameRateCalculator;
     
    BOOL _filterPopoverVisibleBeforeRotation;
    BOOL _settingsPopoverVisibleBeforeRotation;
}


@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *recordStopButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *fpsLabel;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *filtersButton;

@property (strong, nonatomic) UIPopoverController *filterListPopoverController;
@property (strong, nonatomic) UINavigationController *filterListNavigationController;

@property (assign, atomic) CMTime currentVideoTime;

- (IBAction)recordStopAction:(UIBarButtonItem *)sender event:(UIEvent *)event;
- (IBAction)settingsAction:(UIBarButtonItem *)sender event:(UIEvent *)event;
- (IBAction)filtersAction:(UIBarButtonItem *)sender event:(UIEvent *)event;

@property (strong, nonatomic) UIPopoverController *settingsPopoverController;
@property (strong, nonatomic) UINavigationController *settingsNavigationController;
@end

// for telling UI controllers that it has started the capture session, not necessarily meaning the capture session has succeeded started
extern NSString *const FHViewControllerDidStartCaptureSessionNotification;
