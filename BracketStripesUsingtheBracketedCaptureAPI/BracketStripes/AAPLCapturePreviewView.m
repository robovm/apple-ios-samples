/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
         Camera preview view, with automatic "flash" animation
     
 */
#import "AAPLCapturePreviewView.h"


// Keypath for when still image capture is taking place
static NSString *kCapturingStillImageKeypath = @"capturingStillImage";


@implementation AAPLCapturePreviewView {

    UIView *_flashView;
    AVCaptureVideoPreviewLayer *_previewLayer;
    AVCaptureOutput *_captureOutput;
}


- (void)configureCaptureSession:(AVCaptureSession *)captureSession
                  captureOutput:(AVCaptureOutput *)captureOutput
{
    if (_previewLayer) {
        [_previewLayer removeFromSuperlayer];
        _previewLayer = nil;
    }

    // Add preview layer
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    _previewLayer.frame = self.bounds;
    [self.layer addSublayer:_previewLayer];

    // Visually animate still image capture
    _captureOutput = captureOutput;
    [_captureOutput addObserver:self forKeyPath:kCapturingStillImageKeypath options:NSKeyValueObservingOptionNew context:NULL];
}


- (void)dealloc
{
    [_captureOutput removeObserver:self forKeyPath:kCapturingStillImageKeypath];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    // Still image capture state
    if ( (object == _captureOutput) &&
         [keyPath isEqualToString:kCapturingStillImageKeypath] ) {

        NSNumber *value = change[NSKeyValueChangeNewKey];
        [self _animateVisualShutter:[value boolValue]];
        return;
    }

    // Unhandled, pass up the chain
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


- (void)_animateVisualShutter:(BOOL)start
{
    if (start) {
        [_flashView removeFromSuperview];

        _flashView = [[UIView alloc] initWithFrame:self.bounds];
        _flashView.backgroundColor = [UIColor whiteColor];
        _flashView.alpha = 0.0;
        [self addSubview:_flashView];

        [UIView animateWithDuration:0.1 animations:^{
            _flashView.alpha = 1.0;
        }];
    }
    else {

        [UIView animateWithDuration:0.1 animations:^{
            _flashView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [_flashView removeFromSuperview];
            _flashView = nil;
        }];
    }
}

@end
