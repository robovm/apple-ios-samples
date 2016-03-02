/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The SequencerViewController class provides specific UI Elements to interact with the AVAudioSequencer object. The sequencer is not directly part of AVAudioEngine.
  
                 UISlider *sequencerPlaybackRateSlider;  Set the playback rate for the sequencer
                 UISlider *sequencerPositionSlider;      Set the current position for the current track
                 UIButton *sequencerPlayButton;          Toggle the state of the sequencer
*/

#import "SequencerViewController.h"

@interface SequencerViewController () {
    dispatch_source_t _sequencerPositionSliderUpdateTimer;
}

@property (unsafe_unretained, nonatomic) IBOutlet UISlider *sequencerPlaybackRateSlider;
@property (unsafe_unretained, nonatomic) IBOutlet UISlider *sequencerPositionSlider;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *sequencerPlayButton;

@end

@implementation SequencerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateUIElements
{
    self.sequencerPositionSlider.value = 0;
    [self.sequencerPositionSlider setContinuous:NO];
    self.sequencerPlaybackRateSlider.value = self.audioEngine.sequencerPlaybackRate;
    self.sequencerPlayButton.layer.cornerRadius = 5;
    [self styleButton: _sequencerPlayButton isPlaying: self.audioEngine.sequencerIsPlaying];
}

- (void)startTimer
{
    _sequencerPositionSliderUpdateTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    if (_sequencerPositionSliderUpdateTimer) {
        dispatch_source_set_timer(_sequencerPositionSliderUpdateTimer, DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_sequencerPositionSliderUpdateTimer, ^{
            _sequencerPositionSlider.value = self.audioEngine.sequencerCurrentPosition;
        });
        dispatch_resume(_sequencerPositionSliderUpdateTimer);
    }
}

- (void)stopTimer
{
    if (_sequencerPositionSliderUpdateTimer) {
        dispatch_source_cancel(_sequencerPositionSliderUpdateTimer);
        _sequencerPositionSliderUpdateTimer = nil;
    }
}

- (IBAction)togglePlaySequencer:(id)sender {
    [self.audioEngine toggleSequencer];
    
    [self styleButton: _sequencerPlayButton isPlaying: self.audioEngine.sequencerIsPlaying];
    if (self.audioEngine.sequencerIsPlaying) {
        [self startTimer];
    } else {
        [self stopTimer];
    }
}
- (IBAction)sequencerPositionSliderTouchDown:(id)sender {
    if (self.audioEngine.sequencerIsPlaying) {
        [self stopTimer];
    }
}

- (IBAction)sequencerPositionSliderValueChanged:(id)sender {
    if (self.audioEngine.sequencerIsPlaying) {
        self.audioEngine.sequencerCurrentPosition = ((UISlider *)sender).value;
        [self startTimer];
    }
}

- (IBAction)setSequencerPlaybackRate:(id)sender {
    self.audioEngine.sequencerPlaybackRate = ((UISlider *)sender).value;
}

@end
