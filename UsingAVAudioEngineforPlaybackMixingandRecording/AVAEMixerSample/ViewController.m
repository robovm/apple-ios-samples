/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    View Controller class that drives the UI
*/

#import "ViewController.h"
#import "AudioEngine.h"
#import "CAUITransportButton.h"

@interface ViewController () <AudioEngineDelegate>

@end

#define kRoundedCornerRadius    10


@implementation ViewController
            
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    engine = [[AudioEngine alloc] init];
    engine.delegate = self;
    
    [self updateUIElements];
}

- (void)updateUIElements
{
    // update UI
    _marimbaVolumeSlider.value   = engine.marimbaPlayerVolume;
    _marimbaPanSlider.value      = engine.marimbaPlayerPan;
    
    _drumsVolumeSlider.value    = engine.drumPlayerVolume;
    _drumsPanSlider.value       = engine.drumPlayerPan;
    
    _delayWetDrySlider.value    = engine.delayWetDryMix;
    _reverbWetDrySlider.value = engine.reverbWetDryMix;
    
    _masterVolumeSlider.value   = engine.outputVolume;
    
    _marimbaPlayButton.layer.cornerRadius = 5;
    _drumsPlayButton.layer.cornerRadius = 5;
    
    [self styleButton: _marimbaPlayButton isPlaying: engine.marimbaPlayerIsPlaying];
    [self styleButton: _drumsPlayButton isPlaying: engine.drumPlayerIsPlaying];
    
    _shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
    _shadowView.layer.shadowRadius = 10.0f;
    _shadowView.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    _shadowView.layer.shadowOpacity = 0.5f;
    
    _rewindButton.drawingStyle = rewindButtonStyle;
    _rewindButton.fillColor = [UIColor whiteColor].CGColor;
    _rewindButton.enabled = NO;
    _rewindButton.alpha = _rewindButton.enabled ? 1 : .25;
    
    _playButton.drawingStyle = playButtonStyle;
    _playButton.fillColor = [UIColor whiteColor].CGColor;
    _playButton.enabled = NO;
    _playButton.alpha = _playButton.enabled ? 1 : .25;
    
    _recordButton.drawingStyle = recordButtonStyle;
    _recordButton.fillColor = [UIColor redColor].CGColor;
    
    [self updateButtonStates];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)styleButton:(UIButton *)button isPlaying:(BOOL)isPlaying {
    if (isPlaying) {
        [button setTitle: @"Stop" forState: UIControlStateNormal];
        button.layer.backgroundColor = button.tintColor.CGColor;
        button.layer.borderWidth = 0;
        [button setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    } else {
        [button setTitle: @"Play" forState: UIControlStateNormal];
        button.layer.backgroundColor = [UIColor clearColor].CGColor;
        button.layer.borderWidth = 2;
        [button setTitleColor: button.tintColor forState: UIControlStateNormal];
        button.layer.borderColor = button.tintColor.CGColor;
    }
}

- (void)engineConfigurationHasChanged
{
    [self updateUIElements];
}

- (void)engineWasInterrupted
{
    _playing = NO;
    _recording = NO;
    [self updateUIElements];
}

- (IBAction)togglePlayMarimba:(id)sender {
    [engine toggleMarimba];
    
    [self styleButton: _marimbaPlayButton isPlaying: engine.marimbaPlayerIsPlaying];
}
    
- (IBAction)setMarimbaVolume:(id)sender {
    engine.marimbaPlayerVolume = ((UISlider *)sender).value;
}

- (IBAction)setMarimbaPan:(id)sender {
    engine.marimbaPlayerPan = ((UISlider *)sender).value;
}

- (IBAction)togglePlayDrums:(id)sender {
    [engine toggleDrums];
    
    [self styleButton: _drumsPlayButton isPlaying: engine.drumPlayerIsPlaying];
}

- (IBAction)setDrumVolume:(id)sender {
    engine.drumPlayerVolume = ((UISlider *)sender).value;
}

- (IBAction)setDrumPan:(id)sender {
    engine.drumPlayerPan = ((UISlider *)sender).value;
    
}

-(void) updateButtonStates {
    _recordButton.drawingStyle = _recording ? recordEnabledButtonStyle : recordButtonStyle;
    
    _playButton.enabled = _rewindButton.enabled = _canPlayback;
    _playButton.alpha = _playButton.enabled ? 1 : .25;
    _rewindButton.alpha = _rewindButton.enabled ? 1 : .25;
    
    _playButton.drawingStyle = _playing ? pauseButtonStyle : playButtonStyle;
}

- (void)mixerOutputFilePlayerHasStopped
{
    _playing = NO;
    [self updateButtonStates];
}

- (IBAction)rewindAction:(id)sender {
    // rewind stops playback and recording
    _recording = NO;
    _playing = NO;
    
    [engine stopPlayingRecordedFile];
    [engine stopRecordingMixerOutput];
    [self updateButtonStates];
}

- (IBAction)playPauseAction:(id)sender {
    // playing/pausing stops recording toggles playback state
    _recording = NO;
    _playing = !_playing;
    
    [engine stopRecordingMixerOutput];
    if (_playing) [engine playRecordedFile];
    else [engine pausePlayingRecordedFile];
    [self updateButtonStates];
}

- (IBAction)recordAction:(id)sender {
    // recording stops playback and recording if we are already recording
    _playing = NO;
    _recording = !_recording;
    _canPlayback = YES;
    
    [engine stopPlayingRecordedFile];
    if (_recording) [engine startRecordingMixerOutput];
    else [engine stopRecordingMixerOutput];
    [self updateButtonStates];
}

- (IBAction)setReverbMix:(id)sender {
    engine.reverbWetDryMix = ((UISlider *)sender).value;
}

- (IBAction)setDelayMix:(id)sender {
    engine.delayWetDryMix = ((UISlider *)sender).value;
}

- (IBAction)setMasterVolume:(id)sender {
    engine.outputVolume = ((UISlider *)sender).value;
}
@end
