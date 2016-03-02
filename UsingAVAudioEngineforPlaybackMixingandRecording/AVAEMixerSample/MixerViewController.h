/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The MixerViewController class provides specific UI Elements to interact with the AVAudioEngine mainMixerNode object.
     
                    CAUITransportButton *recordButton;          Installs a tap on the output bus for the mixer and records to a file
                    UISlider            *masterVolumeSlider;    Sets the output volume of the mixer
*/

#import "AudioViewController.h"

@interface MixerViewController : AudioViewController

@end
