/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The InstrumentViewController class provides specific UI Elements to interact with the AVAudioSequencer object. The sequencer is not directly part of AVAudioEngine.
  
                     UISlider *samplerDirectVolumeSlider;    Sets the volume of the instrument using AVAudioMixingDestination
                     UISlider *reverbVolumeSlider;           Sets the volume of the instrument using AVAudioMixingDestination
*/

#import "InstrumentViewController.h"

@interface InstrumentViewController ()

@property (unsafe_unretained, nonatomic) IBOutlet UISlider *directVolumeSlider;
@property (unsafe_unretained, nonatomic) IBOutlet UISlider *effectVolumeSlider;

@end

@implementation InstrumentViewController

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
    self.directVolumeSlider.value = self.audioEngine.samplerDirectVolume;
    self.effectVolumeSlider.value = self.audioEngine.samplerEffectVolume;
}

- (IBAction)setSamplerDirectVolume:(id)sender {
    self.audioEngine.samplerDirectVolume = ((UISlider *)sender).value;
}

- (IBAction)setEffectVolime:(id)sender {
    self.audioEngine.samplerEffectVolume = ((UISlider *)sender).value;
}


@end
