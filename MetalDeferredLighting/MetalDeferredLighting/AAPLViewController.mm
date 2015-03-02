/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  View Controller for Metal Sample Code. Maintains a CADisplayLink timer that runs on the main thread and triggers rendering in AAPLView. Provides update callbacks to its delegate on the timer, prior to triggering rendering.
  
 */
#import "AAPLViewController.h"
#import "AAPLView.h"
#import "AAPLRenderer.h"

#import <QuartzCore/CAMetalLayer.h>

@implementation AAPLViewController
{
@private
    // app control
    CADisplayLink *_timer;
    
    // timing for update and draw
    BOOL _firstDrawOccurred;
    
    CFTimeInterval _timeSinceLastDrawPreviousTime;
    
    // pause/resume
    BOOL _gameLoopPaused;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIApplicationDidEnterBackgroundNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIApplicationWillEnterForegroundNotification
                                                  object: nil];
    
    if(_timer)
    {
        [self stop];
    }
}

- (void)initCommon
{
    //  Register notifications to start/stop drawing as this app moves into the background
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(didEnterBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(willEnterForeground:)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    
    _interval = 1;
}

- (id)init
{
    self = [super init];
    
    if(self)
    {
        [self initCommon];
    }
    return self;
}

// called when loaded from nib
- (id)initWithNibName:(NSString *)nibNameOrNil
                bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    
	if(self)
	{
		[self initCommon];
	}
    
	return self;
}

// called when loaded from storyboard
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if(self)
    {
        [self initCommon];
    }
    
    return self;
}

- (void)dispatch
{
    // create a game loop timer using a dispatch source and fire it on the game loop queue
    _timer = [[UIScreen mainScreen] displayLinkWithTarget:self
                                                 selector:@selector(gameloop)];
    _timer.frameInterval = _interval;
    [_timer addToRunLoop:[NSRunLoop mainRunLoop]
                 forMode:NSDefaultRunLoopMode];
}

// the main game loop called by the timer above
- (void)gameloop
{
    
    // tell our delegate to update itself here.
    [_delegate update:self];
    
    if(!_firstDrawOccurred)
    {
        // set up timing data for display since this is the first time through this loop
        _timeSinceLastDraw             = 0.0;
        _timeSinceLastDrawPreviousTime = CACurrentMediaTime();
        _firstDrawOccurred              = YES;
    }
    else
    {
        // figure out the time since we last we drew
        CFTimeInterval currentTime = CACurrentMediaTime();
        
        _timeSinceLastDraw = currentTime - _timeSinceLastDrawPreviousTime;
        
        // keep track of the time interval between draws
        _timeSinceLastDrawPreviousTime = currentTime;
    }
    
    // display (render)
    // call the display method directly on the render view (setNeedsDisplay: has been disabled in the renderview by default)
    
    assert([self.view isKindOfClass:[AAPLView class]]);
    
    [(AAPLView *)self.view display];
}

- (void)stop
{
    // must not be suspended before cancelling
    if(_timer)
    {
        [_timer invalidate];
    }
}

- (void)setPaused:(BOOL)pause
{
    // calls to dispatch_resume dispatch_suspend must be balanced, so if this is same value just return
    if(_gameLoopPaused == pause)
    {
        return;
    }
    
    if(_timer)
    {
        // inform the delegate we are about to pause
        [_delegate controller:self
                              willPause:pause];
        
        if(pause == YES)
        {
            _gameLoopPaused = pause;
            _timer.paused   = YES;
            
            // ask the view to release textures until its resumed
            [(AAPLView *)self.view releaseTextures];
        }
        else
        {
            _gameLoopPaused = pause;
            _timer.paused   = NO;
        }
    }
}

- (BOOL)isPaused
{
    return _gameLoopPaused;
}

- (void)didEnterBackground:(NSNotification*)notification
{
    [self setPaused:YES];
}

- (void) willEnterForeground:(NSNotification*)notification
{
    [self setPaused:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self setPaused:NO];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self setPaused:YES];
}

@end
