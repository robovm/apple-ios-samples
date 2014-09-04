/*
    File: MyStreamingMovieViewController.m
Abstract: 
A UIViewController controller subclass that loads the SecondView nib file that contains its view.
 Contains an action method that is called when the Play Movie button is pressed to play the movie.
 Provides a text edit control for the user to enter a movie URL.
 Manages a collection of transport control UI that allows the user to play/pause and seek.

 Version: 1.4

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

Copyright (C) 2011 Apple Inc. All Rights Reserved.

*/

#import "MyStreamingMovieViewController.h"
#import "MyPlayerLayerView.h"

#import <AVFoundation/AVFoundation.h>

static void *MyStreamingMovieViewControllerTimedMetadataObserverContext = &MyStreamingMovieViewControllerTimedMetadataObserverContext;
static void *MyStreamingMovieViewControllerRateObservationContext = &MyStreamingMovieViewControllerRateObservationContext;
static void *MyStreamingMovieViewControllerCurrentItemObservationContext = &MyStreamingMovieViewControllerCurrentItemObservationContext;
static void *MyStreamingMovieViewControllerPlayerItemStatusObserverContext = &MyStreamingMovieViewControllerPlayerItemStatusObserverContext;

NSString *kTracksKey		= @"tracks";
NSString *kStatusKey		= @"status";
NSString *kRateKey			= @"rate";
NSString *kPlayableKey		= @"playable";
NSString *kCurrentItemKey	= @"currentItem";
NSString *kTimedMetadataKey	= @"currentItem.timedMetadata";

#pragma mark -
@interface MyStreamingMovieViewController (Player)
- (CMTime)playerItemDuration;
- (BOOL)isPlaying;
- (void)handleTimedMetadata:(AVMetadataItem*)timedMetadata;
- (void)updateAdList:(NSArray *)newAdList;
- (void)assetFailedToPrepareForPlayback:(NSError *)error;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;
@end

@implementation MyStreamingMovieViewController

@synthesize movieURLTextField;
@synthesize movieTimeControl;
@synthesize playerLayerView;
@synthesize player, playerItem;
@synthesize isPlayingAdText;
@synthesize toolBar, playButton, stopButton;

#pragma mark -
#pragma mark Movie controller methods
#pragma mark -

/* ---------------------------------------------------------
 **  Methods to handle manipulation of the movie scrubber control
 ** ------------------------------------------------------- */

#pragma mark Play, Stop Buttons

/* Show the stop button in the movie player controller. */
-(void)showStopButton
{
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[toolBar items]];
    [toolbarItems replaceObjectAtIndex:0 withObject:stopButton];
    toolBar.items = toolbarItems;
}

/* Show the play button in the movie player controller. */
-(void)showPlayButton
{
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[toolBar items]];
    [toolbarItems replaceObjectAtIndex:0 withObject:playButton];
    toolBar.items = toolbarItems;
}

/* If the media is playing, show the stop button; otherwise, show the play button. */
- (void)syncPlayPauseButtons
{
	if ([self isPlaying])
	{
        [self showStopButton];
	}
	else
	{
        [self showPlayButton];        
	}
}

-(void)enablePlayerButtons
{
    self.playButton.enabled = YES;
    self.stopButton.enabled = YES;
}

-(void)disablePlayerButtons
{
    self.playButton.enabled = NO;
    self.stopButton.enabled = NO;
}

#pragma mark Scrubber control

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration)) 
	{
		movieTimeControl.minimumValue = 0.0;
		return;
	} 
	
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration) && (duration > 0))
	{
		float minValue = [movieTimeControl minimumValue];
		float maxValue = [movieTimeControl maximumValue];
		double time = CMTimeGetSeconds([player currentTime]);
		[movieTimeControl setValue:(maxValue - minValue) * time / duration + minValue];
	}
}

/* Requests invocation of a given block during media playback to update the 
 movie scrubber control. */
-(void)initScrubberTimer
{
	double interval = .1f;	
	
	CMTime playerDuration = [self playerItemDuration];
	if (CMTIME_IS_INVALID(playerDuration)) 
	{
		return;
	} 
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
		CGFloat width = CGRectGetWidth([movieTimeControl bounds]);
		interval = 0.5f * duration / width;
	}

	/* Update the scrubber during normal playback. */
	timeObserver = [[player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) 
                                                          queue:NULL 
                                                     usingBlock:
                                                      ^(CMTime time) 
                                                      {
                                                          [self syncScrubber];
                                                      }] retain];
}

/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
	if (timeObserver)
	{
		[player removeTimeObserver:timeObserver];
		[timeObserver release];
		timeObserver = nil;
	}
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (IBAction)beginScrubbing:(id)sender
{
	restoreAfterScrubbingRate = [player rate];
	[player setRate:0.f];
	
	/* Remove previous timer. */
	[self removePlayerTimeObserver];
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (IBAction)endScrubbing:(id)sender
{
	if (!timeObserver)
	{
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration)) 
		{
			return;
		} 
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			CGFloat width = CGRectGetWidth([movieTimeControl bounds]);
			double tolerance = 0.5f * duration / width;
            
			timeObserver = [[player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:
                             ^(CMTime time)
                             {
                                 [self syncScrubber];
                             }] retain];
		}
	}
    
	if (restoreAfterScrubbingRate)
	{
		[player setRate:restoreAfterScrubbingRate];
		restoreAfterScrubbingRate = 0.f;
	}
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender
{
	if ([sender isKindOfClass:[UISlider class]])
	{
		UISlider* slider = sender;
		
		CMTime playerDuration = [self playerItemDuration];
		if (CMTIME_IS_INVALID(playerDuration)) {
			return;
		} 
		
		double duration = CMTimeGetSeconds(playerDuration);
		if (isfinite(duration))
		{
			float minValue = [slider minimumValue];
			float maxValue = [slider maximumValue];
			float value = [slider value];
			
			double time = duration * (value - minValue) / (maxValue - minValue);
			
			[player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
		}
	}
}

- (BOOL)isScrubbing
{
	return restoreAfterScrubbingRate != 0.f;
}

-(void)enableScrubber
{
    self.movieTimeControl.enabled = YES;
}

-(void)disableScrubber
{
    self.movieTimeControl.enabled = NO;    
}

/* Prevent the slider from seeking during Ad playback. */
- (void)sliderSyncToPlayerSeekableTimeRanges
{		
	NSArray *seekableTimeRanges = [[player currentItem] seekableTimeRanges];
	if ([seekableTimeRanges count] > 0) 
	{
		NSValue *range = [seekableTimeRanges objectAtIndex:0];
		CMTimeRange timeRange = [range CMTimeRangeValue];
		float startSeconds = CMTimeGetSeconds(timeRange.start);
		float durationSeconds = CMTimeGetSeconds(timeRange.duration);
		
		/* Set the minimum and maximum values of the time slider to match the seekable time range. */
		movieTimeControl.minimumValue = startSeconds;
		movieTimeControl.maximumValue = startSeconds + durationSeconds;
	}
}

#pragma mark Button Action Methods

- (IBAction)play:(id)sender
{
	/* If we are at the end of the movie, we must seek to the beginning first 
     before starting playback. */
	if (YES == seekToZeroBeforePlay) 
	{
		seekToZeroBeforePlay = NO;
		[player seekToTime:kCMTimeZero];
	}
    
	[player play];
	
    [self showStopButton];  
}

- (IBAction)pause:(id)sender
{
	[player pause];
    
    [self showPlayButton];
}

- (IBAction)loadMovieButtonPressed:(id)sender
{
	/* Has the user entered a movie URL? */
	if (self.movieURLTextField.text.length > 0)
	{
		NSURL *newMovieURL = [NSURL URLWithString:self.movieURLTextField.text];
		if ([newMovieURL scheme])	/* Sanity check on the URL. */
		{
			/*
			 Create an asset for inspection of a resource referenced by a given URL.
			 Load the values for the asset keys "tracks", "playable".
			 */
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:newMovieURL options:nil];
            
			NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
			
			/* Tells the asset to load the values of any of the specified keys that are not already loaded. */
			[asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
			 ^{		 
				 dispatch_async( dispatch_get_main_queue(), 
								^{
									/* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
									[self prepareToPlayAsset:asset withKeys:requestedKeys];
								});
			 }];
		}
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{
	/* When the user presses return, take focus away from the text 
		field so that the keyboard is dismissed. */
	if (theTextField == self.movieURLTextField) 
	{
		[self.movieURLTextField resignFirstResponder];
	}
	
	return YES;
}

#pragma mark -
#pragma mark View Controller
#pragma mark -

- (void)viewDidUnload
{
    self.playerLayerView = nil;
    self.toolBar = nil;
    self.playButton = nil;
    self.stopButton = nil;
    self.movieTimeControl = nil;
    self.movieURLTextField = nil;
    self.isPlayingAdText = nil;
    [timeObserver release];
    [movieURL release];
    
    [super viewDidUnload];
}

- (void)viewDidLoad
{    
	UIView* view  = [self view];
	UISwipeGestureRecognizer* swipeUpRecognizer = [[UISwipeGestureRecognizer allocWithZone:[self zone]] initWithTarget:self action:@selector(handleSwipe:)];
	[swipeUpRecognizer setDirection:UISwipeGestureRecognizerDirectionUp];
	[view addGestureRecognizer:swipeUpRecognizer];
	[swipeUpRecognizer release];
	
	UISwipeGestureRecognizer* swipeDownRecognizer = [[UISwipeGestureRecognizer allocWithZone:[self zone]] initWithTarget:self action:@selector(handleSwipe:)];
	[swipeDownRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];
	[view addGestureRecognizer:swipeDownRecognizer];
	[swipeDownRecognizer release];
    
    UIBarButtonItem *scrubberItem = [[UIBarButtonItem alloc] initWithCustomView:movieTimeControl];
    UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
    toolBar.items = [NSArray arrayWithObjects:playButton, flexItem, scrubberItem, nil];
    [scrubberItem release];
    [flexItem release];
    
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    /* Supports all orientations. */
    return YES;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)gestureRecognizer
{
	UIView* view = [self view];
	UISwipeGestureRecognizerDirection direction = [gestureRecognizer direction];
	CGPoint location = [gestureRecognizer locationInView:view];
	
	if (location.y < CGRectGetMidY([view bounds]))
	{
		if (direction == UISwipeGestureRecognizerDirectionUp)
		{
			[UIView animateWithDuration:0.2f animations:
             ^{
                 [[self navigationController] setNavigationBarHidden:YES animated:YES];
             } completion:
             ^(BOOL finished)
             {
                 [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
             }];
		}
		if (direction == UISwipeGestureRecognizerDirectionDown)
		{
			[UIView animateWithDuration:0.2f animations:
             ^{
                 [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
             } completion:
             ^(BOOL finished)
             {
                 [[self navigationController] setNavigationBarHidden:NO animated:YES];
             }];
		}
	}
	else
	{
		if (direction == UISwipeGestureRecognizerDirectionDown)
		{
            if (![toolBar isHidden])
			{
				[UIView animateWithDuration:0.2f animations:
                 ^{
                     [toolBar setTransform:CGAffineTransformMakeTranslation(0.f, CGRectGetHeight([toolBar bounds]))];
                 } completion:
                 ^(BOOL finished)
                 {
                     [toolBar setHidden:YES];
                 }];
			}
		}
		else if (direction == UISwipeGestureRecognizerDirectionUp)
		{
            if ([toolBar isHidden])
			{
				[toolBar setHidden:NO];
				
				[UIView animateWithDuration:0.2f animations:
                 ^{
                     [toolBar setTransform:CGAffineTransformIdentity];
                 } completion:^(BOOL finished){}];
			}
		}
	}
}

- (void)dealloc
{
    [timeObserver release];
    [movieURL release];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    [self.player removeObserver:self forKeyPath:kCurrentItemKey];
    [self.player removeObserver:self forKeyPath:kTimedMetadataKey];
    [self.player removeObserver:self forKeyPath:kRateKey];
	[player release]; 
	[adList release];
	
	[movieURLTextField release];
	[movieTimeControl release];
	[playerLayerView release];
	[toolBar release];
	[playButton release];
	[stopButton release];
	[isPlayingAdText release];
	
    [super dealloc];
}

@end

@implementation MyStreamingMovieViewController (Player)

#pragma mark -

#pragma mark Player

/* ---------------------------------------------------------
 **  Get the duration for a AVPlayerItem. 
 ** ------------------------------------------------------- */

- (CMTime)playerItemDuration
{
	AVPlayerItem *thePlayerItem = [player currentItem];
	if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay)
	{        
        /* 
         NOTE:
         Because of the dynamic nature of HTTP Live Streaming Media, the best practice 
         for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3. 
         Prior to iOS 4.3, you would obtain the duration of a player item by fetching 
         the value of the duration property of its associated AVAsset object. However, 
         note that for HTTP Live Streaming Media the duration of a player item during 
         any particular playback session may differ from the duration of its asset. For 
         this reason a new key-value observable duration property has been defined on 
         AVPlayerItem.
         
         See the AV Foundation Release Notes for iOS 4.3 for more information.
         */		
        
		return([playerItem duration]);
	}
    
	return(kCMTimeInvalid);
}

- (BOOL)isPlaying
{
	return restoreAfterScrubbingRate != 0.f || [player rate] != 0.f;
}

#pragma mark Player Notifications

/* Called when the player item has played to its end time. */
- (void) playerItemDidReachEnd:(NSNotification*) aNotification 
{
	/* Hide the 'Pause' button, show the 'Play' button in the slider control */
    [self showPlayButton];
    
	/* After the movie has played to its end time, seek back to time zero 
     to play it again */
	seekToZeroBeforePlay = YES;
}

#pragma mark -
#pragma mark Timed metadata
#pragma mark -

- (void)handleTimedMetadata:(AVMetadataItem*)timedMetadata
{
	/* We expect the content to contain plists encoded as timed metadata. AVPlayer turns these into NSDictionaries. */
	if ([(NSString *)[timedMetadata key] isEqualToString:AVMetadataID3MetadataKeyGeneralEncapsulatedObject]) 
	{
		if ([[timedMetadata value] isKindOfClass:[NSDictionary class]]) 
		{
			NSDictionary *propertyList = (NSDictionary *)[timedMetadata value];
            
			/* Metadata payload could be the list of ads. */
			NSArray *newAdList = [propertyList objectForKey:@"ad-list"];
			if (newAdList != nil) 
			{
				[self updateAdList:newAdList];
				NSLog(@"ad-list is %@", newAdList);
			}
            
			/* Or it might be an ad record. */
			NSString *adURL = [propertyList objectForKey:@"url"];
			if (adURL != nil) 
			{
				if ([adURL isEqualToString:@""]) 
				{
					/* Ad is not playing, so clear text. */
					self.isPlayingAdText.text = @"";
                    
                    [self enablePlayerButtons];
                    [self enableScrubber]; /* Enable seeking for main content. */
                    
					NSLog(@"enabling seek at %g", CMTimeGetSeconds([player currentTime]));
				}
				else 
				{
					/* Display text indicating that an Ad is now playing. */
					self.isPlayingAdText.text = @"< Ad now playing, seeking is disabled on the movie controller... >";
					
                    [self disablePlayerButtons];
                    [self disableScrubber]; 	/* Disable seeking for ad content. */
                    
					NSLog(@"disabling seek at %g", CMTimeGetSeconds([player currentTime]));
				}
			}
		}
	}
}

#pragma mark Ad list

/* Update current ad list, set slider to match current player item seekable time ranges */
- (void)updateAdList:(NSArray *)newAdList
{
	if (!adList || ![adList isEqualToArray:newAdList]) 
	{
		newAdList = [newAdList copy];
		[adList release];
		adList = newAdList;
        
		[self sliderSyncToPlayerSeekableTimeRanges];
	}
}	

#pragma mark -
#pragma mark Loading the Asset Keys Asynchronously

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

/* --------------------------------------------------------------
 **  Called when an asset fails to prepare for playback for any of
 **  the following reasons:
 ** 
 **  1) values of asset keys did not load successfully, 
 **  2) the asset keys did load successfully, but the asset is not 
 **     playable
 **  3) the item did not become ready to play. 
 ** ----------------------------------------------------------- */

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncScrubber];
    [self disableScrubber];
    [self disablePlayerButtons];
    
    /* Display the error. */
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
														message:[error localizedFailureReason]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

#pragma mark Prepare to play asset

/*
 Invoked at the completion of the loading of the values for all keys on the asset that we require.
 Checks whether loading was successfull and whether the asset is playable.
 If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    /* Make sure that the value of each key has loaded successfully. */
	for (NSString *thisKey in requestedKeys)
	{
		NSError *error = nil;
		AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
		if (keyStatus == AVKeyValueStatusFailed)
		{
			[self assetFailedToPrepareForPlayback:error];
			return;
		}
		/* If you are also implementing the use of -[AVAsset cancelLoading], add your code here to bail 
         out properly in the case of cancellation. */
	}

    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable) 
    {
        /* Generate an error describing the failure. */
		NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
		NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey, 
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey, 
								   nil];
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
	
	/* At this point we're ready to set up for playback of the asset. */

	[self initScrubberTimer];
	[self enableScrubber];
	[self enablePlayerButtons];
	
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (self.playerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [self.playerItem removeObserver:self forKeyPath:kStatusKey];            
		
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
	
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [self.playerItem addObserver:self 
                      forKeyPath:kStatusKey 
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:MyStreamingMovieViewControllerPlayerItemStatusObserverContext];
	
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
	
    seekToZeroBeforePlay = NO;
	
    /* Create new player, if we don't already have one. */
    if (![self player])
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];	
		
        /* Observe the AVPlayer "currentItem" property to find out when any 
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did 
         occur.*/
        [self.player addObserver:self 
                      forKeyPath:kCurrentItemKey 
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:MyStreamingMovieViewControllerCurrentItemObservationContext];
        
        /* A 'currentItem.timedMetadata' property observer to parse the media stream timed metadata. */			
        [self.player addObserver:self 
                      forKeyPath:kTimedMetadataKey 
                         options:0 
                         context:MyStreamingMovieViewControllerTimedMetadataObserverContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self 
                      forKeyPath:kRateKey 
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:MyStreamingMovieViewControllerRateObservationContext];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.playerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs 
         asynchronously; observe the currentItem property to find out when the 
         replacement will/did occur*/
        [[self player] replaceCurrentItemWithPlayerItem:self.playerItem];
        
        [self syncPlayPauseButtons];
    }
	
    [movieTimeControl setValue:0.0];
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed. 
 **  Adjust the movie play and pause button controls when the 
 **  player item "status" value changes. Update the movie 
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item 
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the 
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */

- (void)observeValueForKeyPath:(NSString*) path 
                      ofObject:(id)object 
                        change:(NSDictionary*)change 
                       context:(void*)context
{
	/* AVPlayerItem "status" property value observer. */
	if (context == MyStreamingMovieViewControllerPlayerItemStatusObserverContext)
	{
		[self syncPlayPauseButtons];
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because 
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
                [self removePlayerTimeObserver];
                [self syncScrubber];
                
                [self disableScrubber];
                [self disablePlayerButtons];
            }
            break;
                
            case AVPlayerStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e. 
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                                
                playerLayerView.playerLayer.hidden = NO;
                
                [toolBar setHidden:NO];
                
                /* Show the movie slider control since the movie is now ready to play. */
                movieTimeControl.hidden = NO;
                
                [self enableScrubber];
                [self enablePlayerButtons];
                
                playerLayerView.playerLayer.backgroundColor = [[UIColor blackColor] CGColor];
                
                /* Set the AVPlayerLayer on the view to allow the AVPlayer object to display
                 its content. */	
                [playerLayerView.playerLayer setPlayer:player];

                [self initScrubberTimer];
            }
            break;
                
            case AVPlayerStatusFailed:
            {
                AVPlayerItem *thePlayerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:thePlayerItem.error];
            }
            break;
        }
	}
	/* AVPlayer "rate" property value observer. */
	else if (context == MyStreamingMovieViewControllerRateObservationContext)
	{
        [self syncPlayPauseButtons];
	}
	/* AVPlayer "currentItem" property observer. 
     Called when the AVPlayer replaceCurrentItemWithPlayerItem: 
     replacement will/did occur. */
	else if (context == MyStreamingMovieViewControllerCurrentItemObservationContext)
	{
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* New player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            [self disablePlayerButtons];
            [self disableScrubber];
            
            self.isPlayingAdText.text = @"";
        }
        else /* Replacement of player currentItem has occurred */
        {
            /* Set the AVPlayer for which the player layer displays visual output. */
            [playerLayerView.playerLayer setPlayer:self.player];
            
            /* Specifies that the player should preserve the video’s aspect ratio and 
             fit the video within the layer’s bounds. */
            [playerLayerView setVideoFillMode:AVLayerVideoGravityResizeAspect];
            
            [self syncPlayPauseButtons];
        }
	}
	/* Observe the AVPlayer "currentItem.timedMetadata" property to parse the media stream 
     timed metadata. */
	else if (context == MyStreamingMovieViewControllerTimedMetadataObserverContext) 
	{
		NSArray* array = [[player currentItem] timedMetadata];
		for (AVMetadataItem *metadataItem in array) 
		{
			[self handleTimedMetadata:metadataItem];
		}
	}
	else
	{
		[super observeValueForKeyPath:path ofObject:object change:change context:context];
	}
    
    return;
}

@end
