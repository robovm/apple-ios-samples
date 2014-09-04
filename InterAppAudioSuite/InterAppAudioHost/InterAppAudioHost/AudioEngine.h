/*
     File: AudioEngine.h
 Abstract: 
  Version: 1.1.2
 
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioUnit/AudioComponent.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioFile.h>
#import <AudioUnit/AudioUnitProperties.h>
#import <CoreFoundation/CFNotificationCenter.h>
#import <AudioToolbox/AUGraph.h>

#import "CAAudioUnitOutputCapturer.h"
#import "CAStreamBasicDescription.h"
#import "CAUIKeyboardView.h"

NSString *formattedTimeStringForFrameCount(UInt64 inFrameCount, Float64 inSampleRate, BOOL inShowMilliseconds);
void displayAlertDialog(NSString *title, NSString *message);

#define Check(expr) do { OSStatus err = (expr); if (err) { NSLog(@"error %d from %s", (int)err, #expr); abort(); } } while (0)
#define NSCheck(expr) do { NSError *err = nil; if (!(expr)) { NSLog(@"error from %s: %@", #expr, err);  abort(); } } while (0)

//Notification to refresh the transport UI. Fired when engine state has changed
FOUNDATION_EXPORT NSString * const kTransportStateChangedNotification;

//Midi related constants
enum {
	kMidiMessage_ControlChange 		= 0xB,
	kMidiMessage_ProgramChange 		= 0xC,
	kMidiMessage_BankMSBControl 	= 0,
	kMidiMessage_BankLSBControl		= 32,
	kMidiMessage_NoteOn 			= 0x9,
	kMidiMessage_NoteOff			= 0x8,
	kMidiController_AllNotesOff		= 123
};

//Transport state enum
typedef NS_ENUM(NSInteger, TransportState) {
    TransportStateRecording = 0,
    TransportStatePlaying,
    TransportStatePaused,
    TransportStateStopped
};

//Structure used to playback audio files with audio units
typedef struct AUGraphPlayer {
    AudioStreamBasicDescription inputFormat;
    AudioFileID                 inputFile;
    AUGraph                     graph;
    AudioUnit                   fileAU;
}AUGraphPlayer;
    
//object representing a remote audio unit
@interface RemoteAU : NSObject {
@public
    AudioComponentDescription _desc;
    AudioComponent _comp;
    NSString *_name;
    UIImage *_image;
}
@end
    
//Close a view once we are done with it
@protocol ReturnToParentViewControllerDelegate <NSObject>
- (void) closeView;
@end

@protocol AudioEngineDelegate;

@interface AudioEngine : NSObject<CAUIKeyboardEngine> {
@private
    NSMutableArray *_remoteEffects;
    NSMutableArray *_connectedNodes;
	
    AUGraph		hostGraph;
	AudioUnit	instrument;
	AudioUnit	effect;
	AudioUnit	mixerUnit;
    AudioUnit	outputUnit;
    AudioUnit	filePlayerUnit;
	
	AUNode		outNode, instrumentNode, mixerNode, filePlayerNode, effectNode;

    UInt32		busCount;		// bus count for mixer unit input
    UInt32		playerBus;		// mixer unit bus 0 will be stereo and will take the filePlayer
    UInt32		remoteBus;		// mixer unit bus 1 will be stereo and will take the remote instrument/effects
	
	NSURL						*fileURL;
    AUGraphPlayer				filePlayer;
    CAAudioUnitOutputCapturer	*recorder;
	
    AudioStreamBasicDescription stereoStreamFormat;
    CAStreamBasicDescription	tapFormat;
	
    SInt64 durationOfFile;
    TransportState state;
    
	Boolean _engineStarted, graphStarted;
	bool canPlay, canRewind;
    
    /*Key: name of class that block comes from. Value: function to be called when engine changes  */
    NSMutableDictionary *_engineObservers;
	
	ScheduledAudioFileRegion    mScheduledRegion;
    SInt64						mTranslatedLastTimeRendered;
    SInt64						mInitialRegionOffset;
}

// Graph Interrogation Methods
- (NSUInteger) getNumberOfConnectedNodes;
- (RemoteAU *) getNodeAt:(int) index;
- (BOOL) isRemoteInstrumentConnected;
- (BOOL) isRemoteEffectConnected;
- (void) gotoRemoteInstrument;
- (void) gotoRemoteEffect;
- (void) disconnectInstrument;
- (void) disconnectEffect;
- (void) destroyRemoteAU:(AudioUnit) remoteAU;
- (BOOL) addRemoteAU:(RemoteAU *)rau;
- (void) checkStartStopGraph;

- (void) startPlaying;
- (void) stopPlaying;
- (void) stopRecording;

- (BOOL) canRewind;
- (BOOL) canPlay;
- (BOOL) canRecord;

- (BOOL) isPlaying;
- (BOOL) isPaused;
- (BOOL) isRecording;

- (void) rewind;
- (void) togglePlay;
- (void) toggleRecord;
- (void) seekPlayheadTo:(CGFloat) position;

- (void) synchronizeFilePlayerState:(BOOL) fromTimer;
- (SInt64) getAmountPlayed;
- (NSString *) getDurationString;
- (NSString *) getPlayTimeString;
- (float) getPlayProgress;

- (void) addEngineObserver:(dispatch_block_t) inObserver key:(NSString*) inKey;
- (void) notifyObservers;

@end
