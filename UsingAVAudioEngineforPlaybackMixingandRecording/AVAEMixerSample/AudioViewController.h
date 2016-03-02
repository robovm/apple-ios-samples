/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This class represents a node/sequencer.
                    It contains -
                        A reference to the AudioEngine
                        Basic Views for displaying parameters. Subclasses can provide their own views for customization
 */

@import UIKit;

#import "AudioEngine.h"
#import "CAAVAudioUnitView.h"
#import "CAAVParameterView.h"

@interface AudioViewController : UIViewController

@property (strong) AudioEngine *audioEngine;

@property (weak, nonatomic) IBOutlet UIView *titleView;
@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet CAAVParameterView *parameterView;

- (void)updateUIElements;
- (void)styleButton:(UIButton *)button isPlaying:(BOOL)isPlaying;

@end
