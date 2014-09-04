/*
     File: Delay.h
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
#import <AudioToolbox/AUGraph.h>

#import <AudioUnit/AudioComponent.h>
#import <AudioUnit/AudioUnitProperties.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVAudioSession.h>

#import "CAUITransportView.h"

@interface Delay : NSObject<CAUITransportEngine>  {
    AUGraph		delayGraph;
	AudioUnit	delayUnit;
    AudioUnit	outputUnit;
    AUNode		delayNode, outNode;
    BOOL		inForeground;
    Boolean     graphStarted;
    HostCallbackInfo *callBackInfo;   
    
    AudioStreamBasicDescription stereoStreamFormat;
}

@property (strong, nonatomic) UIImage *audioUnitIcon;
@property (nonatomic) BOOL playing;
@property (nonatomic) BOOL recording;
@property (nonatomic) BOOL connected;
@property (nonatomic) Float64 playTime;

#if defined(__cplusplus)
extern "C"
#endif
NSString *formattedTimeStringForFrameCount(UInt64 inFrameCount, Float64 inSampleRate, BOOL inShowMilliseconds);

/* @property delayTime
 	Time taken by the delayed input signal to reach the output
*/
@property (nonatomic) NSTimeInterval delayTime;

/* @property feedback
 	Amount of the output signal fed back into the delay line
*/
@property (nonatomic) float feedback;

/* @property lowPassCutoff
 	Cutoff frequency above which high frequency content is rolled off
*/
@property (nonatomic) float lowPassCutoff;

/* @property wetDryMix
 	Blend of the wet and dry signals
*/
@property (nonatomic) float wetDryMix;

- (void) audioUnitPropertyChangedListener: (void *) inObject unit: (AudioUnit) inUnit propID: (AudioUnitPropertyID) inID scope: (AudioUnitScope) inScope element: (AudioUnitElement) inElement;

/* Delay effect related setters */
- (void) setWetDryMix: (float) wetDryMix;
- (void) setDelayTime: (NSTimeInterval) delayTime;
- (void) setFeedback: (float) feedback;
- (void) setLowPassCutoff: (float) lowPassCutoff;

//Set float values on the audio unit directly
- (BOOL) setValue:(float)value forParam:(AudioUnitParameterID) paramID;

- (int) getWetDryTag;
- (int) getDelayTag;
- (int) getFeedbackTag;
- (int) getLowPassCutoffTag;
- (float) getMinValueForParam: (AudioUnitParameterID) paramID;
- (float) getMaxValueForParam: (AudioUnitParameterID) paramID;
@end
