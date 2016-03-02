/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The DistortionViewController class provides specific UI Elements to interact with the AVAudioUnitDistortion object.
  
                 UISlider *distortionWetDrySlider;   Set the wet/dry mix of the current reverb preset
                 UIPickerView *distortionTypePicker; Select a preset for the unit
*/

@import AudioToolbox;

#import "DistortionViewController.h"

@interface DistortionViewController ()

@property (unsafe_unretained, nonatomic) IBOutlet UISlider *distortionWetDrySlider;

@end

@implementation DistortionViewController

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
    self.distortionWetDrySlider.value = self.audioEngine.distortionWetDryMix;
}

- (IBAction)setWetDryMix:(id)sender {
    self.audioEngine.distortionWetDryMix = ((UISlider *)sender).value;
}

@end
