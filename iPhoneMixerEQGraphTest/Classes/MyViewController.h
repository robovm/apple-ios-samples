/*
    File: MyViewController.h
Abstract: The main view controller.
 Version: 1.2.2

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

Copyright (C) 2014 Apple Inc. All Rights Reserved.

*/
 
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "AUGraphController.h"

@interface MyViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>
{
	UIView		*instructionsView;
    UIView		*eqView;
    UIWebView 	*webView;
    UIView		*contentView;
    
    UIBarButtonItem 	*infoButtonItem;
    UIBarButtonItem 	*eqButtonItem;
	UIBarButtonItem 	*doneButtonItem;
    
    IBOutlet UIButton 	*startButton;
    
    UISwitch   *bus0Switch;
    UISlider   *bus0VolumeSlider;
    UISwitch   *bus1Switch;
    UISlider   *bus1VolumeSlider;
    UISlider   *outputVolumeSlider;
    UISwitch   *eqSwitch;
    
    UInt8      selectedEQPresetIndex;
   
    AUGraphController *graphController;
}

@property (readonly, nonatomic) IBOutlet UIView    *instructionsView;
@property (readonly, nonatomic) IBOutlet UIView    *eqView;
@property (readonly, nonatomic) IBOutlet UIWebView *webView;
@property (readonly, nonatomic) IBOutlet UIView    *contentView;

@property (nonatomic, retain) UIBarButtonItem *infoButtonItem;
@property (nonatomic, retain) UIBarButtonItem *eqButtonItem;
@property (nonatomic, retain) UIBarButtonItem *doneButtonItem;

@property (readonly, nonatomic) IBOutlet UIButton *startButton;

@property (readonly, nonatomic) IBOutlet UISwitch *bus0Switch;
@property (readonly, nonatomic) IBOutlet UISlider *bus0VolumeSlider;
@property (readonly, nonatomic) IBOutlet UISwitch *bus1Switch;
@property (readonly, nonatomic) IBOutlet UISlider *bus1VolumeSlider;
@property (readonly, nonatomic) IBOutlet UISlider *outputVolumeSlider;
@property (readonly, nonatomic) IBOutlet UISwitch *eqSwitch;

@property (readonly, nonatomic) IBOutlet AUGraphController *graphController;

- (void)setUIDefaults;
- (void)stopForInterruption;

- (IBAction)enableInput:(UISwitch *)sender;
- (IBAction)setInputVolume:(UISlider *)sender;
- (IBAction)setOutputVolume:(UISlider *)sender;
- (IBAction)enableEQ:(UISwitch *)sender;

- (IBAction)buttonPressedAction:(id)sender;

@end