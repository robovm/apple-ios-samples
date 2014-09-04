/*
     File: AVSEViewController.m
 Abstract: The players UIViewController class. It sets up the AVPlayer, AVPlayerLayer, manages adjusting the playback rate, enables and disables UI elements as appropriate and handles the AVMutableComposition, AVMutableVideoComposition, AVMutableAudioMix items across different edits 
  Version: 1.1
 
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


#import "AVSEViewController.h"

#define kTrimIndex 0
#define kRotateIndex 1
#define kCropIndex 2
#define kAddMusicIndex 3
#define kAddWatermarkIndex 4
#define kExportIndex 0

@interface AVSEViewController ()

- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys;
- (void)stopLoadingAnimationAndHandleError:(NSError *)error;

@end

static void *AVSEPlayerItemStatusContext = &AVSEPlayerItemStatusContext;
static void *AVSEPlayerLayerReadyForDisplay = &AVSEPlayerLayerReadyForDisplay;

@implementation AVSEViewController

#pragma mark - View Controls

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self.playerView setBackgroundColor:[UIColor blackColor]];
	[[self view] addSubview:self.playerView];
	[[self playerView] addSubview:self.exportProgressView];
	[[self view] setAutoresizesSubviews:YES];
	[[self playerView] setAutoresizesSubviews:YES];
	[[self loadingSpinner] setHidden:YES];
	[[self exportButton] setEnabled:NO];
	
	// Create a AVAsset for the given video from the main bundle
	NSString *videoURL = [[NSBundle mainBundle] pathForResource:@"Movie" ofType:@"m4v"];
	AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoURL] options:nil];
	// Load the values of AVAsset keys to inspect subsequently
	NSArray *assetKeysToLoadAndTest = @[@"playable", @"composable", @"tracks", @"duration"];
	
	// Tells the asset to load the values of any of the specified keys that are not already loaded.
	[asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:
	 ^{
		 dispatch_async( dispatch_get_main_queue(),
						^{
							// IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem.
							[self setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest];
						});
	 }];
	
	self.inputAsset = asset;
	
	// Create AVPlayer, add rate and status observers
	[self setPlayer:[[AVPlayer alloc] init]];
	[self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:AVSEPlayerItemStatusContext];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(editCommandCompletionNotificationReceiver:)
												 name:AVSEEditCommandCompletionNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(exportCommandCompletionNotificationReceiver:)
												 name:AVSEExportCommandCompletionNotification
											   object:nil];
}

-(NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (self.playerView) {
		[self updatePlayerLayerSize];
	}
}

#pragma mark - Playback

- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys
{
	// This method is called when AVAsset has completed loading the specified array of keys.
	// playback of the asset is set up here.
	
	// Check whether the values of each of the keys we need has been successfully loaded.
	for (NSString *key in keys) {
		NSError *error = nil;
		
		if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
			[self stopLoadingAnimationAndHandleError:error];
			return;
		}
	}
	
	if (![asset isPlayable]) {
		// Asset cannot be played. Display the "Unplayable Asset" label.
		[self stopLoadingAnimationAndHandleError:nil];
		[[self unplayableLabel] setHidden:NO];
		return;
	}
	
	if (![asset isComposable]) {
		// Asset cannot be used to create a composition (e.g. it may have protected content).
		[self stopLoadingAnimationAndHandleError:nil];
		[[self protectedVideoLabel] setHidden:NO];
		return;
	}
	
	// Set up an AVPlayerLayer
	if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
		// Create an AVPlayerLayer and add it to the player view if there is video, but hide it until it's ready for display
		AVPlayerLayer *newPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:[self player]];
		[newPlayerLayer setFrame:[[[self playerView] layer] bounds]];
		[newPlayerLayer setHidden:YES];
		[[[self playerView] layer] addSublayer:newPlayerLayer];
		[self setPlayerLayer:newPlayerLayer];
		[self addObserver:self forKeyPath:@"playerLayer.readyForDisplay" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:AVSEPlayerLayerReadyForDisplay];
	}
	else {
		// This asset has no video tracks. Show the "No Video" label.
		[self stopLoadingAnimationAndHandleError:nil];
		[[self noVideoLabel] setHidden:NO];
	}
	
	// Create a new AVPlayerItem and make it the player's current item.
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
	[[self player] replaceCurrentItemWithPlayerItem:playerItem];
}

- (void)stopLoadingAnimationAndHandleError:(NSError *)error
{
	[[self loadingSpinner] stopAnimating];
	[[self loadingSpinner] setHidden:YES];
	if (error) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
															message:[error localizedFailureReason]
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
		[alertView show];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == AVSEPlayerItemStatusContext) {
		AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
		BOOL enable = NO;
		switch (status) {
			case AVPlayerItemStatusUnknown:
				break;
			case AVPlayerItemStatusReadyToPlay:
				enable = YES;
				break;
			case AVPlayerItemStatusFailed:
				[self stopLoadingAnimationAndHandleError:[[[self player] currentItem] error]];
				break;
		}
		[[self playPauseButton] setEnabled:enable];
	} else if (context == AVSEPlayerLayerReadyForDisplay) {
		if ([change[NSKeyValueChangeNewKey] boolValue] == YES) {
			// The AVPlayerLayer is ready for display. Hide the loading spinner and show the video.
			[self stopLoadingAnimationAndHandleError:nil];
			[[self playerLayer] setHidden:NO];
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

+ (NSSet *)keyPathsForValuesAffectingDuration
{
	return [NSSet setWithObjects:@"player.currentItem", @"player.currentItem.status", nil];
}

- (double)duration
{
	AVPlayerItem *playerItem = [[self player] currentItem];
	
	if ([playerItem status] == AVPlayerItemStatusReadyToPlay)
		return CMTimeGetSeconds([[playerItem asset] duration]);
	else
		return 0.f;
}

- (double)currentTime
{
	return CMTimeGetSeconds([[self player] currentTime]);
}

- (void)setCurrentTime:(double)time
{
	[[self player] seekToTime:CMTimeMakeWithSeconds(time, 1)];
}

- (IBAction)playPauseToggle:(id)sender
{
	if ([[self player] rate] != 1.f) {
		if ([self currentTime] == [self duration])
			[self setCurrentTime:0.f];
		[[self player] play];
	} else {
		[[self player] pause];
	}
}

- (void)reloadPlayerView
{
	// This method is called every time a tool has been applied to a composition
	// It reloads the player view with the updated composition
	// Create a new AVPlayerItem and make it our player's current item.
	self.videoComposition.animationTool = NULL;
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
	playerItem.videoComposition = self.videoComposition;
	playerItem.audioMix = self.audioMix;
	if(self.watermarkLayer) {
		self.watermarkLayer.position = CGPointMake([[self playerView] bounds].size.width/2, [[self playerView] bounds].size.height/2);
		[[[self playerView] layer] addSublayer:self.watermarkLayer];
	}
	[[self player] replaceCurrentItemWithPlayerItem:playerItem];
	
	// enable export
	[[self exportButton] setEnabled:YES];
}

#pragma mark - Utilities

- (void)updatePlayerLayerSize
{
	[self.playerLayer setFrame:[[[self playerView] layer] bounds]];
}

- (void)updateExportProgress:(NSTimer*)timer
{
	self.exportProgressView.progress = exportCommand.exportSession.progress;
}

- (CALayer*)copyWatermarkLayer:(CALayer*)inputLayer
{
	CALayer *exportWatermarkLayer = [CALayer layer];
	CATextLayer *titleLayer = [CATextLayer layer];
	CATextLayer *inputTextLayer = [inputLayer sublayers][0];
	titleLayer.string = inputTextLayer.string;
	titleLayer.foregroundColor = inputTextLayer.foregroundColor;
	titleLayer.font = inputTextLayer.font;
	titleLayer.shadowOpacity = inputTextLayer.shadowOpacity;
	titleLayer.alignmentMode = inputTextLayer.alignmentMode;
	titleLayer.bounds = inputTextLayer.bounds;
	
	[exportWatermarkLayer addSublayer:titleLayer];
	return exportWatermarkLayer;
}

- (void)exportWillBegin
{
	// Hide play until the export is complete
	[[self playPauseButton] setEnabled:NO];
	[[self exportProgressView] setHidden:NO];
	self.exportProgressView.progress = 0.0;
	[NSTimer scheduledTimerWithTimeInterval:0.05
									 target:self
								   selector:@selector(updateExportProgress:)
								   userInfo:nil
									repeats:YES];
	// If Add watermark has been applied to the composition, create a video composition animation tool for export
	if(self.watermarkLayer) {
		CALayer *exportWatermarkLayer = [self copyWatermarkLayer:self.watermarkLayer];
		CALayer *parentLayer = [CALayer layer];
		CALayer *videoLayer = [CALayer layer];
		parentLayer.frame = CGRectMake(0, 0, self.videoComposition.renderSize.width, self.videoComposition.renderSize.height);
		videoLayer.frame = CGRectMake(0, 0, self.videoComposition.renderSize.width, self.videoComposition.renderSize.height);
		[parentLayer addSublayer:videoLayer];
		exportWatermarkLayer.position = CGPointMake(self.videoComposition.renderSize.width/2, self.videoComposition.renderSize.height/4);
		[parentLayer addSublayer:exportWatermarkLayer];
		self.videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
	}
}

- (void)exportDidEnd
{
	// Update UI after export is completed
	[[self playPauseButton] setEnabled:YES];
	[[self exportProgressView] setHidden:YES];
	[[self exportButton] setEnabled:NO];
}


- (void)editCommandCompletionNotificationReceiver:(NSNotification*) notification
{
	if ([[notification name] isEqualToString:AVSEEditCommandCompletionNotification]) {
		// Update the document's composition, video composition etc
		self.composition = [[notification object] mutableComposition];
		self.videoComposition = [[notification object] mutableVideoComposition];
		self.audioMix = [[notification object] mutableAudioMix];
		if([[notification object] watermarkLayer])
			self.watermarkLayer = [[notification object] watermarkLayer];
		dispatch_async( dispatch_get_main_queue(), ^{
			[self reloadPlayerView];
		});
	}
}

- (void)exportCommandCompletionNotificationReceiver:(NSNotification *)notification
{
	if ([[notification name] isEqualToString:AVSEExportCommandCompletionNotification]) {
		dispatch_async( dispatch_get_main_queue(), ^{
			[self exportDidEnd];
		});
	}
}

#pragma mark - Editing Tools

- (IBAction)edit:(id)sender
{
	int tag = [sender tag];
	// Disable the operation just selected
	[sender setEnabled:NO];
	
	AVSECommand *editCommand;
	
	switch (tag) {
		case kTrimIndex:
			editCommand = [[AVSETrimCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix];
			break;
		case kRotateIndex:
			editCommand = [[AVSERotateCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix];
			break;
		case kCropIndex:
			editCommand = [[AVSECropCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix];
			break;
		case kAddMusicIndex:
			editCommand = [[AVSEAddMusicCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix];
			break;
		case kAddWatermarkIndex:
			editCommand = [[AVSEAddWatermarkCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix];
			break;
		default:
			break;
	}
	
	[editCommand performWithAsset:self.inputAsset];
}

- (IBAction)exportToMovie:(id)sender
{
	[self exportWillBegin];
	exportCommand = [[AVSEExportCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix];
	[exportCommand performWithAsset:nil];
}

@end
