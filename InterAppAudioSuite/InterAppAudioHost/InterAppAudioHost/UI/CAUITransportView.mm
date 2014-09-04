/*
     File: CAUITransportView.mm
 Abstract: 
  Version: 1.1.2
 
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

#import "CAUITransportView.h"
#import "AppDelegate.h"

@implementation CAUITransportView

#pragma mark - Initialization
- (void) awakeFromNib {
	rewindButton.drawingStyle = rewindButtonStyle;
	playPauseButton.drawingStyle = pauseButtonStyle;
	recordButton.drawingStyle = recordButtonStyle;
	
	rewindButton.fillColor = [UIColor colorWithWhite: .937f alpha:1].CGColor;
	playPauseButton.fillColor = [UIColor colorWithWhite: .937f alpha:1].CGColor;
	recordButton.fillColor = [UIColor colorWithRed:.984f green:.251f blue:.173f alpha:1.0].CGColor;
    
	// Initialization code
    __block CAUITransportView *blockSelf = self;//Is this a good idea?
    
	//Wire view upto the audio engine
    [AUDIO_ENGINE addEngineObserver: ^{
        [blockSelf updateTransportControls];
    } key:[NSString stringWithFormat:@"%@,%@",
           NSStringFromClass([self class]),
           @"updateTransportControls"]];
}

#pragma mark - Property methods
- (BOOL) isEnabled {
	return enabled;
}

- (void) setEnabled:(BOOL) value {
	if (enabled != value) {
		recordButton.enabled = value;
		playPauseButton.enabled = value;
		rewindButton.enabled = value;
	}
}

#pragma mark - Action methods
- (IBAction) togglePlayback:(id) sender {
    if (![AUDIO_ENGINE canPlay])
        displayAlertDialog(@"Error", @"Host can't play");
    else {
        [AUDIO_ENGINE togglePlay];
        [self updateTransportControls];
    }
}

- (IBAction) toggleRecording:(id) sender {
    if (![AUDIO_ENGINE canRecord])
        displayAlertDialog(@"Error", @"Host can't record");
    else {
        [AUDIO_ENGINE toggleRecord];
        [self updateTransportControls];
    }
}

- (IBAction) rewindAction:(id) sender {
    if (![AUDIO_ENGINE canPlay])
        displayAlertDialog(@"Error", @"Host can't rewind");
    else {
        [AUDIO_ENGINE rewind];
        [self updateTransportControls];
    }
}

- (void) updateTransportControls {
    if ([AUDIO_ENGINE isRecording])
		recordButton.drawingStyle =recordEnabledButtonStyle;
    else
        recordButton.drawingStyle = recordButtonStyle;
    
    if ([AUDIO_ENGINE isPlaying])
 		playPauseButton.drawingStyle =pauseButtonStyle;
    else
		playPauseButton.drawingStyle = playButtonStyle;
    
	recordButton.enabled = [AUDIO_ENGINE canRecord];
	recordButton.userInteractionEnabled = recordButton.enabled;
	recordButton.alpha = recordButton.enabled ? 1 : .25;
	
	playPauseButton.enabled = [AUDIO_ENGINE canPlay];
	playPauseButton.userInteractionEnabled = playPauseButton.enabled;
	playPauseButton.alpha = playPauseButton.enabled ? 1 : .25;

	rewindButton.enabled = [AUDIO_ENGINE canRewind];
	rewindButton.userInteractionEnabled = rewindButton.enabled;
	rewindButton.alpha = rewindButton.enabled ? 1 : .25;
	    
    [self setNeedsDisplay];
}

@end
