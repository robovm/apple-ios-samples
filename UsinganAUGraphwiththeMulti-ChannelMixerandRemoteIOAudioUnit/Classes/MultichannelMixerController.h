/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The Controller Class for the AUGraph.
*/

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVAudioFormat.h>

#import "CAComponentDescription.h"

#define MAXBUFS  2
#define NUMFILES 2

typedef struct {
    AudioStreamBasicDescription asbd;
    Float32 *data;
	UInt32 numFrames;
	UInt32 sampleNum;
} SoundBuffer, *SoundBufferPtr;

@interface MultichannelMixerController : NSObject
{
    CFURLRef sourceURL[2];
    
    AVAudioFormat *mAudioFormat;
    
	AUGraph   mGraph;
	AudioUnit mMixer;
    AudioUnit mOutput;
    
    SoundBuffer mSoundBuffer[MAXBUFS];

	Boolean isPlaying;
}

@property (readonly, nonatomic) Boolean isPlaying;

- (void)initializeAUGraph;

- (void)enableInput:(UInt32)inputNum isOn:(AudioUnitParameterValue)isONValue;
- (void)setInputVolume:(UInt32)inputNum value:(AudioUnitParameterValue)value;
- (void)setOutputVolume:(AudioUnitParameterValue)value;

- (void)startAUGraph;
- (void)stopAUGraph;

@end
