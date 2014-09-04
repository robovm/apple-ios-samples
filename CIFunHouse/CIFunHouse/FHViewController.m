/*
     File: FHViewController.m
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

#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>

#import "FHViewController.h"
#import "FHAppDelegate.h"
#import "FilterListController.h"

#import "CIFilter+FHAdditions.h"
#import "FilterAttributeBinding.h"


static NSString *const kUserDefaultsKey = @"FilterSettings";

NSString *const FHViewControllerDidStartCaptureSessionNotification = @"FHViewControllerDidStartCaptureSessionNotification";

static NSString *const kTempVideoFilename = @"recording.mov";
static NSTimeInterval kFPSLabelUpdateInterval = 0.25;

static CGColorSpaceRef sDeviceRgbColorSpace = NULL;


static CGAffineTransform FCGetTransformForDeviceOrientation(UIDeviceOrientation orientation, BOOL mirrored)
{
    // Internal comment: This routine assumes that the native camera image is always coming from a UIDeviceOrientationLandscapeLeft (i.e. the home button is on the RIGHT, which equals AVCaptureVideoOrientationLandscapeRight!), although in the future this assumption may not hold; better to get video output's capture connection's videoOrientation property, and apply the transform according to the native video orientation
    
    // Also, it may be desirable to apply the flipping as a separate step after we get the rotation transform
    CGAffineTransform result;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            result = CGAffineTransformMakeRotation(M_PI_2);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            result = CGAffineTransformMakeRotation((3 * M_PI_2));
            break;
        case UIDeviceOrientationLandscapeLeft:
            result = mirrored ?  CGAffineTransformMakeRotation(M_PI) : CGAffineTransformIdentity;
            break;
        default:
            result = mirrored ? CGAffineTransformIdentity : CGAffineTransformMakeRotation(M_PI);
            break;
    }
    
    return result;
}

// an inline function to filter a CIImage through a filter chain; note that each image input attribute may have different source
static inline CIImage *RunFilter(CIImage *cameraImage, NSArray *filters)
{
    CIImage *currentImage = nil;
    NSMutableArray *activeInputs = [NSMutableArray array];
    
    for (CIFilter *filter in filters)
    {
        if ([filter isKindOfClass:[SourceVideoFilter class]])
        {
            [filter setValue:cameraImage forKey:kCIInputImageKey];
        }
        else if ([filter isKindOfClass:[SourcePhotoFilter class]])
        {
            ; // nothing to do here
        }
        else
        {
            for (NSString *attrName in [filter imageInputAttributeKeys])
            {
                CIImage* top = [activeInputs lastObject];
                if (top)
                {
                    [filter setValue:top forKey:attrName];
                    [activeInputs removeLastObject];
                }
                else
                    NSLog(@"failed to set %@ for %@", attrName, filter.name);
            }
        }
        
        currentImage = filter.outputImage;
        if (currentImage == nil)
            return nil;
        [activeInputs addObject:currentImage];
    }
    
    if (CGRectIsEmpty(currentImage.extent))
        return nil;
    return currentImage;
}

@interface FHViewController (PrivateMethods)
- (void)_start;

- (void)_startWriting;
- (void)_abortWriting;
- (void)_stopWriting;

- (void)_startLabelUpdateTimer;
- (void)_stopLabelUpdateTimer;
- (void)_updateLabel:(NSTimer *)timer;

- (void)_handleFilterStackActiveFilterListDidChangeNotification:(NSNotification *)notification;
- (void)_handleAVCaptureSessionWasInterruptedNotification:(NSNotification *)notification;
- (void)_handleUIApplicationDidEnterBackgroundNotification:(NSNotification *)notification;

- (void)_showAlertViewWithMessage:(NSString *)message title:(NSString *)title;
- (void)_showAlertViewWithMessage:(NSString *)message;  // can be called in any thread, any queue

- (void)_stop;

- (void)_handleFHFilterImageAttributeSourceChange:(NSNotification *)notification;
- (void)_handleSettingUpdate:(NSNotification *)notification;
@end


@implementation FHViewController
@synthesize recordStopButton = _recordStopButton;
@synthesize filtersButton = _filtersButton;
@synthesize filterListPopoverController = _filterListPopoverController;
@synthesize filterListNavigationController = _filterListNavigationController;
@synthesize currentVideoTime = _currentVideoTime;
@synthesize toolbar = _toolbar;
@synthesize settingsButton = _settingsButton;
@synthesize fpsLabel = _fpsLabel;
@synthesize settingsPopoverController = _settingsPopoverController;
@synthesize settingsNavigationController = _settingsNavigationController;


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // create the shared color space object once
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sDeviceRgbColorSpace = CGColorSpaceCreateDeviceRGB();
        });
        
        // load the filters and their configurations
        _filterStack = [[FilterStack alloc] init];

        _activeFilters = [_filterStack.activeFilters copy];

        _frameRateCalculator = [[FrameRateCalculator alloc] init];

        // create the dispatch queue for handling capture session delegate method calls
        _captureSessionQueue = dispatch_queue_create("capture_session_queue", NULL);
        
        self.wantsFullScreenLayout = YES;        
        [UIApplication sharedApplication].statusBarHidden = YES;
    }
    return self;
}

- (void)dealloc
{
    if (_currentAudioSampleBufferFormatDescription)
        CFRelease(_currentAudioSampleBufferFormatDescription);

    //dispatch_release(_captureSessionQueue);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    FilterListController *filterListController = [[FilterListController alloc] initWithStyle:UITableViewStylePlain];
    filterListController.filterStack = _filterStack;    
    filterListController.delegate = self;
    filterListController.contentSizeForViewInPopover = CGSizeMake(480.0, 320.0);
    self.filterListNavigationController = [[UINavigationController alloc] initWithRootViewController:filterListController];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        self.filterListPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.filterListNavigationController];

    SettingsController *settingsController = [[SettingsController alloc] initWithStyle:UITableViewStyleGrouped];
    settingsController.delegate = self;
    settingsController.contentSizeForViewInPopover = CGSizeMake(480.0, 320.0);
    self.settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsController];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        self.settingsPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.settingsNavigationController];
    
    
    // remove the view's background color; this allows us not to use the opaque property (self.view.opaque = NO) since we remove the background color drawing altogether
    self.view.backgroundColor = nil;
    
    // setup the GLKView for video/image preview
    UIView *window = ((FHAppDelegate *)[UIApplication sharedApplication].delegate).window;
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _videoPreviewView = [[GLKView alloc] initWithFrame:window.bounds context:_eaglContext];
    _videoPreviewView.enableSetNeedsDisplay = NO;
    
    // because the native video image from the back camera is in UIDeviceOrientationLandscapeLeft (i.e. the home button is on the right), we need to apply a clockwise 90 degree transform so that we can draw the video preview as if we were in a landscape-oriented view; if you're using the front camera and you want to have a mirrored preview (so that the user is seeing themselves in the mirror), you need to apply an additional horizontal flip (by concatenating CGAffineTransformMakeScale(-1.0, 1.0) to the rotation transform)
    _videoPreviewView.transform = CGAffineTransformMakeRotation(M_PI_2);
    _videoPreviewView.frame = window.bounds;
    
    // we make our video preview view a subview of the window, and send it to the back; this makes FHViewController's view (and its UI elements) on top of the video preview, and also makes video preview unaffected by device rotation
    [window addSubview:_videoPreviewView];
    [window sendSubviewToBack:_videoPreviewView];
        
    // create the CIContext instance, note that this must be done after _videoPreviewView is properly set up
    _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
    
    // bind the frame buffer to get the frame buffer width and height;
    // the bounds used by CIContext when drawing to a GLKView are in pixels (not points),
    // hence the need to read from the frame buffer's width and height;
    // in addition, since we will be accessing the bounds in another queue (_captureSessionQueue),
    // we want to obtain this piece of information so that we won't be
    // accessing _videoPreviewView's properties from another thread/queue
    [_videoPreviewView bindDrawable];            
    _videoPreviewViewBounds = CGRectZero;
    _videoPreviewViewBounds.size.width = _videoPreviewView.drawableWidth;
    _videoPreviewViewBounds.size.height = _videoPreviewView.drawableHeight;
    
    filterListController.screenSize = CGSizeMake(_videoPreviewViewBounds.size.width, _videoPreviewViewBounds.size.height);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleAttributeValueUpdate:)
                                                 name:FilterAttributeValueDidUpdateNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleFHFilterImageAttributeSourceChange:)
                                                 name:kFHFilterImageAttributeSourceDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleSettingUpdate:)
                                                 name:kFHSettingDidUpdateNotification object:nil];
    
    // handle filter list change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleFilterStackActiveFilterListDidChangeNotification:)
                                                 name:FilterStackActiveFilterListDidChangeNotification object:nil];
    
    // handle AVCaptureSessionWasInterruptedNotification (such as incoming phone call)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleAVCaptureSessionWasInterruptedNotification:)
                                                 name:AVCaptureSessionWasInterruptedNotification object:nil];
    
    // handle UIApplicationDidEnterBackgroundNotification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleUIApplicationDidEnterBackgroundNotification:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    // check the availability of video and audio devices
    // create and start the capture session only if the devices are present
    {
        #if TARGET_IPHONE_SIMULATOR
        #warning On iPhone Simulator, the app still gets a video device, but the video device will not work;
        #warning On iPad Simulator, the app gets no video device
        #endif
        
        // populate the defaults
        FCPopulateDefaultSettings();
        
        // see if we have any video device
        if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 0)
        {
            // find the audio device
            NSArray *audioDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
            if ([audioDevices count])
                _audioDevice = [audioDevices objectAtIndex:0];  // use the first audio device
            
            [self _start];
        }
    }
    
    self.toolbar.translucent = NO;
    self.fpsLabel.title = @"";
    self.fpsLabel.enabled = NO;
    self.recordStopButton.enabled = NO;
}

- (void)viewDidUnload
{
    // remove the _videoPreviewView
    [_videoPreviewView removeFromSuperview];
    _videoPreviewView = nil;
    
    [self _stopWriting];
    [self _stop];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FilterAttributeValueDidUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFHFilterImageAttributeSourceDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFHSettingDidUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FilterStackActiveFilterListDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionWasInterruptedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];    
    
    [super viewDidUnload];    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // filterListPopoverController is nil when on iPhone, so no effect if used
    _filterPopoverVisibleBeforeRotation = self.filterListPopoverController.popoverVisible;
    if (_filterPopoverVisibleBeforeRotation)
        [self.filterListPopoverController dismissPopoverAnimated:NO];
    

    _settingsPopoverVisibleBeforeRotation = self.settingsPopoverController.popoverVisible;
    if (_settingsPopoverVisibleBeforeRotation)
        [self.settingsPopoverController dismissPopoverAnimated:NO];
    
    
    // makes the UI more Camera.app like
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [UIView setAnimationsEnabled:NO];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [UIView setAnimationsEnabled:YES];
        [UIView beginAnimations:@"reappear" context:NULL];
        [UIView setAnimationDuration:0.75];
        [UIView commitAnimations];
    }

    // settingsPopoverController is nil when on iPhone, so no effect if used
    if (_settingsPopoverVisibleBeforeRotation)
        [self.settingsPopoverController presentPopoverFromBarButtonItem:_settingsButton
                                               permittedArrowDirections:UIPopoverArrowDirectionAny
                                                               animated:YES];
    
    // filterListPopoverController is nil when on iPhone, so no effect if used
    if (_filterPopoverVisibleBeforeRotation)
        [self.filterListPopoverController presentPopoverFromBarButtonItem:_filtersButton
                                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                                             animated:YES];
}

#pragma mark - Actions

- (IBAction)recordStopAction:(UIBarButtonItem *)sender event:(UIEvent *)event
{
    if (_assetWriter)
        [self _stopWriting];
    else
        [self _startWriting];    
}

- (IBAction)filtersAction:(UIBarButtonItem *)sender event:(UIEvent *)event
{
    // set the global crop max
    FCSetGlobalCropFilterMaxValue(MAX(_currentVideoDimensions.width, _currentVideoDimensions.height));

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                withAnimation:UIStatusBarAnimationSlide];
        
        [self presentViewController:self.filterListNavigationController animated:YES completion:nil];
    }
    else
    {
        if (self.settingsPopoverController.popoverVisible)
            [self.settingsPopoverController dismissPopoverAnimated:NO];

        if (self.filterListPopoverController.popoverVisible)
            [self.filterListPopoverController dismissPopoverAnimated:NO];
        else
            [self.filterListPopoverController presentPopoverFromBarButtonItem:sender
                                                     permittedArrowDirections:UIPopoverArrowDirectionAny
                                                                     animated:YES];
    }
}

- (IBAction)settingsAction:(UIBarButtonItem *)sender event:(UIEvent *)event
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                withAnimation:UIStatusBarAnimationSlide];
        
        [self presentViewController:self.settingsNavigationController animated:YES completion:nil];
    }
    else
    {
        if (self.filterListPopoverController.popoverVisible)
            [self.filterListPopoverController dismissPopoverAnimated:NO];
        
        if (self.settingsPopoverController.popoverVisible)
            [self.settingsPopoverController dismissPopoverAnimated:NO];
        else
            [self.settingsPopoverController presentPopoverFromBarButtonItem:sender
                                                   permittedArrowDirections:UIPopoverArrowDirectionAny
                                                                   animated:YES];
    }
}

#pragma mark - Private methods

- (void)_start
{
    if (_captureSession)
        return;
    
    [self _stopLabelUpdateTimer];
    
    dispatch_async(_captureSessionQueue, ^(void) {
        NSError *error = nil;
        
        // get the input device and also validate the settings
        NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
        AVCaptureDevicePosition position = [[NSUserDefaults standardUserDefaults] integerForKey:kFHSettingCameraPositionKey];
        
        _videoDevice = nil;
        for (AVCaptureDevice *device in videoDevices)
        {
            if (device.position == position) {
                _videoDevice = device;
                break;
            }
        }
        
        if (!_videoDevice)
        {
            _videoDevice = [videoDevices objectAtIndex:0];            
            [[NSUserDefaults standardUserDefaults] setObject:@(_videoDevice.position) forKey:kFHSettingCameraPositionKey];
        }

        
        // obtain device input
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_videoDevice error:&error];
        if (!videoDeviceInput)
        {
            [self _showAlertViewWithMessage:[NSString stringWithFormat:@"Unable to obtain video device input, error: %@", error]];
            return;
        }
        
        AVCaptureDeviceInput *audioDeviceInput = nil;
        if (_audioDevice)
        {
            audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_audioDevice error:&error];
            if (!audioDeviceInput)
            {
                [self _showAlertViewWithMessage:[NSString stringWithFormat:@"Unable to obtain audio device input, error: %@", error]];
                return;            
            }
        }
        
        // obtain the preset and validate the preset
        NSString *preset = [[NSUserDefaults standardUserDefaults] objectForKey:kFHSettingCaptureSessionPresetKey];
        if (![_videoDevice supportsAVCaptureSessionPreset:preset])
        {
            preset = AVCaptureSessionPresetMedium;
            [[NSUserDefaults standardUserDefaults] setObject:preset forKey:kFHSettingCaptureSessionPresetKey];
        }                
        if (![_videoDevice supportsAVCaptureSessionPreset:preset])
        {
            [self _showAlertViewWithMessage:[NSString stringWithFormat:@"Capture session preset not supported by video device: %@", preset]];
            return;            
        }

        // CoreImage wants BGRA pixel format
        NSDictionary *outputSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
        
        // create the capture session
        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.sessionPreset = preset;
        
        // create and configure video data output
        AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        videoDataOutput.videoSettings = outputSettings;
        videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        [videoDataOutput setSampleBufferDelegate:self queue:_captureSessionQueue];
        
        // configure audio data output
        AVCaptureAudioDataOutput *audioDataOutput = nil;
        if (_audioDevice) {
            audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
            [audioDataOutput setSampleBufferDelegate:self queue:_captureSessionQueue];
        }
        
        // begin configure capture session
        [_captureSession beginConfiguration];
        
        if (![_captureSession canAddOutput:videoDataOutput])
        {
            [self _showAlertViewWithMessage:@"Cannot add video data output"];
            _captureSession = nil;
            return;                    
        }

        if (audioDataOutput)
        {
            if (![_captureSession canAddOutput:audioDataOutput])
            {
                [self _showAlertViewWithMessage:@"Cannot add still audio data output"];
                _captureSession = nil;
                return;                    
            }        
        }
        
        // connect the video device input and video data and still image outputs
        [_captureSession addInput:videoDeviceInput];
        [_captureSession addOutput:videoDataOutput];
        
        if (_audioDevice)
        {
            [_captureSession addInput:audioDeviceInput];
            [_captureSession addOutput:audioDataOutput];
        }
        
        [_captureSession commitConfiguration];
        
        // then start everything
        [_frameRateCalculator reset];
        [_captureSession startRunning];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self _startLabelUpdateTimer];

            UIView *window = ((FHAppDelegate *)[UIApplication sharedApplication].delegate).window;

            CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
            // apply the horizontal flip
            BOOL shouldMirror = (AVCaptureDevicePositionFront == _videoDevice.position);
            if (shouldMirror)
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(-1.0, 1.0));

            _videoPreviewView.transform = transform;
            _videoPreviewView.frame = window.bounds;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:FHViewControllerDidStartCaptureSessionNotification object:self];
        });
        
    });
}

- (void)_stop
{
    if (!_captureSession || !_captureSession.running)
        return;

    [_captureSession stopRunning];

    dispatch_sync(_captureSessionQueue, ^{
        NSLog(@"waiting for capture session to end");
    });
    
    [self _stopWriting];

    _captureSession = nil;
    _videoDevice = nil;    
}

- (void)_startWriting
{
    _recordStopButton.title = @"Stop";
    _fpsLabel.title = @"00:00";
    
    dispatch_async(_captureSessionQueue, ^{
        NSError *error = nil;
        
        // remove the temp file, if any
        NSURL *outputFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:kTempVideoFilename]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[outputFileURL path]])
            [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:NULL];
        
        
        AVAssetWriter *newAssetWriter = [AVAssetWriter assetWriterWithURL:outputFileURL fileType:AVFileTypeQuickTimeMovie error:&error];
        if (!newAssetWriter || error) {
            [self _showAlertViewWithMessage:[NSString stringWithFormat:@"Cannot create asset writer, error: %@", error]];
            return;
        }
        
        NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                  AVVideoCodecH264, AVVideoCodecKey,
                                                  [NSNumber numberWithInteger:_currentVideoDimensions.width], AVVideoWidthKey,
                                                  [NSNumber numberWithInteger:_currentVideoDimensions.height], AVVideoHeightKey,
                                                  nil];
        
        _assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
        _assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        
        // create a pixel buffer adaptor for the asset writer; we need to obtain pixel buffers for rendering later from its pixel buffer pool
        _assetWriterInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput sourcePixelBufferAttributes:
                                               [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                                [NSNumber numberWithUnsignedInteger:_currentVideoDimensions.width], (id)kCVPixelBufferWidthKey,
                                                [NSNumber numberWithUnsignedInteger:_currentVideoDimensions.height], (id)kCVPixelBufferHeightKey,
                                                (id)kCFBooleanTrue, (id)kCVPixelFormatOpenGLESCompatibility,
                                                nil]];
        
        
        UIDeviceOrientation orientation = ((FHAppDelegate *)[UIApplication sharedApplication].delegate).realDeviceOrientation;
        //UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        
        // give correct orientation information to the video
        if (_videoDevice.position == AVCaptureDevicePositionFront)
            _assetWriterVideoInput.transform = FCGetTransformForDeviceOrientation(orientation, YES);
        else
            _assetWriterVideoInput.transform = FCGetTransformForDeviceOrientation(orientation, NO);
        
        BOOL canAddInput = [newAssetWriter canAddInput:_assetWriterVideoInput];
        if (!canAddInput) {
            [self _showAlertViewWithMessage:@"Cannot add asset writer video input"];
            _assetWriterAudioInput = nil;
            _assetWriterVideoInput = nil;
            return;
        }
        
        [newAssetWriter addInput:_assetWriterVideoInput];    
        
        if (_audioDevice) {
            size_t layoutSize = 0;
            const AudioChannelLayout *channelLayout = CMAudioFormatDescriptionGetChannelLayout(_currentAudioSampleBufferFormatDescription, &layoutSize);
            const AudioStreamBasicDescription *basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(_currentAudioSampleBufferFormatDescription);
            
            NSData *channelLayoutData = [NSData dataWithBytes:channelLayout length:layoutSize];
            
            // record the audio at AAC format, bitrate 64000, sample rate and channel number using the basic description from the audio samples
            NSDictionary *audioCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                      [NSNumber numberWithInteger:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                                      [NSNumber numberWithInteger:basicDescription->mChannelsPerFrame], AVNumberOfChannelsKey,                                                  
                                                      [NSNumber numberWithFloat:basicDescription->mSampleRate], AVSampleRateKey,
                                                      [NSNumber numberWithInteger:64000], AVEncoderBitRateKey,
                                                      channelLayoutData, AVChannelLayoutKey,
                                                      nil];
            
            if ([newAssetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio]) {
                _assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
                _assetWriterAudioInput.expectsMediaDataInRealTime = YES;
                
                if ([newAssetWriter canAddInput:_assetWriterAudioInput])
                    [newAssetWriter addInput:_assetWriterAudioInput];
                else
                    [self _showAlertViewWithMessage:@"Couldn't add asset writer audio input"
                                              title:@"Warning"];
            }
            else 
                [self _showAlertViewWithMessage:@"Couldn't apply audio output settings."
                                          title:@"Warning"];
        }
        
        // Make sure we have time to finish saving the movie if the app is backgrounded during recording
        // cf. the RosyWriter sample app from WWDC 2011
        if ([[UIDevice currentDevice] isMultitaskingSupported])
            _backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];    
        
        _videoWritingStarted = NO;
        _assetWriter = newAssetWriter;        
    });    
}

- (void)_abortWriting
{
    if (!_assetWriter)
        return;
    
    [_assetWriter cancelWriting];
    _assetWriterAudioInput = nil;
    _assetWriterVideoInput = nil;
    _assetWriter = nil;
    
    // remove the temp file
    NSURL *fileURL = [_assetWriter outputURL];
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:NULL];

    void (^resetUI)(void) = ^(void) {
        _recordStopButton.title = @"Record";
        _recordStopButton.enabled = YES;
        
        // end the background task if it's done there
        // cf. The RosyWriter sample app from WWDC 2011
        if ([[UIDevice currentDevice] isMultitaskingSupported])
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundRecordingID];        
    };

    dispatch_async(dispatch_get_main_queue(), resetUI);    
}

- (void)_stopWriting
{
    if (!_assetWriter)
        return;
    

    AVAssetWriter *writer = _assetWriter;
    
    _assetWriterAudioInput = nil;
    _assetWriterVideoInput = nil;
    _assetWriterInputPixelBufferAdaptor = nil;
    _assetWriter = nil;
    
    [self _stopLabelUpdateTimer];
    _fpsLabel.title = @"Saving...";
    _recordStopButton.enabled = NO;

    void (^resetUI)(void) = ^(void) {
        _recordStopButton.title = @"Record";
        _recordStopButton.enabled = YES;
        
        [self _startLabelUpdateTimer];
        
        // end the background task if it's done there
        // cf. The RosyWriter sample app from WWDC 2011
        if ([[UIDevice currentDevice] isMultitaskingSupported])
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundRecordingID];        
    };
    
    dispatch_async(_captureSessionQueue, ^(void){
        NSURL *fileURL = [writer outputURL];
        
        [writer finishWritingWithCompletionHandler:^(void){
            if (writer.status == AVAssetWriterStatusFailed)
            {
                dispatch_async(dispatch_get_main_queue(), resetUI);
                [self _showAlertViewWithMessage:@"Cannot complete writing the video, the output could be corrupt."];
            }
            else if (writer.status == AVAssetWriterStatusCompleted)
            {
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                [library writeVideoAtPathToSavedPhotosAlbum:fileURL
                                            completionBlock:^(NSURL *assetURL, NSError *error){
                                                if (error) {
                                                    NSString *mssg = [NSString stringWithFormat:@"Error saving the video to the photo library. %@", error];
                                                    [self _showAlertViewWithMessage:mssg];
                                                }
                                                
                                                // remove the temp file
                                                [[NSFileManager defaultManager] removeItemAtURL:fileURL error:NULL];
                                            }];
            }
            dispatch_async(dispatch_get_main_queue(), resetUI);
        }];
        
    });    
}


- (void)_startLabelUpdateTimer
{
    _labelUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:kFPSLabelUpdateInterval target:self selector:@selector(_updateLabel:) userInfo:nil repeats:YES];    
}

- (void)_stopLabelUpdateTimer
{
    [_labelUpdateTimer invalidate];
    _labelUpdateTimer = nil;
}

- (void)_updateLabel:(NSTimer *)timer
{
    _fpsLabel.title = [NSString stringWithFormat:@"%.1f fps", _frameRateCalculator.frameRate];
    if (_assetWriter)
    {
        CMTime diff = CMTimeSubtract(self.currentVideoTime, _videoWrtingStartTime);
        NSUInteger seconds = (NSUInteger)CMTimeGetSeconds(diff);
        
        _fpsLabel.title = [NSString stringWithFormat:@"%02lu:%02lu", seconds / 60UL, seconds % 60UL];
    }
}


- (void)_handleAttributeValueUpdate:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CIFilter *filter = [info valueForKey:kFilterObject];
    id key = [info valueForKey:kFilterInputKey];
    id value = [info valueForKey:kFilterInputValue];
    
    if (filter && key && value) {
        dispatch_async(_captureSessionQueue, ^{
            [filter setValue:value forKey:key];
        });
    }
}

- (void)_handleFHFilterImageAttributeSourceChange:(NSNotification *)notification
{
    [self _handleFilterStackActiveFilterListDidChangeNotification:notification];
}

- (void)_handleSettingUpdate:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *updatedKey = [userInfo objectForKey:kFHSettingUpdatedKeyNameKey];
    
    if ([updatedKey isEqualToString:kFHSettingColorMatchKey])
    {
        BOOL colormatch = [[NSUserDefaults standardUserDefaults] boolForKey:updatedKey];
        NSDictionary *options = colormatch ? @{kCIContextWorkingColorSpace : [NSNull null]} : nil;
        
        dispatch_async(_captureSessionQueue, ^{
            _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:options];
        });
    }
    
    [self _stop];
    [self _start];
}


- (void)_handleFilterStackActiveFilterListDidChangeNotification:(NSNotification *)notification
{
    // the active filter list gets updated, and we use this to ensure that the our _activeFilters array gets changed in the designated queue (to avoid the race condition where _activeFilters is being used by RunFilter()
    NSArray *newActiveFilters = _filterStack.activeFilters;
    dispatch_async(_captureSessionQueue, ^() {
        _activeFilters = newActiveFilters;
    });    
    
    self.fpsLabel.enabled = (_filterStack.containsVideoSource);
    self.recordStopButton.enabled = (_filterStack.containsVideoSource);
}

- (void)_handleAVCaptureSessionWasInterruptedNotification:(NSNotification *)notification
{
    [self _stopWriting];
}

- (void)_handleUIApplicationDidEnterBackgroundNotification:(NSNotification *)notification
{
    [self _stopWriting];
}

- (void)_showAlertViewWithMessage:(NSString *)message title:(NSString *)title
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
        [alert show];
    });
}

- (void)_showAlertViewWithMessage:(NSString *)message
{
    [self _showAlertViewWithMessage:message title:@"Error"];
}


#pragma mark - Delegate methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDesc);
    
    // write the audio data if it's from the audio connection
    if (mediaType == kCMMediaType_Audio)
    {
        CMFormatDescriptionRef tmpDesc = _currentAudioSampleBufferFormatDescription;
        _currentAudioSampleBufferFormatDescription = formatDesc;
        CFRetain(_currentAudioSampleBufferFormatDescription);
        
        if (tmpDesc)
            CFRelease(tmpDesc);
        
        // we need to retain the sample buffer to keep it alive across the different queues (threads)
        if (_assetWriter &&
            _assetWriterAudioInput.readyForMoreMediaData &&
            ![_assetWriterAudioInput appendSampleBuffer:sampleBuffer])
        {
            [self _showAlertViewWithMessage:@"Cannot write audio data, recording aborted"];
            [self _abortWriting];
        }
        
        return;
    }
    
    // if not from the audio capture connection, handle video writing    
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    [_frameRateCalculator calculateFramerateAtTimestamp:timestamp];
    
    // update the video dimensions information
    _currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDesc);
    
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];    
    
    // run the filter through the filter chain
    CIImage *filteredImage = RunFilter(sourceImage, _activeFilters);
    
    CGRect sourceExtent = sourceImage.extent;
    
    CGFloat sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
    CGFloat previewAspect = _videoPreviewViewBounds.size.width  / _videoPreviewViewBounds.size.height;

    // we want to maintain the aspect radio of the screen size, so we clip the video image
    CGRect drawRect = sourceExtent;
    if (sourceAspect > previewAspect)
    {
        // use full height of the video image, and center crop the width
        drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect) / 2.0;
        drawRect.size.width = drawRect.size.height * previewAspect;
    }
    else
    {
        // use full width of the video image, and center crop the height
        drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspect) / 2.0;
        drawRect.size.height = drawRect.size.width / previewAspect;
    }

    if (_assetWriter == nil)
    {
        [_videoPreviewView bindDrawable];
        
        if (_eaglContext != [EAGLContext currentContext])
            [EAGLContext setCurrentContext:_eaglContext];
        
        // clear eagl view to grey
        glClearColor(0.5, 0.5, 0.5, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        // set the blend mode to "source over" so that CI will use that
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        if (filteredImage)
            [_ciContext drawImage:filteredImage inRect:_videoPreviewViewBounds fromRect:drawRect];
        
        [_videoPreviewView display];
    }
    else
    {
        // if we need to write video and haven't started yet, start writing
        if (!_videoWritingStarted)
        {
            _videoWritingStarted = YES;
            BOOL success = [_assetWriter startWriting];
            if (!success)
            {
                [self _showAlertViewWithMessage:@"Cannot write video data, recording aborted"];
                [self _abortWriting];
                return;
            }
            
            [_assetWriter startSessionAtSourceTime:timestamp];
            _videoWrtingStartTime = timestamp;
            self.currentVideoTime = _videoWrtingStartTime;
        }
        
        CVPixelBufferRef renderedOutputPixelBuffer = NULL;
        
        OSStatus err = CVPixelBufferPoolCreatePixelBuffer(nil, _assetWriterInputPixelBufferAdaptor.pixelBufferPool, &renderedOutputPixelBuffer);
        if (err)
        {
            NSLog(@"Cannot obtain a pixel buffer from the buffer pool");
            return;
        }
        
        // render the filtered image back to the pixel buffer (no locking needed as CIContext's render method will do that
        if (filteredImage)
            [_ciContext render:filteredImage toCVPixelBuffer:renderedOutputPixelBuffer bounds:[filteredImage extent] colorSpace:sDeviceRgbColorSpace];

        // pass option nil to enable color matching at the output, otherwise the color will be off
        CIImage *drawImage = [CIImage imageWithCVPixelBuffer:renderedOutputPixelBuffer options:nil];
        
        [_videoPreviewView bindDrawable];
        [_ciContext drawImage:drawImage inRect:_videoPreviewViewBounds fromRect:drawRect];
        [_videoPreviewView display];

        
        self.currentVideoTime = timestamp;                
        
        // write the video data
        if (_assetWriterVideoInput.readyForMoreMediaData)           
            [_assetWriterInputPixelBufferAdaptor appendPixelBuffer:renderedOutputPixelBuffer withPresentationTime:timestamp];

        CVPixelBufferRelease(renderedOutputPixelBuffer);
    }
}


- (void)filterListEditorDidDismiss
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    [self dismissViewControllerAnimated:YES completion: ^(void){
        self.recordStopButton.enabled = (_filterStack.containsVideoSource);
    }];
}

- (void) settingsDidDismiss
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    [self dismissViewControllerAnimated:YES completion: ^(void){
        self.recordStopButton.enabled = (_filterStack.containsVideoSource);
    }];
}
@end
