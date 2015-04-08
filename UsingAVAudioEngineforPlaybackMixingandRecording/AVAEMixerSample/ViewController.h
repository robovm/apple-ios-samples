/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    View Controller class that drives the UI
*/

@import UIKit;

@class AudioEngine, CAUITransportButton;
@interface ViewController : UIViewController {
    AudioEngine *engine;
}
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *marimbaPlayButton;
@property (unsafe_unretained, nonatomic) IBOutlet UISlider *marimbaVolumeSlider;
@property (unsafe_unretained, nonatomic) IBOutlet UISlider *marimbaPanSlider;

@property (unsafe_unretained, nonatomic) IBOutlet UIButton *drumsPlayButton;
@property (unsafe_unretained, nonatomic) IBOutlet UISlider *drumsVolumeSlider;
@property (unsafe_unretained, nonatomic) IBOutlet UISlider *drumsPanSlider;

@property (unsafe_unretained, nonatomic) IBOutlet CAUITransportButton *rewindButton;
@property (unsafe_unretained, nonatomic) IBOutlet CAUITransportButton *playButton;
@property (unsafe_unretained, nonatomic) IBOutlet CAUITransportButton *recordButton;

- (IBAction)togglePlayMarimba:(id)sender;
- (IBAction)setMarimbaVolume:(id)sender;
- (IBAction)setMarimbaPan:(id)sender;

- (IBAction)togglePlayDrums:(id)sender;
- (IBAction)setDrumVolume:(id)sender;
- (IBAction)setDrumPan:(id)sender;

- (IBAction)rewindAction:(id)sender;
- (IBAction)playPauseAction:(id)sender;
- (IBAction)recordAction:(id)sender;

@property (unsafe_unretained, nonatomic) IBOutlet UISlider *reverbWetDrySlider;
@property (unsafe_unretained, nonatomic) IBOutlet UISlider *delayWetDrySlider;

- (IBAction)setReverbMix:(id)sender;
- (IBAction)setDelayMix:(id)sender;

@property (unsafe_unretained, nonatomic) IBOutlet UISlider *masterVolumeSlider;
- (IBAction)setMasterVolume:(id)sender;

@property (unsafe_unretained, nonatomic) IBOutlet UIView *shadowView;

@property (getter=isRecording) BOOL recording;
@property (getter=isPlaying) BOOL playing;
@property BOOL canPlayback;
@end

