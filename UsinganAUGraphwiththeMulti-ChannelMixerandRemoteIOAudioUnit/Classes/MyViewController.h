/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The main view controller of this app
*/

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "MultichannelMixerController.h"

@interface MyViewController : UIViewController
{
	IBOutlet UIView		*instructionsView;
    IBOutlet UIWebView 	*webView;
    IBOutlet UIView		*contentView;
    
    UIBarButtonItem 	*flipButton;
	UIBarButtonItem 	*doneButton;
    
    IBOutlet UIButton 	*startButton;
    
    IBOutlet UISwitch   *bus0Switch;
    IBOutlet UISlider   *bus0VolumeSlider;
    IBOutlet UISwitch   *bus1Switch;
    IBOutlet UISlider   *bus1VolumeSlider;
    IBOutlet UISlider   *outputVolumeSlider;
   
    IBOutlet MultichannelMixerController *mixerController;
}

@property (readonly, nonatomic) UIView    *instructionsView;
@property (readonly, nonatomic) UIWebView *webView;
@property (readonly, nonatomic) UIView 	  *contentView;

@property (nonatomic, retain) UIBarButtonItem *flipButton;
@property (nonatomic, retain) UIBarButtonItem *doneButton;

@property (readonly, nonatomic) UIButton *startButton;

@property (readonly, nonatomic) UISwitch *bus0Switch;
@property (readonly, nonatomic) UISlider *bus0VolumeSlider;
@property (readonly, nonatomic) UISwitch *bus1Switch;
@property (readonly, nonatomic) UISlider *bus1VolumeSlider;
@property (readonly, nonatomic) UISlider *outputVolumeSlider;

@property (readonly, nonatomic)MultichannelMixerController *mixerController;

- (void)setUIDefaults;
- (void)stopForInterruption;

- (IBAction)enableInput:(UISwitch *)sender;
- (IBAction)setInputVolume:(UISlider *)sender;
- (IBAction)setOutputVolume:(UISlider *)sender;

- (IBAction)doSomethingAction:(id)sender;

@end