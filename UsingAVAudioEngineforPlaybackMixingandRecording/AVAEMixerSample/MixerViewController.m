/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The MixerViewController class provides specific UI Elements to interact with the AVAudioEngine mainMixerNode object.
  
                 CAUITransportButton *recordButton;          Installs a tap on the output bus for the mixer and records to a file
                 UISlider            *masterVolumeSlider;    Sets the output volume of the mixer
*/

#import "MixerViewController.h"
#import "CAUITransportButton.h"

@interface MixerViewController ()

@property (unsafe_unretained, nonatomic) IBOutlet CAUITransportButton *recordButton;
@property (unsafe_unretained, nonatomic) IBOutlet UISlider *masterVolumeSlider;

@property (getter=isRecording) BOOL recording;

@end

@implementation MixerViewController

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
    self.masterVolumeSlider.value   = self.audioEngine.outputVolume;
    self.recordButton.drawingStyle = recordButtonStyle;
    self.recordButton.fillColor = [UIColor colorWithRed:255/255.0 green:102/255.0 blue:102/255.0 alpha:1].CGColor;
}

- (IBAction)setMasterVolume:(id)sender {
    self.audioEngine.outputVolume = ((UISlider *)sender).value;
}

- (IBAction)recordAction:(id)sender {
    self.recording = !self.recording;
    
    if (self.recording)
        [self.audioEngine startRecordingMixerOutput];
    else
        [self.audioEngine stopRecordingMixerOutput];
    
    self.recordButton.drawingStyle = self.recording ? recordEnabledButtonStyle : recordButtonStyle;
}


@end
