/*

    File: MyMovieViewController.m 
Abstract:  A UIViewController controller subclass that implements a movie playback view.
Uses a MyMovieController object to control playback of a movie.
Adds and removes an overlay view to the view hierarchy. Handles button presses to the
'Close Movie' button in the overlay view.
Adds and removes a background view to hide any underlying user interface controls when playing a movie.
Gets user movie settings preferences by calling the MoviePlayerUserPref methods. Apply these settings to the movie with the MyMovieController singleton.
 
 Version: 1.5 
 
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

#import "MyMovieViewController.h"
#import "MoviePlayerUserPrefs.h"

CGFloat kMovieViewOffsetX = 20.0;
CGFloat kMovieViewOffsetY = 20.0;

@interface MyMovieViewController (OverlayView)

-(void)addOverlayView;
-(void)removeOverlayView;
-(void)resizeOverlayWindow;

@end

@interface MyMovieViewController(MovieControllerInternal)
-(void)createAndPlayMovieForURL:(NSURL *)movieURL sourceType:(MPMovieSourceType)sourceType;
-(void)applyUserSettingsToMoviePlayer;
-(void)moviePlayBackDidFinish:(NSNotification*)notification;
-(void)loadStateDidChange:(NSNotification *)notification;
-(void)moviePlayBackStateDidChange:(NSNotification*)notification;
-(void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification;
-(void)installMovieNotificationObservers;
-(void)removeMovieNotificationHandlers;
-(void)deletePlayerAndNotificationObservers;
@end

@interface MyMovieViewController (ViewController)
-(void)removeMovieViewFromViewHierarchy;
@end

@implementation MyMovieViewController(ViewController)

#pragma mark View Controller

/* Sent to the view controller after the user interface rotates. */
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	/* Size movie view to fit parent view. */
	CGRect viewInsetRect = CGRectInset ([self.view bounds],
										kMovieViewOffsetX,
										kMovieViewOffsetY );
	[[[self moviePlayerController] view] setFrame:viewInsetRect];

    /* Size the overlay view for the current orientation. */
	[self resizeOverlayWindow];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    /* Return YES for supported orientations. */
    return YES;
}

- (BOOL)canBecomeFirstResponder
{
	return YES;
}

- (void)viewDidUnload
{
    [self deletePlayerAndNotificationObservers];
    
    [super viewDidUnload];
}

/* Notifies the view controller that its view is about to be become visible. */
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    /* Size the overlay view for the current orientation. */
	[self resizeOverlayWindow];
    /* Update user settings for the movie (in case they changed). */
    [self applyUserSettingsToMoviePlayer];
}

/* Notifies the view controller that its view is about to be dismissed, 
 covered, or otherwise hidden from view. */
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    /* Remove the movie view from the current view hierarchy. */
	[self removeMovieViewFromViewHierarchy];
    /* Removie the overlay view. */
	[self removeOverlayView];
    /* Remove the background view. */
	[self.backgroundView removeFromSuperview];
    
    /* Delete the movie player object and remove the notification observers. */
    [self deletePlayerAndNotificationObservers];
}

- (void)dealloc 
{	
    [self setMoviePlayerController:nil];
    self.imageView = nil;
    self.movieBackgroundImageView = nil;
    self.backgroundView = nil;
    self.overlayController = nil;

}

/* Remove the movie view from the view hierarchy. */
-(void)removeMovieViewFromViewHierarchy
{
    MPMoviePlayerController *player = [self moviePlayerController];
    
	[player.view removeFromSuperview];
}

#pragma mark Error Reporting

-(void)displayError:(NSError *)theError
{
	if (theError)
	{
		UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Error"
                              message: [theError localizedDescription]
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
		[alert show];
	}
}

@end

#pragma mark -
@implementation MyMovieViewController (OverlayView)


/* Add an overlay view on top of the movie. This view will display movie
 play states and includes a 'Close Movie' button. */
-(void)addOverlayView
{
    MPMoviePlayerController *player = [self moviePlayerController];
    
    if (!([self.overlayController.view isDescendantOfView:self.view])
        && ([player.view isDescendantOfView:self.view])) 
    {
        // add an overlay view to the window view hierarchy
        [self.view addSubview:self.overlayController.view];
    }
}

/* Remove overlay view from the view hierarchy. */
-(void)removeOverlayView
{
	[self.overlayController.view removeFromSuperview];
}

-(void)resizeOverlayWindow
{
	CGRect frame = self.overlayController.view.frame;
	frame.origin.x = round((self.view.frame.size.width - frame.size.width) / 2.0);
	frame.origin.y = round((self.view.frame.size.height - frame.size.height) / 2.0);
	self.overlayController.view.frame = frame;
}

@end

#pragma mark -
@implementation MyMovieViewController

@synthesize moviePlayerController;

@synthesize imageView;
@synthesize movieBackgroundImageView;
@synthesize backgroundView;
@synthesize overlayController;

@synthesize appDelegate;

/* Action method for the overlay view 'Close Movie' button.
 Remove the movie view and overlay view from the window,
 dispose the movie object and remove the notification
 handlers. */
-(IBAction)overlayViewCloseButtonPress:(id)sender
{
	[[self moviePlayerController] stop];
    
	[self removeMovieViewFromViewHierarchy];
    
	[self removeOverlayView];
	[self.backgroundView removeFromSuperview];
    
    [self deletePlayerAndNotificationObservers];
}

/*  
 Called by the MoviePlayerAppDelegate (UIApplicationDelegate protocol) 
 applicationWillEnterForeground when the app is about to enter
 the foreground.
 */
- (void)viewWillEnterForeground
{
	/* Set the movie object settings (control mode, background color, and so on) 
       in case these changed. */
	[self applyUserSettingsToMoviePlayer];
}

#pragma mark Play Movie Actions

/* Called soon after the Play Movie button is pressed to play the local movie. */
-(void)playMovieFile:(NSURL *)movieFileURL
{
    [self createAndPlayMovieForURL:movieFileURL sourceType:MPMovieSourceTypeFile];   
}

/* Called soon after the Play Movie button is pressed to play the streaming movie. */
-(void)playMovieStream:(NSURL *)movieFileURL
{
    MPMovieSourceType movieSourceType = MPMovieSourceTypeUnknown;
    /* If we have a streaming url then specify the movie source type. */
    if ([[movieFileURL pathExtension] compare:@"m3u8" options:NSCaseInsensitiveSearch] == NSOrderedSame) 
    {
        movieSourceType = MPMovieSourceTypeStreaming;
    }
    [self createAndPlayMovieForURL:movieFileURL sourceType:movieSourceType];   
}

@end

#pragma mark -
#pragma mark Movie Player Controller Methods
#pragma mark -

@implementation MyMovieViewController (MovieControllerInternal)

#pragma mark Create and Play Movie URL

/*
 Create a MPMoviePlayerController movie object for the specified URL and add movie notification
 observers. Configure the movie object for the source type, scaling mode, control style, background
 color, background image, repeat mode and AirPlay mode. Add the view containing the movie content and 
 controls to the existing view hierarchy.
 */
-(void)createAndConfigurePlayerWithURL:(NSURL *)movieURL sourceType:(MPMovieSourceType)sourceType 
{    
    /* Create a new movie player object. */
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
    
    if (player) 
    {
        /* Save the movie object. */
        [self setMoviePlayerController:player];
        
        /* Register the current object as an observer for the movie
         notifications. */
        [self installMovieNotificationObservers];
        
        /* Specify the URL that points to the movie file. */
        [player setContentURL:movieURL];        
        
        /* If you specify the movie type before playing the movie it can result 
         in faster load times. */
        [player setMovieSourceType:sourceType];
        
        /* Apply the user movie preference settings to the movie player object. */
        [self applyUserSettingsToMoviePlayer];
        
        /* Add a background view as a subview to hide our other view controls 
         underneath during movie playback. */
        [self.view addSubview:self.backgroundView];
        
        CGRect viewInsetRect = CGRectInset ([self.view bounds],
                                            kMovieViewOffsetX,
                                            kMovieViewOffsetY );
        /* Inset the movie frame in the parent view frame. */
        [[player view] setFrame:viewInsetRect];
        
        [player view].backgroundColor = [UIColor lightGrayColor];
        
        /* To present a movie in your application, incorporate the view contained 
         in a movie player’s view property into your application’s view hierarchy. 
         Be sure to size the frame correctly. */
        [self.view addSubview: [player view]];        
    }    
}

/* Load and play the specified movie url with the given file type. */
-(void)createAndPlayMovieForURL:(NSURL *)movieURL sourceType:(MPMovieSourceType)sourceType
{
    [self createAndConfigurePlayerWithURL:movieURL sourceType:sourceType];
        
    /* Play the movie! */
    [[self moviePlayerController] play];
}

#pragma mark Movie Notification Handlers

/*  Notification called when the movie finished playing. */
- (void) moviePlayBackDidFinish:(NSNotification*)notification
{
    NSNumber *reason = [notification userInfo][MPMoviePlayerPlaybackDidFinishReasonUserInfoKey]; 
	switch ([reason integerValue]) 
	{
            /* The end of the movie was reached. */
		case MPMovieFinishReasonPlaybackEnded:
            /*
             Add your code here to handle MPMovieFinishReasonPlaybackEnded.
             */
			break;
            
            /* An error was encountered during playback. */
		case MPMovieFinishReasonPlaybackError:
            NSLog(@"An error was encountered during playback");
            [self performSelectorOnMainThread:@selector(displayError:) withObject:[notification userInfo][@"error"] 
                                waitUntilDone:NO];
            [self removeMovieViewFromViewHierarchy];
            [self removeOverlayView];
            [self.backgroundView removeFromSuperview];
			break;
            
            /* The user stopped playback. */
		case MPMovieFinishReasonUserExited:
            [self removeMovieViewFromViewHierarchy];
            [self removeOverlayView];
            [self.backgroundView removeFromSuperview];
			break;
            
		default:
			break;
	}
}

/* Handle movie load state changes. */
- (void)loadStateDidChange:(NSNotification *)notification 
{   
	MPMoviePlayerController *player = notification.object;
	MPMovieLoadState loadState = player.loadState;	
    
	/* The load state is not known at this time. */
	if (loadState & MPMovieLoadStateUnknown)
	{
        [self.overlayController setLoadStateDisplayString:@"n/a"];

        [overlayController setLoadStateDisplayString:@"unknown"];       
	}
	
	/* The buffer has enough data that playback can begin, but it 
	 may run out of data before playback finishes. */
	if (loadState & MPMovieLoadStatePlayable)
	{
        [overlayController setLoadStateDisplayString:@"playable"];
	}
	
	/* Enough data has been buffered for playback to continue uninterrupted. */
	if (loadState & MPMovieLoadStatePlaythroughOK)
	{
        // Add an overlay view on top of the movie view
        [self addOverlayView];
        
        [overlayController setLoadStateDisplayString:@"playthrough ok"];
	}
	
	/* The buffering of data has stalled. */
	if (loadState & MPMovieLoadStateStalled)
	{
        [overlayController setLoadStateDisplayString:@"stalled"];
	}
}

/* Called when the movie playback state has changed. */
- (void) moviePlayBackStateDidChange:(NSNotification*)notification
{
	MPMoviePlayerController *player = notification.object;
    
	/* Playback is currently stopped. */
	if (player.playbackState == MPMoviePlaybackStateStopped) 
	{
        [overlayController setPlaybackStateDisplayString:@"stopped"];
	}
	/*  Playback is currently under way. */
	else if (player.playbackState == MPMoviePlaybackStatePlaying) 
	{
        [overlayController setPlaybackStateDisplayString:@"playing"];
	}
	/* Playback is currently paused. */
	else if (player.playbackState == MPMoviePlaybackStatePaused) 
	{
        [overlayController setPlaybackStateDisplayString:@"paused"];
	}
	/* Playback is temporarily interrupted, perhaps because the buffer 
	 ran out of content. */
	else if (player.playbackState == MPMoviePlaybackStateInterrupted) 
	{
        [overlayController setPlaybackStateDisplayString:@"interrupted"];
	}
}

/* Notifies observers of a change in the prepared-to-play state of an object 
 conforming to the MPMediaPlayback protocol. */
- (void) mediaIsPreparedToPlayDidChange:(NSNotification*)notification
{
	// Add an overlay view on top of the movie view
    [self addOverlayView];
}

#pragma mark Install Movie Notifications

/* Register observers for the various movie object notifications. */
-(void)installMovieNotificationObservers
{
    MPMoviePlayerController *player = [self moviePlayerController];
    
	[[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(loadStateDidChange:) 
                                                 name:MPMoviePlayerLoadStateDidChangeNotification 
                                               object:player];

	[[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(moviePlayBackDidFinish:) 
                                                 name:MPMoviePlayerPlaybackDidFinishNotification 
                                               object:player];
    
	[[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(mediaIsPreparedToPlayDidChange:) 
                                                 name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification 
                                               object:player];
    
	[[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(moviePlayBackStateDidChange:) 
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification 
                                               object:player];        
}

#pragma mark Remove Movie Notification Handlers

/* Remove the movie notification observers from the movie object. */
-(void)removeMovieNotificationHandlers
{    
    MPMoviePlayerController *player = [self moviePlayerController];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:player];
}

/* Delete the movie player object, and remove the movie notification observers. */
-(void)deletePlayerAndNotificationObservers
{
    [self removeMovieNotificationHandlers];
    [self setMoviePlayerController:nil];
}

#pragma mark Movie Settings

/* Apply user movie preference settings (these are set from the Settings: iPhone Settings->Movie Player)
   for scaling mode, control style, background color, repeat mode, application audio session, background
   image and AirPlay mode. 
 */
-(void)applyUserSettingsToMoviePlayer
{
    MPMoviePlayerController *player = [self moviePlayerController];
    if (player) 
    {
        player.scalingMode = [MoviePlayerUserPrefs scalingModeUserSetting];
        player.controlStyle =[MoviePlayerUserPrefs controlStyleUserSetting];	
        player.backgroundView.backgroundColor = [MoviePlayerUserPrefs backgroundColorUserSetting];
        player.repeatMode = [MoviePlayerUserPrefs repeatModeUserSetting];
        if ([MoviePlayerUserPrefs backgroundImageUserSetting] == YES)
        {
            [self.movieBackgroundImageView setFrame:[self.view bounds]];
            [player.backgroundView addSubview:self.movieBackgroundImageView];
        }
        else
        {
            [self.movieBackgroundImageView removeFromSuperview];
        }
        
        /* Indicate the movie player allows AirPlay movie playback. */
        player.allowsAirPlay = YES;        
    }
}



@end



