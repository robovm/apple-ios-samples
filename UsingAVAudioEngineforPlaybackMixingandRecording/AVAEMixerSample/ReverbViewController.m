/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The ReverbViewController class provides specific UI Elements to interact with the AVAudioUnitReverb object.
  
                 UISlider *reverbWetDrySlider;   Set the wet/dry mix of the current reverb preset
                 UIPickerView *reverbTypePicker; Select a preset for the unit
*/

@import AudioToolbox;

#import "ReverbViewController.h"

@interface ReverbViewController ()

@property (unsafe_unretained, nonatomic) IBOutlet UISlider *reverbWetDrySlider;

@end

@implementation ReverbViewController

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
    self.reverbWetDrySlider.value = self.audioEngine.reverbWetDryMix;
}

- (IBAction)setWetDryMix:(id)sender {
    self.audioEngine.reverbWetDryMix = ((UISlider *)sender).value;
}

@end
