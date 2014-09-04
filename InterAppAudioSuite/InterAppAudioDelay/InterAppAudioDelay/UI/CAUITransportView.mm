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

@interface CAUITransportView ()

@property (nonatomic, assign) IBOutlet UILabel *currentTime;

@property (nonatomic, assign) IBOutlet CAUITransportButton *playPauseButton;
@property (nonatomic, assign) IBOutlet CAUITransportButton *recordButton;
@property (nonatomic, assign) IBOutlet CAUITransportButton *rewindButton;

@property (nonatomic, assign) IBOutlet UIImageView *hostIconView;

@end

@implementation CAUITransportView {
    UIImage                      *hostIcon;

    NSTimer                      *pollPlayerTimer;
    BOOL                         inForeground;
}

@synthesize engine = _engine;
@synthesize rewindButton;
@synthesize playPauseButton;
@synthesize recordButton;
@synthesize hostIconView;
@synthesize currentTime;

extern NSString *kTransportStateChangedNotification;
void displayAlertDialog(NSString *title, NSString *message);

#pragma mark Initialization/dealloc
- (void) awakeFromNib {
	rewindButton.drawingStyle	 = rewindButtonStyle;
	playPauseButton.drawingStyle = pauseButtonStyle;
	recordButton.drawingStyle	 = recordButtonStyle;
	
	rewindButton.fillColor		 = [UIColor darkGrayColor].CGColor;
	playPauseButton.fillColor	 = [UIColor darkGrayColor].CGColor;
	recordButton.fillColor		 = [UIColor redColor].CGColor;
 
    UIApplicationState appstate = [UIApplication sharedApplication].applicationState;
    inForeground = (appstate != UIApplicationStateBackground);
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(appHasGoneInBackground)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(appHasGoneForeground)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    
	//Set touch listener on host icon
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hostIconSelected:)];
    //Default value for cancelsTouchesInView is YES, which will prevent buttons to be clicked
    singleTap.cancelsTouchesInView = NO;
    [hostIconView addGestureRecognizer:singleTap];
}

- (void) dealloc {
    if (_engine)
        [((NSObject*)_engine) removeObserver:self forKeyPath:kTransportStateChangedNotification];
    [hostIcon release];
	
    [super dealloc];
}

- (void) setDelegateAddObserver:(id<CAUITransportEngine>) inDelegate {
    if (_engine != inDelegate) {
        if (_engine) 
            [((NSObject*)_engine) removeObserver:self forKeyPath:kTransportStateChangedNotification];
		
        [((NSObject*)_engine) release];
        _engine = (id)[((NSObject*)inDelegate) retain];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(updateTransportControls)
                                                     name: kTransportStateChangedNotification
                                                   object: _engine];
    }
}

#pragma mark IBActions
- (IBAction) togglePlayback:(id) sender {
    if (self.engine) {
        if (!self.engine.connected)
            displayAlertDialog(@"Error", @"Host not connected");
        else {
            [self.engine togglePlay];
            [self startPollingPlayer];
            [self updateTransportControls];
        }
    }
}

- (IBAction) toggleRecording:(id) sender {
    if (self.engine) {
        if (!self.engine.connected)
            displayAlertDialog(@"Error", @"Host not connected");
        else {
            [self.engine toggleRecord];
            [self updateTransportControls];
        }
    }
}

- (IBAction) rewindAction:(id) sender {
    if (self.engine) {
        if(!self.engine.connected)
            displayAlertDialog(@"Error", @"Host not connected");
        else {
            [self.engine rewind];
            [self updateTransportControls];
        }
    }
}

#pragma mark Activation behavior
- (void) appHasGoneInBackground {
    inForeground = NO;
    [self stopPollingPlayer];
}

- (void) appHasGoneForeground {
    inForeground = YES;
    if (self.engine && [self.engine isHostPlaying])
        [self startPollingPlayer];
    else 
		[self stopPollingPlayer];
    
    [self updateTransportControls];
}

#pragma mark Control updating
- (void) updateTransportControls {
    if (self.engine) {
 		if ([self.engine isHostConnected]) {
			if (!hostIcon)
				hostIcon =  [self.engine getAudioUnitIcon];
			if (hostIcon) {
                hostIconView.userInteractionEnabled = YES;
				[hostIconView setImage:hostIcon];
				hostIconView.contentMode = UIViewContentModeCenter;
			}
			
			recordButton.drawingStyle	 = [self.engine isHostRecording] ? recordEnabledButtonStyle : recordButtonStyle;
			playPauseButton.drawingStyle = [self.engine isHostPlaying]   ? pauseButtonStyle			: playButtonStyle;
			
			[recordButton setEnabled: [self.engine canRecord]];
			[currentTime setText: [self.engine getPlayTimeString]];
			
			self.hidden = NO;
		} else
			self.hidden = YES;
		
		[self setNeedsDisplay];
    }
}

- (void) stopPollingPlayer {
    if (pollPlayerTimer) {
        [pollPlayerTimer invalidate];
        pollPlayerTimer = NULL;
    }
}

- (void) startPollingPlayer {
    if (self.engine && [self.engine isHostConnected] && inForeground ) {
        if (!pollPlayerTimer) {
            pollPlayerTimer =  [NSTimer scheduledTimerWithTimeInterval: 0.05
                                                                target: self
                                                              selector: @selector(pollHost)
                                                              userInfo: nil
                                                               repeats: YES];
        }
    }
}

- (void) pollHost {
    if (self.engine)
        [currentTime setText:[self.engine getPlayTimeString]];
}

- (void) hostIconSelected:(UITapGestureRecognizer *) gesture {
    if (self.engine)
        [self.engine gotoHost];
}

@end
