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
    
    // boolean to determine if the first draw has occured
    BOOL _firstDrawOccurred;
    
    CFTimeInterval _timeSinceLastDrawPreviousTime;
    
    // pause/resume
    BOOL _gameLoopPaused;
    
    // our renderer instance
    AAPLRenderer *_renderer;
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
        [self stopGameLoop];
    }
}

- (void)initCommon
{
    _renderer = [AAPLRenderer new];
    self.delegate = _renderer;
    
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AAPLView *renderView = (AAPLView *)self.view;
    renderView.delegate = _renderer;
    
    // load all renderer assets before starting game loop
    [_renderer configure:renderView];
}

- (void)dispatchGameLoop
{
    // create a game loop timer using a display link
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
    
    assert([self.view isKindOfClass:[AAPLView class]]);
    
    // call the display method directly on the render view (setNeedsDisplay: has been disabled in the renderview by default)
    [(AAPLView *)self.view display];
}

- (void)stopGameLoop
{
    if(_timer)
        [_timer invalidate];
}

- (void)setPaused:(BOOL)pause
{
    if(_gameLoopPaused == pause)
    {
        return;
    }
    
    if(_timer)
    {
        // inform the delegate we are about to pause
        [_delegate viewController:self
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

- (void)willEnterForeground:(NSNotification*)notification
{
    [self setPaused:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // run the game loop
    [self dispatchGameLoop];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // end the gameloop
    [self stopGameLoop];
}

@end
