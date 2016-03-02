/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The PlayerViewController class provides specific UI Elements to interact with the PlayerNode.
  
             UISlider            *playerVolumeSlider;    Sets the volume on the player
             UISlider            *playerPanSlider;       Sets the pan on the player
             UIButton            *playerPlayButton;      Toggles the player state
             UISegmentedControl  *playerSegmentControl;  Provides a selection for different buffers/files
*/

#import "PlayerViewController.h"

@interface PlayerViewController ()

@property (unsafe_unretained, nonatomic) IBOutlet UISlider *playerVolumeSlider;
@property (unsafe_unretained, nonatomic) IBOutlet UISlider *playerPanSlider;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *playerPlayButton;
@property (unsafe_unretained, nonatomic) IBOutlet UISegmentedControl *playerSegmentControl;

@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableToggle:) name:kRecordingCompletedNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)toggleBuffer:(id)sender
{
    [self.audioEngine toggleBuffer:((UISegmentedControl *)sender).selectedSegmentIndex];
}

- (IBAction)togglePlay:(id)sender
{
    [self.audioEngine togglePlayer];
    [self styleButton: _playerPlayButton isPlaying: self.audioEngine.playerIsPlaying];
}

- (IBAction)setVolume:(id)sender
{
    self.audioEngine.playerVolume = ((UISlider *)sender).value;
}

- (IBAction)setPan:(id)sender
{
    self.audioEngine.playerPan = ((UISlider *)sender).value;
}

- (void)enableToggle:(NSNotification*)notification
{
    [self.playerSegmentControl setEnabled:YES forSegmentAtIndex:1];
}

- (void)updateUIElements
{
    [self styleButton: _playerPlayButton isPlaying: self.audioEngine.playerIsPlaying];
}


@end
