/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	An AUAudioUnit subclass implementing a low-pass filter with resonance. Illustrates parameter management and rendering, including in-place processing and buffer management.
*/

#ifndef FilterDemo_h
#define FilterDemo_h

#import <AudioToolbox/AudioToolbox.h>

@interface AUv3FilterDemo : AUAudioUnit

- (NSArray<NSNumber *> *)magnitudesForFrequencies:(NSArray<NSNumber *> *)frequencies;

@end

#endif /* FilterDemo_h */
