/*
     File: APLViewController.m
 Abstract: UIViewController subclasses which handles setup, playback and export of AVMutableComposition along with other user interactions like scrubbing, toggling play/pause, selecting transition type.
  Version: 1.2
 
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

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "APLViewController.h"
#import "APLSimpleEditor.h"

/*
 Player view backed by an AVPlayerLayer
*/
@interface APLPlayerView : UIView

@property (nonatomic, strong) AVPlayer *player;

@end



@implementation APLPlayerView

+ (Class)layerClass
{
	return [AVPlayerLayer class];
}

- (AVPlayer *)player
{
	return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player
{
	[(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end
/*
 */

static NSString* const AVCustomEditPlayerViewControllerStatusObservationContext	= @"AVCustomEditPlayerViewControllerStatusObservationContext";
static NSString* const AVCustomEditPlayerViewControllerRateObservationContext = @"AVCustomEditPlayerViewControllerRateObservationContext";

@interface APLViewController () 

@property APLSimpleEditor		*editor;
@property NSMutableArray		*clips;
@property NSMutableArray		*clipTimeRanges;

@property AVPlayer				*player;
@property AVPlayerItem			*playerItem;

@property UIPopoverController	*popover;

- (void)updatePlayPauseButton;
- (void)updateScrubber;
- (void)updateTimeLabel;

- (CMTime)playerItemDuration;

- (void)synchronizePlayerWithEditor;

@property IBOutlet APLPlayerView		*playerView;

@property IBOutlet UIToolbar			*toolbar;
@property IBOutlet UISlider				*scrubber;
@property IBOutlet UIBarButtonItem		*playPauseButton;
@property IBOutlet UIBarButtonItem		*transitionButton;
@property IBOutlet UIBarButtonItem		*exportButton;
@property IBOutlet UILabel				*currentTimeLabel;
@property IBOutlet UIProgressView		*exportProgressView;

- (IBAction)handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer;
- (IBAction)togglePlayPause:(id)sender;
- (IBAction)exportToMovie:(id)sender;

- (IBAction)beginScrubbing:(id)sender;
- (IBAction)scrub:(id)sender;
- (IBAction)endScrubbing:(id)sender;


@end



@implementation APLViewController
{
@private
	BOOL			_playing;
	BOOL			_scrubInFlight;
	BOOL			_seekToZeroBeforePlaying;
	float			_lastScrubSliderValue;
	float			_playRateToRestore;
	id				_timeObserver;

	float			_transitionDuration;
	NSInteger		_transitionType;
	BOOL			_transitionsEnabled;

	NSTimer			*_progressTimer;
}


#pragma mark - View loading

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.editor = [[APLSimpleEditor alloc] init];
	self.clips = [[NSMutableArray alloc] initWithCapacity:2];
	self.clipTimeRanges = [[NSMutableArray alloc] initWithCapacity:2];
	
	// Defaults for the transition settings.
	_transitionType = kDiagonalWipeTransition;
	_transitionDuration = 2.0;
	_transitionsEnabled = YES;
	
	[self updateScrubber];
	[self updateTimeLabel];
	
	// Add the clips from the main bundle to create a composition using them
	[self setupEditingAndPlayback]; 
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (!self.player) {
		_seekToZeroBeforePlaying = NO;
		self.player = [[AVPlayer alloc] init];
		[self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:(__bridge void *)(AVCustomEditPlayerViewControllerRateObservationContext)];
		[self.playerView setPlayer:self.player];
	}
	
	[self addTimeObserverToPlayer];
	
	// Build AVComposition and AVVideoComposition objects for playback
	[self.editor buildCompositionObjectsForPlayback:YES];
	[self synchronizePlayerWithEditor];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[self.player pause];
	[self removeTimeObserverFromPlayer];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"Transition"])
	{
		// Setup transition type picker controller before it is shown.
		APLTransitionTypeController *transitionTypePickerController = (APLTransitionTypeController *)((UINavigationController *)segue.destinationViewController).topViewController;
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			self.popover = [(UIStoryboardPopoverSegue *)segue popoverController];
		}
		transitionTypePickerController.delegate = self;
		transitionTypePickerController.currentTransition = _transitionType;
		if (_transitionType == kCrossDissolveTransition) {
			// Make sure the view is loaded first
			if (!transitionTypePickerController.crossDissolveCell)
				[transitionTypePickerController loadView];
			[transitionTypePickerController.crossDissolveCell setAccessoryType:UITableViewCellAccessoryCheckmark];
		} else {
			// Make sure the view is loaded first
			if (!transitionTypePickerController.diagonalWipeCell)
				[transitionTypePickerController loadView];
			[transitionTypePickerController.diagonalWipeCell setAccessoryType:UITableViewCellAccessoryCheckmark];
		}
	}
}

#pragma mark - Simple Editor

- (void)setupEditingAndPlayback
{
	AVURLAsset *asset1 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample_clip1" ofType:@"m4v"]]];
	AVURLAsset *asset2 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample_clip2" ofType:@"mov"]]];
	
	dispatch_group_t dispatchGroup = dispatch_group_create();
	NSArray *assetKeysToLoadAndTest = @[@"tracks", @"duration", @"composable"];
	
	[self loadAsset:asset1 withKeys:assetKeysToLoadAndTest usingDispatchGroup:dispatchGroup];
	[self loadAsset:asset2 withKeys:assetKeysToLoadAndTest usingDispatchGroup:dispatchGroup];
	
	// Wait until both assets are loaded
	dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^(){
		[self synchronizeWithEditor];
	});
}

- (void)loadAsset:(AVAsset *)asset withKeys:(NSArray *)assetKeysToLoad usingDispatchGroup:(dispatch_group_t)dispatchGroup
{
	dispatch_group_enter(dispatchGroup);
	[asset loadValuesAsynchronouslyForKeys:assetKeysToLoad completionHandler:^(){
		// First test whether the values of each of the keys we need have been successfully loaded.
		for (NSString *key in assetKeysToLoad) {
			NSError *error;
			
			if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
				NSLog(@"Key value loading failed for key:%@ with error: %@", key, error);
				goto bail;
			}
		}
		if (![asset isComposable]) {
			NSLog(@"Asset is not composable");
			goto bail;
		}
		
		[self.clips addObject:asset];
		// This code assumes that both assets are atleast 5 seconds long.
		[self.clipTimeRanges addObject:[NSValue valueWithCMTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, 1), CMTimeMakeWithSeconds(5, 1))]];
bail:
		dispatch_group_leave(dispatchGroup);
	}];
}

- (void)synchronizePlayerWithEditor
{
	if ( self.player == nil )
		return;
	
	AVPlayerItem *playerItem = [self.editor playerItem];
	
	if (self.playerItem != playerItem) {
		if ( self.playerItem ) {
			[self.playerItem removeObserver:self forKeyPath:@"status"];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
		}
		
		self.playerItem = playerItem;
		
		if ( self.playerItem ) {
			if ( [self.playerItem respondsToSelector:@selector(setSeekingWaitsForVideoCompositionRendering:)] )
				self.playerItem.seekingWaitsForVideoCompositionRendering = YES;
			
			// Observe the player item "status" key to determine when it is ready to play
			[self.playerItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial) context:(__bridge void *)(AVCustomEditPlayerViewControllerStatusObservationContext)];
			
			// When the player item has played to its end time we'll set a flag
			// so that the next time the play method is issued the player will
			// be reset to time zero first.
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
		}
		[self.player replaceCurrentItemWithPlayerItem:playerItem];
	}
}

- (void)synchronizeWithEditor
{
	// Clips
	[self synchronizeEditorClipsWithOurClips];
	[self synchronizeEditorClipTimeRangesWithOurClipTimeRanges];
	
	
	// Transitions
	if (_transitionsEnabled) {
		self.editor.transitionDuration = CMTimeMakeWithSeconds(_transitionDuration, 600);
		self.editor.transitionType = _transitionType;
	} else {
		self.editor.transitionDuration = kCMTimeInvalid;
	}
	
	// Build AVComposition and AVVideoComposition objects for playback
	[self.editor buildCompositionObjectsForPlayback:YES];
	
	[self synchronizePlayerWithEditor];
}

- (void)synchronizeEditorClipsWithOurClips
{
	NSMutableArray *validClips = [NSMutableArray arrayWithCapacity:2];
	for (AVURLAsset *asset in self.clips) {
		if (![asset isKindOfClass:[NSNull class]]) {
			[validClips addObject:asset];
		}
	}
	
	self.editor.clips = validClips;
}

- (void)synchronizeEditorClipTimeRangesWithOurClipTimeRanges
{
	NSMutableArray *validClipTimeRanges = [NSMutableArray arrayWithCapacity:2];
	for (NSValue *timeRange in self.clipTimeRanges) {
		if (! [timeRange isKindOfClass:[NSNull class]]) {
			[validClipTimeRanges addObject:timeRange];
		}
	}
	
	self.editor.clipTimeRanges = validClipTimeRanges;
}

#pragma mark - Utilities

/* Update the scrubber and time label periodically. */
- (void)addTimeObserverToPlayer
{
	if (_timeObserver)
		return;
	
	if (self.player == nil)
		return;
	
	if (self.player.currentItem.status != AVPlayerItemStatusReadyToPlay)
		return;
	
	double duration = CMTimeGetSeconds([self playerItemDuration]);
	
	if (isfinite(duration)) {
		CGFloat width = CGRectGetWidth([self.scrubber bounds]);
		double interval = 0.5 * duration / width;
		
		/* The time label needs to update at least once per second. */
		if (interval > 1.0)
			interval = 1.0;
		__weak APLViewController *weakSelf = self;
		_timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:
						  ^(CMTime time) {
							  [weakSelf updateScrubber];
							  [weakSelf updateTimeLabel];
						  }];
	}
}

- (void)removeTimeObserverFromPlayer
{
	if (_timeObserver) {
		[self.player removeTimeObserver:_timeObserver];
		_timeObserver = nil;
	}
}

- (CMTime)playerItemDuration
{
	AVPlayerItem *playerItem = [self.player currentItem];
	CMTime itemDuration = kCMTimeInvalid;
	
	if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
		itemDuration = [playerItem duration];
	}
	
	/* Will be kCMTimeInvalid if the item is not ready to play. */
	return itemDuration;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == (__bridge void *)(AVCustomEditPlayerViewControllerRateObservationContext) ) {
		float newRate = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
		NSNumber *oldRateNum = [change objectForKey:NSKeyValueChangeOldKey];
		if ( [oldRateNum isKindOfClass:[NSNumber class]] && newRate != [oldRateNum floatValue] ) {
			_playing = ((newRate != 0.f) || (_playRateToRestore != 0.f));
			[self updatePlayPauseButton];
			[self updateScrubber];
			[self updateTimeLabel];
		}
    }
	else if ( context == (__bridge void *)(AVCustomEditPlayerViewControllerStatusObservationContext) ) {
		AVPlayerItem *playerItem = (AVPlayerItem *)object;
		if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
			/* Once the AVPlayerItem becomes ready to play, i.e.
			 [playerItem status] == AVPlayerItemStatusReadyToPlay,
			 its duration can be fetched from the item. */
			
			[self addTimeObserverToPlayer];
		}
		else if (playerItem.status == AVPlayerItemStatusFailed) {
			[self reportError:playerItem.error];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)updatePlayPauseButton
{
	UIBarButtonSystemItem style = _playing ? UIBarButtonSystemItemPause : UIBarButtonSystemItemPlay;
	UIBarButtonItem *newPlayPauseButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:style target:self action:@selector(togglePlayPause:)];
	
	NSMutableArray *items = [NSMutableArray arrayWithArray:self.toolbar.items];
	[items replaceObjectAtIndex:[items indexOfObject:self.playPauseButton] withObject:newPlayPauseButton];
	[self.toolbar setItems:items];
	
	self.playPauseButton = newPlayPauseButton;
}

- (void)updateTimeLabel
{
	double seconds = CMTimeGetSeconds([self.player currentTime]);
	if (!isfinite(seconds)) {
		seconds = 0;
	}
	
	int secondsInt = round(seconds);
	int minutes = secondsInt/60;
	secondsInt -= minutes*60;
	
	self.currentTimeLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
	self.currentTimeLabel.textAlignment = NSTextAlignmentCenter;
	
	self.currentTimeLabel.text = [NSString stringWithFormat:@"%.2i:%.2i", minutes, secondsInt];
}

- (void)updateScrubber
{
	double duration = CMTimeGetSeconds([self playerItemDuration]);
	
	if (isfinite(duration)) {
		double time = CMTimeGetSeconds([self.player currentTime]);
		[self.scrubber setValue:time / duration];
	}
	else {
		[self.scrubber setValue:0.0];
	}
}

- (void)updateProgress:(NSTimer*)timer
{
	AVAssetExportSession *session = (AVAssetExportSession *)[timer userInfo];
	if (session.status == AVAssetExportSessionStatusExporting) {
		_exportProgressView.progress = session.progress;
	}
}

- (void)reportError:(NSError *)error
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (error) {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
																message:[error localizedRecoverySuggestion]
															   delegate:nil
													  cancelButtonTitle:NSLocalizedString(@"OK", nil)
													  otherButtonTitles:nil];

			[alertView show];
		}
	});
}

#pragma mark - IBActions

- (IBAction)togglePlayPause:(id)sender
{
	_playing = !_playing;
	if ( _playing ) {
		if ( _seekToZeroBeforePlaying ) {
			[self.player seekToTime:kCMTimeZero];
			_seekToZeroBeforePlaying = NO;
		}
		[self.player play];
	}
	else {
		[self.player pause];
	}
}

- (IBAction)beginScrubbing:(id)sender
{
	_seekToZeroBeforePlaying = NO;
	_playRateToRestore = [self.player rate];
	[self.player setRate:0.0];
	
	[self removeTimeObserverFromPlayer];
}

- (IBAction)scrub:(id)sender
{
	_lastScrubSliderValue = [self.scrubber value];
	
	if ( ! _scrubInFlight )
		[self scrubToSliderValue:_lastScrubSliderValue];
}

- (void)scrubToSliderValue:(float)sliderValue
{
	double duration = CMTimeGetSeconds([self playerItemDuration]);
	
	if (isfinite(duration)) {
		CGFloat width = CGRectGetWidth([self.scrubber bounds]);
		
		double time = duration*sliderValue;
		double tolerance = 1.0f * duration / width;
		
		_scrubInFlight = YES;
		
		[self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)
				toleranceBefore:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC)
				 toleranceAfter:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC)
			  completionHandler:^(BOOL finished) {
				  _scrubInFlight = NO;
				  [self updateTimeLabel];
			  }];
	}
}

- (IBAction)endScrubbing:(id)sender
{
	if ( _scrubInFlight )
		[self scrubToSliderValue:_lastScrubSliderValue];
	[self addTimeObserverToPlayer];
	
	[self.player setRate:_playRateToRestore];
	_playRateToRestore = 0.f;
}

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
	/* After the movie has played to its end time, seek back to time zero to play it again. */
	_seekToZeroBeforePlaying = YES;
}

- (IBAction)handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer
{
    self.toolbar.hidden = !self.toolbar.hidden;
	self.currentTimeLabel.hidden = !self.currentTimeLabel.hidden;
}

- (IBAction)exportToMovie:(id)sender
{
	_exportProgressView.hidden = NO;
	
	[self.player pause];
	[self.playPauseButton setEnabled:NO];
	[self.transitionButton setEnabled:NO];
	[self.scrubber setEnabled:NO];
	[self.exportButton setEnabled:NO];
	
	[self.editor buildCompositionObjectsForPlayback:NO];
	
	// Get the export session from the editor
	AVAssetExportSession *session = [self.editor assetExportSessionWithPreset:AVAssetExportPresetMediumQuality];
	
	// Remove the file if it already exists
	NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ExportedProject.mov"];
	[[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
	
	// If a preset that is not compatible with AVFileTypeQuickTimeMovie is used, one can use -[AVAssetExportSession supportedFileTypes] to obtain a supported file type for the output file and UTTypeCreatePreferredIdentifierForTag to obtain an appropriate path extension for the output file type.
	session.outputURL = [NSURL fileURLWithPath:filePath];
	session.outputFileType = AVFileTypeQuickTimeMovie;
	
	[session exportAsynchronouslyWithCompletionHandler:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self exportCompleted:session];
		});
	}];
	
	// Update progress view with export progress
	_progressTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updateProgress:) userInfo:session repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:_progressTimer forMode:NSDefaultRunLoopMode];
}

- (void)exportCompleted:(AVAssetExportSession *)session
{
	_exportProgressView.hidden = YES;
	_currentTimeLabel.hidden = NO;
	NSURL *outputURL = session.outputURL;
	
	[_progressTimer invalidate];
	_progressTimer = nil;
	
	if ( session.status != AVAssetExportSessionStatusCompleted ) {
		NSLog(@"exportSession error:%@", session.error);
		[self reportError:session.error];
	}
	
	if ( session.status != AVAssetExportSessionStatusCompleted ) {
		return;
	}
	
	_exportProgressView.progress = 1.0;
	
	// Save the exported movie to the camera roll
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	[library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error) {
		if (error != NULL) {
			NSLog(@"writeVideoToAssestsLibrary failed: %@", error);
			[self reportError:error];
		}
	}];
	
	[self.player play];
	[self.playPauseButton setEnabled:YES];
	[self.transitionButton setEnabled:YES];
	[self.scrubber setEnabled:YES];
	[self.exportButton setEnabled:YES];
}

#pragma mark - Gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view != self.playerView) {
        // Ignore touch on toolbar.
        return NO;
    }
    return YES;
}

#pragma mark - APLTransitionTypePickerDelegate

- (void)transitionTypeController:(APLTransitionTypeController *)controller didPickTransitionType:(int)transitionType
{
	_transitionType = transitionType;
	
	// Let the editor know of the change in transition type.
	[self synchronizeWithEditor];
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		[self.popover dismissPopoverAnimated:YES];
	} else {
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

@end
