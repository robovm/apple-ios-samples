/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
         Camera view controller
     
 */

@import AVFoundation;
@import CoreMedia;

#import "AAPLCameraViewController.h"
#import "AAPLStripedImage.h"
#import "AAPLCapturePreviewView.h"
#import "AAPLImageViewController.h"


// Completion handler prototypes
typedef void(^AAPLCompletion)(BOOL success);
typedef void(^AAPLCompletionWithError)(BOOL success, NSError *error);
typedef void(^AAPLCompletionWithImage)(UIImage *image);


@interface AAPLCameraViewController () <AAPLImageViewDelegate>

// Convenience for enable/disable UI controls
@property (nonatomic, assign) BOOL userInterfaceEnabled;

@end


@implementation AAPLCameraViewController {

    // Capture
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_captureDevice;
    AVCaptureDeviceFormat *_captureDeviceFormat;
    AVCaptureStillImageOutput *_stillImageOutput;

    // Brackets
    NSUInteger _maxBracketCount;
    NSArray *_bracketSettings;

    // UI
    IBOutlet AAPLCapturePreviewView *_cameraPreviewView;
    IBOutlet UIButton *_cameraShutterButton;
    IBOutlet UISegmentedControl *_bracketModeControl;

    // Striped rendered brackets
    AAPLStripedImage *_imageStripes;
}


- (void)setUserInterfaceEnabled:(BOOL)userInterfaceEnabled
{
    _cameraShutterButton.enabled =
    _bracketModeControl.enabled =
        userInterfaceEnabled;
}


- (BOOL)userInterfaceEnabled
{
    return _cameraShutterButton.enabled;
}


- (AVCaptureDevice *)_cameraDeviceForPosition:(AVCaptureDevicePosition)position
{
    for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
        if (device.position == position) {
            return device;
        }
    }

    return nil;
}


- (void)_showErrorMessage:(NSString *)message title:(NSString *)title
{
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = title;
    alert.message = message;

    [alert addButtonWithTitle:NSLocalizedString(@"title-ok", @"OK Button Title")];
    [alert show];
}


- (void)_startCameraWithCompletionHandler:(AAPLCompletionWithError)completion
{
    // Capture session
    _captureSession = [[AVCaptureSession alloc] init];

    [_captureSession beginConfiguration];

    // Obtain back facing camera
    _captureDevice = [self _cameraDeviceForPosition:AVCaptureDevicePositionBack];
    if (!_captureDevice) {
        NSString *message = NSLocalizedString(@"message-back-camera-not-found", @"Error message back camera - not found");
        NSString *title = NSLocalizedString(@"title-back-camera-not-found", @"Error title back camera - not found");
        [self _showErrorMessage:message title:title];
        return;
    }

    NSError *error = nil;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    if (!deviceInput) {
        NSLog(@"This error should be handled appropriately in your app -- obtain device input: %@", error);
        NSString *message = NSLocalizedString(@"message-back-camera-open-failed", @"Error message back camera - can't open.");
        NSString *title = NSLocalizedString(@"title-back-camera-open-failed", @"Error title for back camera - can't open.");
        [self _showErrorMessage:message title:title];
        return;
    }
    [_captureSession addInput:deviceInput];

    // Still image output
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [_stillImageOutput setOutputSettings:@{
        // JPEG output
        AVVideoCodecKey: AVVideoCodecJPEG
       /*
        * Or instead of JPEG, we can use one of the following pixel formats:
        *
        // BGRA
        (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
        *
        // 420f output
        (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        *
        */
    }];
    [_captureSession addOutput:_stillImageOutput];

    // Capture preview
    [_cameraPreviewView configureCaptureSession:_captureSession captureOutput:_stillImageOutput];

    // Configure for high resolution still image photography
    [_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];

    // Track the device's active format (we don't change this later)
    _captureDeviceFormat = _captureDevice.activeFormat;

    [_captureSession commitConfiguration];

    // Start the AV session
    [_captureSession startRunning];

    // We make sure not to exceed the maximum number of supported brackets
    _maxBracketCount = [_stillImageOutput maxBracketedCaptureStillImageCount];

    // Construct capture bracket settings and warmup
    [self _prepareBracketsWithCompletionHandler:completion];
}


- (void)_prepareBracketsWithCompletionHandler:(AAPLCompletionWithError)completion
{
    // Construct the list of brackets
    switch (_bracketModeControl.selectedSegmentIndex) {
        case 0:
            NSLog(@"Configuring auto-exposure brackets...");
            _bracketSettings = [self _exposureBrackets];
            break;

        case 1:
            NSLog(@"Configuring duration/ISO brackets...");
            _bracketSettings = [self _durationISOBrackets];
            break;
    }

    // Prime striped image buffer
    const CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions([[_captureDevice activeFormat] formatDescription]);
    _imageStripes = [[AAPLStripedImage alloc] initForSize:CGSizeMake(dimensions.width, dimensions.height) stripWidth:dimensions.width/12.0 stride:[_bracketSettings count]];

    // Warm up bracketed capture
    NSLog(@"Warming brackets: %@", _bracketSettings);
    AVCaptureConnection *connection = [_stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [_stillImageOutput prepareToCaptureStillImageBracketFromConnection:connection
                                                     withSettingsArray:_bracketSettings
                                                     completionHandler:^(BOOL prepared, NSError *error) {

        completion(prepared, error);
    }];
}


- (NSArray *)_exposureBrackets
{
    NSMutableArray *brackets = [[NSMutableArray alloc] initWithCapacity:_maxBracketCount];

    // Fixed bracket settings
    const int fixedBracketCount = 3;
    const float biasValues[] = {
        -2.0, 0.0, +2.0,
    };

    for (int index = 0; index < MIN(fixedBracketCount, _maxBracketCount); index++) {

        const float biasValue = biasValues[index];

        AVCaptureAutoExposureBracketedStillImageSettings *settings = [AVCaptureAutoExposureBracketedStillImageSettings autoExposureSettingsWithExposureTargetBias:biasValue];
        [brackets addObject:settings];
    }

    return brackets;
}


- (NSArray *)_durationISOBrackets
{
    NSMutableArray *brackets = [[NSMutableArray alloc] initWithCapacity:_maxBracketCount];

    // ISO and Duration are hardware dependent
    NSLog(@"Camera device ISO range: [%.2f, %.2f]", _captureDeviceFormat.minISO, _captureDeviceFormat.maxISO);
    NSLog(@"Camera device Duration range: [%.4f, %.4f]", CMTimeGetSeconds(_captureDeviceFormat.minExposureDuration), CMTimeGetSeconds(_captureDeviceFormat.maxExposureDuration));

    // Fixed bracket settings
    const int fixedBracketCount = 3;
    const float ISOValues[] = {
        50, 60, 500,
    };
    const Float64 durationSecondsValues[] = {
        0.250, 0.050, 0.005,
    };

    for (int index = 0; index < MIN(fixedBracketCount, _maxBracketCount); index++) {

        // Clamp fixed settings to the device limits
        const float ISO = CLAMP(
            ISOValues[index],
            _captureDeviceFormat.minISO,
            _captureDeviceFormat.maxISO
        );

        const Float64 durationSeconds = CLAMP(
            durationSecondsValues[index],
            CMTimeGetSeconds(_captureDeviceFormat.minExposureDuration),
            CMTimeGetSeconds(_captureDeviceFormat.maxExposureDuration)
        );
        const CMTime duration = CMTimeMakeWithSeconds(durationSeconds, 1e3);

        // Create bracket settings
        AVCaptureManualExposureBracketedStillImageSettings *settings = [AVCaptureManualExposureBracketedStillImageSettings manualExposureSettingsWithExposureDuration:duration ISO:ISO];
        [brackets addObject:settings];
    }

    return brackets;
}


- (void)_performBrackedCaptureWithCompletionHandler:(AAPLCompletionWithImage)completion
{
    // Number of brackets to capture
    __block int todo = (int)[_bracketSettings count];

    // Number of failed bracket captures
    __block int failed = 0;

    NSLog(@"Performing bracketed capture: %@", _bracketSettings);
    AVCaptureConnection *connection = [_stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [_stillImageOutput captureStillImageBracketAsynchronouslyFromConnection:connection
                                                          withSettingsArray:_bracketSettings
                                                          completionHandler:^(
            CMSampleBufferRef sampleBuffer,
            AVCaptureBracketedStillImageSettings *stillImageSettings,
            NSError *error
        ) {
            --todo;

            if (!error) {
                NSLog(@"Bracket %@", stillImageSettings);

                // Process this sample buffer while we wait for the next bracketed image to be captured.
                // You would insert your own HDR algorithm here.
                [_imageStripes addSampleBuffer:sampleBuffer];
            }
            else {
                NSLog(@"This error should be handled appropriately in your app -- Bracket %@ ERROR: %@", stillImageSettings, error);

                ++failed;
            }

            // Return the rendered image strip when the capture completes
            if (!todo) {
                NSLog(@"All %d bracket(s) have been captured %@ error.", (int)[_bracketSettings count], (failed) ? @"with" : @"without");

                // This demo is restricted to portrait orientation for simplicity, where we hard-code the rendered striped image orientation.
                UIImage *image =
                    (!failed)
                        ? [_imageStripes imageWithOrientation:UIImageOrientationRight]
                        : nil;

                // Don't assume we're on the main thread
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(image);
                });
            }
    }];
}


- (IBAction)_bracketModeDidChange:(id)sender
{
    self.userInterfaceEnabled = NO;

    // Prepare for the new bracket settings
    [self _prepareBracketsWithCompletionHandler:^(BOOL success, NSError *error) {

        self.userInterfaceEnabled = YES;
    }];
}


- (IBAction)_cameraShutterDidPress:(id)sender
{
    if (![_captureSession isRunning]) {
        return;
    }

    self.userInterfaceEnabled = NO;

    [self _performBrackedCaptureWithCompletionHandler:^(UIImage *image) {

        AAPLImageViewController *controller = [[AAPLImageViewController alloc] initWithImage:image];
        controller.delegate = self;
        controller.title = NSLocalizedString(@"title-bracket-stripes", @"Bracket Viewer Title");

        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [self presentViewController:navController animated:YES completion:nil];
    }];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.userInterfaceEnabled = NO;

    [self _startCameraWithCompletionHandler:^(BOOL success, NSError *error) {
        if (success) {
            self.userInterfaceEnabled = YES;
        }
        else {
            NSLog(@"This error should be handled appropriately in your app -- start camera completion: %@", error);
        }
    }];
}


#pragma mark - AAPLImageViewDelegate

- (void)imageViewControllerDidFinish:(AAPLImageViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:^{
        self.userInterfaceEnabled = YES;
    }];
}

@end
