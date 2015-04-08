/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    AudioEngine is the main controller class that creates the following objects:
                    AVAudioEngine       *_engine;
                    AVAudioPlayerNode   *_marimbaPlayer;
                    AVAudioPlayerNode   *_drumPlayer;
                    AVAudioUnitDelay    *_delay;
                    AVAudioUnitReverb   *_reverb;
                    AVAudioPCMBuffer    *_marimbaLoopBuffer;
                    AVAudioPCMBuffer    *_drumLoopBuffer;
                    
                 It connects all the nodes, loads the buffers as well as controls the AVAudioEngine object itself.
*/

@import Foundation;

// effect strip 1 - Marimba Player -> Delay -> Mixer
// effect strip 2 - Drum Player -> Distortion -> Mixer

@protocol AudioEngineDelegate <NSObject>

@optional
- (void)engineConfigurationHasChanged;
- (void)mixerOutputFilePlayerHasStopped;

@end

@interface AudioEngine : NSObject

@property (nonatomic, readonly) BOOL marimbaPlayerIsPlaying;
@property (nonatomic, readonly) BOOL drumPlayerIsPlaying;

@property (nonatomic) float marimbaPlayerVolume;    // 0.0 - 1.0
@property (nonatomic) float drumPlayerVolume;       // 0.0 - 1.0

@property (nonatomic) float marimbaPlayerPan;       // -1.0 - 1.0
@property (nonatomic) float drumPlayerPan;          // -1.0 - 1.0

@property (nonatomic) float delayWetDryMix;         // 0.0 - 1.0
@property (nonatomic) BOOL bypassDelay;

@property (nonatomic) float reverbWetDryMix;        // 0.0 - 1.0
@property (nonatomic) BOOL bypassReverb;

@property (nonatomic) float outputVolume;           // 0.0 - 1.0

@property (weak) id<AudioEngineDelegate> delegate;


- (void)toggleMarimba;
- (void)toggleDrums;

- (void)startRecordingMixerOutput;
- (void)stopRecordingMixerOutput;
- (void)playRecordedFile;
- (void)pausePlayingRecordedFile;
- (void)stopPlayingRecordedFile;

@end
