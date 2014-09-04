/*
    File: MainViewController.m
Abstract: View controller class for AddMusic. Sets up user interface, responds 
to and manages user interaction.
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

Copyright (C) 2009 Apple Inc. All Rights Reserved.

*/


#import "MainViewController.h"
#import <Foundation/Foundation.h>

#pragma mark Audio session callbacks_______________________

// Audio session callback function for responding to audio route changes. If playing 
//		back application audio when the headset is unplugged, this callback pauses 
//		playback and displays an alert that allows the user to resume or stop playback.
//
//		The system takes care of iPod audio pausing during route changes--this callback  
//		is not involved with pausing playback of iPod audio.
void audioRouteChangeListenerCallback (
   void                      *inUserData,
   AudioSessionPropertyID    inPropertyID,
   UInt32                    inPropertyValueSize,
   const void                *inPropertyValue
) {
	
	// ensure that this callback was invoked for a route change
	if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;

	// This callback, being outside the implementation block, needs a reference to the
	//		MainViewController object, which it receives in the inUserData parameter.
	//		You provide this reference when registering this callback (see the call to 
	//		AudioSessionAddPropertyListener).
	MainViewController *controller = (MainViewController *) inUserData;
	
	// if application sound is not playing, there's nothing to do, so return.
	if (controller.appSoundPlayer.playing == 0 ) {

		NSLog (@"Audio route change while application audio is stopped.");
		return;
		
	} else {

		// Determines the reason for the route change, to ensure that it is not
		//		because of a category change.
		CFDictionaryRef	routeChangeDictionary = inPropertyValue;
		
		CFNumberRef routeChangeReasonRef =
						CFDictionaryGetValue (
							routeChangeDictionary,
							CFSTR (kAudioSession_AudioRouteChangeKey_Reason)
						);

		SInt32 routeChangeReason;
		
		CFNumberGetValue (
			routeChangeReasonRef,
			kCFNumberSInt32Type,
			&routeChangeReason
		);
		
		// "Old device unavailable" indicates that a headset was unplugged, or that the
		//	device was removed from a dock connector that supports audio output. This is
		//	the recommended test for when to pause audio.
		if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {

			[controller.appSoundPlayer pause];
			NSLog (@"Output device removed, so application audio was paused.");

			UIAlertView *routeChangeAlertView = 
					[[UIAlertView alloc]	initWithTitle: NSLocalizedString (@"Playback Paused", @"Title for audio hardware route-changed alert view")
												  message: NSLocalizedString (@"Audio output was changed", @"Explanation for route-changed alert view")
												 delegate: controller
										cancelButtonTitle: NSLocalizedString (@"StopPlaybackAfterRouteChange", @"Stop button title")
										otherButtonTitles: NSLocalizedString (@"ResumePlaybackAfterRouteChange", @"Play button title"), nil];
			[routeChangeAlertView show];
			// release takes place in alertView:clickedButtonAtIndex: method
		
		} else {

			NSLog (@"A route change occurred that does not require pausing of application audio.");
		}
	}
}



@implementation MainViewController

@synthesize artworkItem;				// the now-playing media item's artwork image, displayed in the Navigation bar
@synthesize userMediaItemCollection;	// the media item collection created by the user, using the media item picker	
@synthesize playBarButton;				// the button for invoking Play on the music player
@synthesize pauseBarButton;				// the button for invoking Pause on the music player
@synthesize musicPlayer;				// the music player, which plays media items from the iPod library
@synthesize navigationBar;				// the application's Navigation bar
@synthesize noArtworkImage;				// an image to display when a media item has no associated artwork
@synthesize backgroundColorTimer;		// a timer for changing the background color -- represents an application that is
										//		doing something else while iPod music is playing
@synthesize nowPlayingLabel;			// descriptive text shown on the main screen about the now-playing media item
@synthesize appSoundButton;				// the button to invoke playback for the application sound
@synthesize addOrShowMusicButton;		// the button for invoking the media item picker. if the user has already 
										//		specified a media item collection, the title changes to "Show Music" and
										//		the button invokes a table view that shows the specified collection
@synthesize appSoundPlayer;				// An AVAudioPlayer object for playing application sound
@synthesize soundFileURL;				// The path to the application sound
@synthesize interruptedOnPlayback;		// A flag indicating whether or not the application was interrupted during 
										//		application audio playback
@synthesize playedMusicOnce;			// A flag indicating if the user has played iPod library music at least one time
										//		since application launch.
@synthesize playing;					// An application that responds to interruptions must keep track of its playing/
										//		not-playing state.

#pragma mark Music control________________________________

// A toggle control for playing or pausing iPod library music playback, invoked
//		when the user taps the 'playBarButton' in the Navigation bar. 
- (IBAction) playOrPauseMusic: (id)sender {

	MPMusicPlaybackState playbackState = [musicPlayer playbackState];

	if (playbackState == MPMusicPlaybackStateStopped || playbackState == MPMusicPlaybackStatePaused) {
		[musicPlayer play];
	} else if (playbackState == MPMusicPlaybackStatePlaying) {
		[musicPlayer pause];
	}
}

// If there is no selected media item collection, display the media item picker. If there's 
// already a selected collection, display the list of selected songs.
- (IBAction) AddMusicOrShowMusic: (id) sender {    

	// if the user has already chosen some music, display that list
	if (userMediaItemCollection) {
	
		MusicTableViewController *controller = [[MusicTableViewController alloc] initWithNibName: @"MusicTableView" bundle: nil];
		controller.delegate = self;
		
		controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		
		[self presentModalViewController: controller animated: YES];
		[controller release];

	// else, if no music is chosen yet, display the media item picker
	} else {
	
		MPMediaPickerController *picker =
			[[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic];
		
		picker.delegate						= self;
		picker.allowsPickingMultipleItems	= YES;
		picker.prompt						= NSLocalizedString (@"Add songs to play", "Prompt in media item picker");
		
		// The media item picker uses the default UI style, so it needs a default-style
		//		status bar to match it visually
		[[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault animated: YES];
		
		[self presentModalViewController: picker animated: YES];
		[picker release];
	}
}


// Invoked by the delegate of the media item picker when the user is finished picking music.
//		The delegate is either this class or the table view controller, depending on the 
//		state of the application.
- (void) updatePlayerQueueWithMediaCollection: (MPMediaItemCollection *) mediaItemCollection {

	// Configure the music player, but only if the user chose at least one song to play
	if (mediaItemCollection) {

		// If there's no playback queue yet...
		if (userMediaItemCollection == nil) {
		
			// apply the new media item collection as a playback queue for the music player
			[self setUserMediaItemCollection: mediaItemCollection];
			[musicPlayer setQueueWithItemCollection: userMediaItemCollection];
			[self setPlayedMusicOnce: YES];
			[musicPlayer play];

		// Obtain the music player's state so it can then be
		//		restored after updating the playback queue.
		} else {

			// Take note of whether or not the music player is playing. If it is
			//		it needs to be started again at the end of this method.
			BOOL wasPlaying = NO;
			if (musicPlayer.playbackState == MPMusicPlaybackStatePlaying) {
				wasPlaying = YES;
			}
			
			// Save the now-playing item and its current playback time.
			MPMediaItem *nowPlayingItem			= musicPlayer.nowPlayingItem;
			NSTimeInterval currentPlaybackTime	= musicPlayer.currentPlaybackTime;

			// Combine the previously-existing media item collection with the new one
			NSMutableArray *combinedMediaItems	= [[userMediaItemCollection items] mutableCopy];
			NSArray *newMediaItems				= [mediaItemCollection items];
			[combinedMediaItems addObjectsFromArray: newMediaItems];
			
			[self setUserMediaItemCollection: [MPMediaItemCollection collectionWithItems: (NSArray *) combinedMediaItems]];
			[combinedMediaItems release];

			// Apply the new media item collection as a playback queue for the music player.
			[musicPlayer setQueueWithItemCollection: userMediaItemCollection];
			
			// Restore the now-playing item and its current playback time.
			musicPlayer.nowPlayingItem			= nowPlayingItem;
			musicPlayer.currentPlaybackTime		= currentPlaybackTime;
			
			// If the music player was playing, get it playing again.
			if (wasPlaying) {
				[musicPlayer play];
			}
		}

		// Finally, because the music player now has a playback queue, ensure that 
		//		the music play/pause button in the Navigation bar is enabled.
		navigationBar.topItem.leftBarButtonItem.enabled = YES;

		[addOrShowMusicButton	setTitle: NSLocalizedString (@"Show Music", @"Alternate title for 'Add Music' button, after user has chosen some music")
								forState: UIControlStateNormal];
	}
}

// If the music player was paused, leave it paused. If it was playing, it will continue to
//		play on its own. The music player state is "stopped" only if the previous list of songs
//		had finished or if this is the first time the user has chosen songs after app 
//		launch--in which case, invoke play.
- (void) restorePlaybackState {

	if (musicPlayer.playbackState == MPMusicPlaybackStateStopped && userMediaItemCollection) {

		[addOrShowMusicButton	setTitle: NSLocalizedString (@"Show Music", @"Alternate title for 'Add Music' button, after user has chosen some music")
								forState: UIControlStateNormal];
		
		if (playedMusicOnce == NO) {
		
			[self setPlayedMusicOnce: YES];
			[musicPlayer play];
		}
	}

}



#pragma mark Media item picker delegate methods________

// Invoked when the user taps the Done button in the media item picker after having chosen
//		one or more media items to play.
- (void) mediaPicker: (MPMediaPickerController *) mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection {
  
	// Dismiss the media item picker.
	[self dismissModalViewControllerAnimated: YES];
	
	// Apply the chosen songs to the music player's queue.
	[self updatePlayerQueueWithMediaCollection: mediaItemCollection];

	[[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
}

// Invoked when the user taps the Done button in the media item picker having chosen zero
//		media items to play
- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker {

	[self dismissModalViewControllerAnimated: YES];
	
	[[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated: YES];
}



#pragma mark Music notification handlers__________________

// When the now-playing item changes, update the media item artwork and the now-playing label.
- (void) handle_NowPlayingItemChanged: (id) notification {

	MPMediaItem *currentItem = [musicPlayer nowPlayingItem];
	
	// Assume that there is no artwork for the media item.
	UIImage *artworkImage = noArtworkImage;
	
	// Get the artwork from the current media item, if it has artwork.
	MPMediaItemArtwork *artwork = [currentItem valueForProperty: MPMediaItemPropertyArtwork];
	
	// Obtain a UIImage object from the MPMediaItemArtwork object
	if (artwork) {
		artworkImage = [artwork imageWithSize: CGSizeMake (30, 30)];
	}
	
	// Obtain a UIButton object and set its background to the UIImage object
	UIButton *artworkView = [[UIButton alloc] initWithFrame: CGRectMake (0, 0, 30, 30)];
	[artworkView setBackgroundImage: artworkImage forState: UIControlStateNormal];

	// Obtain a UIBarButtonItem object and initialize it with the UIButton object
	UIBarButtonItem *newArtworkItem = [[UIBarButtonItem alloc] initWithCustomView: artworkView];
	[self setArtworkItem: newArtworkItem];
	[newArtworkItem release];
	
	[artworkItem setEnabled: NO];
	
	// Display the new media item artwork
	[navigationBar.topItem setRightBarButtonItem: artworkItem animated: YES];
	
	// Display the artist and song name for the now-playing media item
	[nowPlayingLabel setText: [
			NSString stringWithFormat: @"%@ %@ %@ %@",
			NSLocalizedString (@"Now Playing:", @"Label for introducing the now-playing song title and artist"),
			[currentItem valueForProperty: MPMediaItemPropertyTitle],
			NSLocalizedString (@"by", @"Article between song name and artist name"),
			[currentItem valueForProperty: MPMediaItemPropertyArtist]]];

	if (musicPlayer.playbackState == MPMusicPlaybackStateStopped) {
		// Provide a suitable prompt to the user now that their chosen music has 
		//		finished playing.
		[nowPlayingLabel setText: [
				NSString stringWithFormat: @"%@",
				NSLocalizedString (@"Music-ended Instructions", @"Label for prompting user to play music again after it has stopped")]];

	}
}

// When the playback state changes, set the play/pause button in the Navigation bar
//		appropriately.
- (void) handle_PlaybackStateChanged: (id) notification {

	MPMusicPlaybackState playbackState = [musicPlayer playbackState];
	
	if (playbackState == MPMusicPlaybackStatePaused) {
	
		navigationBar.topItem.leftBarButtonItem = playBarButton;
		
	} else if (playbackState == MPMusicPlaybackStatePlaying) {
	
		navigationBar.topItem.leftBarButtonItem = pauseBarButton;

	} else if (playbackState == MPMusicPlaybackStateStopped) {
	
		navigationBar.topItem.leftBarButtonItem = playBarButton;
		
		// Even though stopped, invoking 'stop' ensures that the music player will play  
		//		its queue from the start.
		[musicPlayer stop];

	}
}

- (void) handle_iPodLibraryChanged: (id) notification {

	// Implement this method to update cached collections of media items when the 
	// user performs a sync while your application is running. This sample performs 
	// no explicit media queries, so there is nothing to update.
}



#pragma mark Application playback control_________________

- (IBAction) playAppSound: (id) sender {

	[appSoundPlayer play];
	playing = YES;
	[appSoundButton setEnabled: NO];
}

// delegate method for the audio route change alert view; follows the protocol specified
//	in the UIAlertViewDelegate protocol.
- (void) alertView: routeChangeAlertView clickedButtonAtIndex: buttonIndex {

	if ((NSInteger) buttonIndex == 1) {
		[appSoundPlayer play];
	} else {
		[appSoundPlayer setCurrentTime: 0];
		[appSoundButton setEnabled: YES];
	}
	
	[routeChangeAlertView release];			
}



#pragma mark AV Foundation delegate methods____________

- (void) audioPlayerDidFinishPlaying: (AVAudioPlayer *) appSoundPlayer successfully: (BOOL) flag {

	playing = NO;
	[appSoundButton setEnabled: YES];
}

- (void) audioPlayerBeginInterruption: player {

	NSLog (@"Interrupted. The system has paused audio playback.");
	
	if (playing) {
	
		playing = NO;
		interruptedOnPlayback = YES;
	}
}

- (void) audioPlayerEndInterruption: player {

	NSLog (@"Interruption ended. Resuming audio playback.");
	
	// Reactivates the audio session, whether or not audio was playing
	//		when the interruption arrived.
	[[AVAudioSession sharedInstance] setActive: YES error: nil];
	
	if (interruptedOnPlayback) {
	
		[appSoundPlayer prepareToPlay];
		[appSoundPlayer play];
		playing = YES;
		interruptedOnPlayback = NO;
	}
}



#pragma mark Table view delegate methods________________

// Invoked when the user taps the Done button in the table view.
- (void) musicTableViewControllerDidFinish: (MusicTableViewController *) controller {
	
	[self dismissModalViewControllerAnimated: YES];
	[self restorePlaybackState];
}



#pragma mark Application setup____________________________

#if TARGET_IPHONE_SIMULATOR
#warning *** Simulator mode: iPod library access works only when running on a device.
#endif

- (void) setupApplicationAudio {
	
	// Gets the file system path to the sound to play.
	NSString *soundFilePath = [[NSBundle mainBundle]	pathForResource:	@"sound"
														ofType:				@"caf"];

	// Converts the sound's file path to an NSURL object
	NSURL *newURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
	self.soundFileURL = newURL;
	[newURL release];

	// Registers this class as the delegate of the audio session.
	[[AVAudioSession sharedInstance] setDelegate: self];
	
	// The AmbientSound category allows application audio to mix with Media Player
	// audio. The category also indicates that application audio should stop playing 
	// if the Ring/Siilent switch is set to "silent" or the screen locks.
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error: nil];
/*
	// Use this code instead to allow the app sound to continue to play when the screen is locked.
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];

	UInt32 doSetProperty = 0;
	AudioSessionSetProperty (
		kAudioSessionProperty_OverrideCategoryMixWithOthers,
		sizeof (doSetProperty),
		&doSetProperty
	);
*/

	// Registers the audio route change listener callback function
	AudioSessionAddPropertyListener (
		kAudioSessionProperty_AudioRouteChange,
		audioRouteChangeListenerCallback,
		self
	);

	// Activates the audio session.
	
	NSError *activationError = nil;
	[[AVAudioSession sharedInstance] setActive: YES error: &activationError];

	// Instantiates the AVAudioPlayer object, initializing it with the sound
	AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: soundFileURL error: nil];
	self.appSoundPlayer = newPlayer;
	[newPlayer release];
	
	// "Preparing to play" attaches to the audio hardware and ensures that playback
	//		starts quickly when the user taps Play
	[appSoundPlayer prepareToPlay];
	[appSoundPlayer setVolume: 1.0];
	[appSoundPlayer setDelegate: self];
}


// To learn about notifications, see "Notifications" in Cocoa Fundamentals Guide.
- (void) registerForMediaPlayerNotifications {

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	[notificationCenter addObserver: self
						   selector: @selector (handle_NowPlayingItemChanged:)
							   name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
							 object: musicPlayer];
	
	[notificationCenter addObserver: self
						   selector: @selector (handle_PlaybackStateChanged:)
							   name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
							 object: musicPlayer];

/*
	// This sample doesn't use libray change notifications; this code is here to show how
	//		it's done if you need it.
	[notificationCenter addObserver: self
						   selector: @selector (handle_iPodLibraryChanged:)
							   name: MPMediaLibraryDidChangeNotification
							 object: musicPlayer];
	
	[[MPMediaLibrary defaultMediaLibrary] beginGeneratingLibraryChangeNotifications];
*/

	[musicPlayer beginGeneratingPlaybackNotifications];
}


// To learn about the Settings bundle and user preferences, see User Defaults Programming Topics
//		for Cocoa and "The Settings Bundle" in iPhone Application Programming Guide 

// Returns whether or not to use the iPod music player instead of the application music player.
- (BOOL) useiPodPlayer {

	if ([[NSUserDefaults standardUserDefaults] boolForKey: PLAYER_TYPE_PREF_KEY]) {
		return YES;		
	} else {
		return NO;
	}		
}

// Configure the application.
- (void) viewDidLoad {

    [super viewDidLoad];

	[self setupApplicationAudio];
	
	[self setPlayedMusicOnce: NO];

	[self setNoArtworkImage:	[UIImage imageNamed: @"no_artwork.png"]];		

	[self setPlayBarButton:		[[UIBarButtonItem alloc]	initWithBarButtonSystemItem: UIBarButtonSystemItemPlay
																				 target: self
																				 action: @selector (playOrPauseMusic:)]];

	[self setPauseBarButton:	[[UIBarButtonItem alloc]	initWithBarButtonSystemItem: UIBarButtonSystemItemPause
																				 target: self
																				 action: @selector (playOrPauseMusic:)]];

	[addOrShowMusicButton	setTitle: NSLocalizedString (@"Add Music", @"Title for 'Add Music' button, before user has chosen some music")
							forState: UIControlStateNormal];

	[appSoundButton			setTitle: NSLocalizedString (@"Play App Sound", @"Title for 'Play App Sound' button")
							forState: UIControlStateNormal];

	[nowPlayingLabel setText: NSLocalizedString (@"Instructions", @"Brief instructions to user, shown at launch")];
	
	// Instantiate the music player. If you specied the iPod music player in the Settings app,
	//		honor the current state of the built-in iPod app.
	if ([self useiPodPlayer]) {
	
		[self setMusicPlayer: [MPMusicPlayerController iPodMusicPlayer]];
		
		if ([musicPlayer nowPlayingItem]) {
		
			navigationBar.topItem.leftBarButtonItem.enabled = YES;
			
			// Update the UI to reflect the now-playing item. 
			[self handle_NowPlayingItemChanged: nil];
			
			if ([musicPlayer playbackState] == MPMusicPlaybackStatePaused) {
				navigationBar.topItem.leftBarButtonItem = playBarButton;
			}
		}
		
	} else {
	
		[self setMusicPlayer: [MPMusicPlayerController applicationMusicPlayer]];
		
		// By default, an application music player takes on the shuffle and repeat modes
		//		of the built-in iPod app. Here they are both turned off.
		[musicPlayer setShuffleMode: MPMusicShuffleModeOff];
		[musicPlayer setRepeatMode: MPMusicRepeatModeNone];
	}	

	[self registerForMediaPlayerNotifications];

	// Configure a timer to change the background color. The changing color represents an 
	//		application that is doing something else while iPod music is playing.
	[self setBackgroundColorTimer: [NSTimer scheduledTimerWithTimeInterval: 3.5
																	target: self
																  selector: @selector (updateBackgroundColor)
																  userInfo: nil
																   repeats: YES]];
}

// Invoked by the backgroundColorTimer.
- (void) updateBackgroundColor {

	[UIView beginAnimations: nil context: nil];
    [UIView setAnimationDuration: 3.0];

	CGFloat redLevel	= rand() / (float) RAND_MAX;
	CGFloat greenLevel	= rand() / (float) RAND_MAX;
	CGFloat blueLevel	= rand() / (float) RAND_MAX;
	
	self.view.backgroundColor = [UIColor colorWithRed: redLevel
												green: greenLevel
												 blue: blueLevel
												alpha: 1.0];
	[UIView commitAnimations];
}

#pragma mark Application state management_____________

- (void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void) viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {

/*
	// This sample doesn't use libray change notifications; this code is here to show how
	//		it's done if you need it.
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MPMediaLibraryDidChangeNotification
												  object: musicPlayer];

	[[MPMediaLibrary defaultMediaLibrary] endGeneratingLibraryChangeNotifications];
	
*/
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
												  object: musicPlayer];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
												  object: musicPlayer];

	[musicPlayer endGeneratingPlaybackNotifications];
	[musicPlayer				release];

	[artworkItem				release]; 
	[backgroundColorTimer		invalidate];
	[backgroundColorTimer		release];
	[navigationBar				release];
	[noArtworkImage				release];
	[nowPlayingLabel			release];
	[pauseBarButton				release];
	[playBarButton				release];
	[soundFileURL				release];
	[userMediaItemCollection	release];

    [super dealloc];
}


@end
