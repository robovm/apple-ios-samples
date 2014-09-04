/*
 
 
     File: APLViewController.m
 Abstract: ViewController class implementation, defines categories: PlayControl and PlayAsset.
  Version: 1.0
 
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
#import "APLViewController.h"
#import "APLPlayerView.h"
#import "APLCustomAVARLDelegate.h"

/* Asset keys */
NSString * const kPlayableKey		= @"playable";

/* PlayerItem keys */
NSString * const kStatusKey         = @"status";

/* AVPlayer keys */
NSString * const kRateKey			= @"rate";
NSString * const kCurrentItemKey	= @"currentItem";

static void *AVARLDelegateDemoViewControllerRateObservationContext = &AVARLDelegateDemoViewControllerRateObservationContext;
static void *AVARLDelegateDemoViewControllerStatusObservationContext = &AVARLDelegateDemoViewControllerStatusObservationContext;
static void *AVARLDelegateDemoViewControllerCurrentItemObservationContext = &AVARLDelegateDemoViewControllerCurrentItemObservationContext;


@interface APLViewController ()
{
    BOOL seekToZeroBeforePlay;
    APLCustomAVARLDelegate *delegate;
}

@property (retain, nonatomic) IBOutlet APLPlayerView *playView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *pauseButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic, copy) NSURL* URL;
@property (readwrite, retain, setter=setPlayer:, getter=player) AVPlayer* player;
@property (retain) AVPlayerItem* playerItem;

- (IBAction) issuePause:(id)sender;
- (IBAction) issuePlay:(id)sender;
- (void) setupToolbar;
- (void) initializeView;
- (void) viewDidLoad;
- (void) setURL:(NSURL *)URL;
- (void) configDelegates:(AVURLAsset *) asset;
@end

/*!
 *  Interface for the play control buttons.
 *  Play
 *  Pause
 */
@interface APLViewController (PlayControl)
- (void) showButton:(id) button;
- (void) showPauseButton;
- (void) showPlayButton;
- (void) syncPlayPauseButtons;
- (void) enablePlayerButtons;
- (void) disablePlayerButtons;
@end

/*!
 *  Interface for the AVPlayer
 *  - observe the properties
 *  - initialize the play
 *  - play status
 *  - play failed
 *  - play ended
 */
@interface APLViewController (PlayAsset)
- (void) observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void) prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;
- (BOOL) isPlaying;
- (void) assetFailedToPrepareForPlayback:(NSError *)error;
- (void) playerItemDidReachEnd:(NSNotification *)notification;
@end

#pragma mark - APLViewController

@implementation APLViewController

@synthesize player, playerItem, playView, toolbar, playButton, pauseButton;

- (void) setupToolbar
{
    self.toolbar.items = [NSArray arrayWithObjects:self.playButton,  nil];
    [self syncPlayPauseButtons];
}

- (void) initializeView
{
    // Restore saved media from the defaults system.
    NSURL *URL = [NSURL URLWithString:@"cplp://devimages.apple.com/samplecode/AVARLDelegateDemo/BipBop_gear3_segmented/redirect_prog_index.m3u8"];
    
	if (URL)
	{
		[self setURL:URL];
    }
}

- (void) viewDidLoad
{
    [self setupToolbar];
    [self initializeView];
    [super viewDidLoad];    
}

/*!
 *  Create the asset to play (using the given URL).
 *  Configure the asset properties and callbacks when the asset is ready.
 */
- (void) setURL:(NSURL*)URL
{
	if ([self URL] != URL)
	{
		self->_URL = [URL copy];
		
        /*
         Create an asset for inspection of a resource referenced by a given URL.
         Load the values for the asset keys  "playable".
         */
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:self.URL options:nil];
        [self configDelegates:asset];
        
        NSArray *requestedKeys = [NSArray arrayWithObjects:kPlayableKey, nil];
        
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

/*!
 *  Create and setup the custom delegae instance.
 */
- (void) configDelegates:(AVURLAsset*) asset
{
    //Setup the delegate for custom URL.
    self->delegate = [[APLCustomAVARLDelegate alloc] init];
    AVAssetResourceLoader *resourceLoader = asset.resourceLoader;
    [resourceLoader setDelegate:delegate queue:dispatch_queue_create("AVARLDelegateDemo loader", nil)];
    
}

/*!
 *  Gets called when the play button is pressed.
 *  Start the playback of the asset and show the pause button.
 */
- (IBAction) issuePlay:(id)sender {
    if (YES == seekToZeroBeforePlay)
	{
		seekToZeroBeforePlay = NO;
		[self.player seekToTime:kCMTimeZero];
	}
    
	[self.player play];
    [self showPauseButton ];
}

/*!
 *  Gets called when the pause button is pressed.
 *  Stop the play and show the play button.
 */
- (IBAction) issuePause:(id)sender {
    [self.player pause];
    [self showPlayButton];
}
@end

#pragma mark - APLViewController PlayControl

@implementation APLViewController (PlayControl)

- (void) showButton:(id)button
{
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[self.toolbar items]];
    [toolbarItems replaceObjectAtIndex:0 withObject:button];
    self.toolbar.items = toolbarItems;
}

- (void) showPlayButton
{
    [self showButton:self.playButton];
}

- (void) showPauseButton
{
    [self showButton:self.pauseButton];
}

- (void) syncPlayPauseButtons
{
    //If we are playing, show the pause button otherwise show the play button
    if ([self isPlaying])
    {
        [self showPauseButton];
    } else
    {
        [self showPlayButton];
    }
}

-(void) enablePlayerButtons
{
    self.playButton.enabled = YES;
    self.pauseButton.enabled = YES;
}

-(void) disablePlayerButtons
{
    self.playButton.enabled = NO;
    self.pauseButton.enabled = NO;
}

@end

#pragma mark - APLViewController PlayAsset

@implementation APLViewController (PlayAsset)
/*!
 *  Called when the value at the specified key path relative
 *  to the given object has changed.
 *  Adjust the movie play and pause button controls when the
 *  player item "status" value changes. Update the movie
 *  scrubber control when the player item is ready to play.
 *  Adjust the movie scrubber control when the player item
 *  "rate" value changes. For updates of the player
 *  "currentItem" property, set the AVPlayer for which the
 *  player layer displays visual output.
 *  NOTE: this method is invoked on the main queue.
 */
- (void) observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
	/* AVPlayerItem "status" property value observer. */
	if (context == AVARLDelegateDemoViewControllerStatusObservationContext)
	{
		[self syncPlayPauseButtons];
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
                [self disablePlayerButtons];
            }
            break;
                
            case AVPlayerStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                [self enablePlayerButtons];
            }
            break;
                
            case AVPlayerStatusFailed:
            {
                AVPlayerItem *pItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:pItem.error];
            }
            break;
        }
	}
	/* AVPlayer "rate" property value observer. */
	else if (context == AVARLDelegateDemoViewControllerRateObservationContext)
	{
        [self syncPlayPauseButtons];
	}
	/* 
      AVPlayer "currentItem" property observer.
      Called when the AVPlayer replaceCurrentItemWithPlayerItem:
      replacement will/did occur. 
     */
	else if (context == AVARLDelegateDemoViewControllerCurrentItemObservationContext)
	{
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* Is the new player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            [self disablePlayerButtons];
        }
        else /* Replacement of player currentItem has occurred */
        {
            /* Set the AVPlayer for which the player layer displays visual output. */
            [self.playView setPlayer:self.player];
            
            /* Specifies that the player should preserve the video’s aspect ratio and
             fit the video within the layer’s bounds. */
            [self.playView setVideoFillMode:AVLayerVideoGravityResizeAspect];
            
            [self syncPlayPauseButtons];
        }
	}
	else
	{
		[super observeValueForKeyPath:path ofObject:object change:change context:context];
	}

}

/*!
 *  Invoked at the completion of the loading of the values for all keys on the asset that we require.
 *  Checks whether loading was successfull and whether the asset is playable.
 *  If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void) prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
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
		/* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
	}
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Generate an error describing the failure. */
		NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
		NSString *localizedFailureReason = NSLocalizedString(@"The contents of the resource at the specified URL are not playable.", @"Item cannot be played failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey,
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
								   nil];
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
	
	/* At this point we're ready to set up for playback of the asset. */
    
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
                          context:AVARLDelegateDemoViewControllerStatusObservationContext];
	
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
	
    seekToZeroBeforePlay = NO;
	
    /* Create new player, if we don't already have one. */
    if (!self.player)
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
		
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [self.player addObserver:self
                      forKeyPath:kCurrentItemKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVARLDelegateDemoViewControllerCurrentItemObservationContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [self.player addObserver:self
                      forKeyPath:kRateKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVARLDelegateDemoViewControllerRateObservationContext];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if (self.player.currentItem != self.playerItem)
    {
        /* Replace the player item with a new player item. The item replacement occurs
         asynchronously; observe the currentItem property to find out when the
         replacement will/did occur*/
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
        
        [self syncPlayPauseButtons];
    }
	
}

- (BOOL) isPlaying
{
    return [self.player rate] != 0.f;
}

/*!
 *  Called when an asset fails to prepare for playback for any of
 *  the following reasons:
 *
 *  1) values of asset keys did not load successfully,
 *  2) the asset keys did load successfully, but the asset is not
 *     playable
 *  3) the item did not become ready to play.
 */
-(void) assetFailedToPrepareForPlayback:(NSError *)error
{
    [self disablePlayerButtons];
    
    /* Display the error. */
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
														message:[error localizedFailureReason]
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
}

/*! 
 *  Called when the player item has played to its end time.
 */
- (void) playerItemDidReachEnd:(NSNotification *)notification
{
	/* After the movie has played to its end time, seek back to time zero
     to play it again. */
	seekToZeroBeforePlay = YES;
}
@end
