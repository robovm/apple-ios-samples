/*
     File: MyViewController.h 
 Abstract: The main view controller of this app 
  Version: 1.1.1 
  
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
  
 Copyright (C) 2013 Apple Inc. All Rights Reserved. 
  
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